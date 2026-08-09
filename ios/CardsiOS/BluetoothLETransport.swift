import CoreBluetooth
import Foundation

/// Cross-platform BLE fallback. The host is a GATT peripheral; guests are centrals.
/// The session-code hello envelope remains mandatory before a player is admitted.
@MainActor
final class BluetoothLETransport: NSObject, NearbyTransport {
    let localPeerID: String
    var onEnvelope: ((NearbyEnvelope) -> Void)?
    var onPeersChanged: (([String]) -> Void)?

    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    private var connectedPeripheral: CBPeripheral?
    private var streamCharacteristic: CBMutableCharacteristic?
    private var remoteStreamCharacteristic: CBCharacteristic?
    private var isHost = false
    private var targetSessionID: String?
    private var receiver = BLEPacketFramer()
    private var peerIDs = Set<String>()
    private let cipher: BLEEnvelopeCipher

    init(localPeerID: String, displayName: String, sessionID: String, pairingSecret: String) {
        self.localPeerID = localPeerID
        self.cipher = BLEEnvelopeCipher(pairingSecret: pairingSecret, sessionID: sessionID)
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        peripheralManager = CBPeripheralManager(delegate: self, queue: .main, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
    }

    func host(sessionID: String) {
        disconnect()
        isHost = true
        targetSessionID = sessionID
        startAdvertisingIfReady()
    }

    func join(sessionID: String) {
        disconnect()
        isHost = false
        targetSessionID = sessionID
        startScanningIfReady()
    }

    func send(_ envelope: NearbyEnvelope) {
        guard let data = try? JSONEncoder().encode(envelope), let encrypted = try? cipher.seal(data) else { return }
        let packets = BLEPacketFramer.packets(for: encrypted)
        if isHost, let streamCharacteristic {
            for packet in packets { _ = peripheralManager.updateValue(packet, for: streamCharacteristic, onSubscribedCentrals: nil) }
        } else if let peripheral = connectedPeripheral, let remoteStreamCharacteristic {
            for packet in packets { peripheral.writeValue(packet, for: remoteStreamCharacteristic, type: .withoutResponse) }
        }
    }

    func disconnect() {
        centralManager?.stopScan()
        if let connectedPeripheral { centralManager?.cancelPeripheralConnection(connectedPeripheral) }
        connectedPeripheral = nil
        remoteStreamCharacteristic = nil
        peripheralManager?.stopAdvertising()
        peripheralManager?.removeAllServices()
        streamCharacteristic = nil
        peerIDs = []
        onPeersChanged?([])
    }

    private func startAdvertisingIfReady() {
        guard peripheralManager.state == .poweredOn else { return }
        let stream = CBMutableCharacteristic(
            type: CBUUID(string: CardsBLEContract.streamUUID),
            properties: [.writeWithoutResponse, .notify],
            value: nil,
            permissions: [.writeable]
        )
        streamCharacteristic = stream
        let service = CBMutableService(type: CBUUID(string: CardsBLEContract.serviceUUID), primary: true)
        service.characteristics = [stream]
        peripheralManager.add(service)
    }

    private func startScanningIfReady() {
        guard centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(withServices: [CBUUID(string: CardsBLEContract.serviceUUID)], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    private func receive(_ packet: Data) {
        for data in receiver.append(packet: packet) {
            guard let plaintext = try? cipher.open(data), let envelope = try? JSONDecoder().decode(NearbyEnvelope.self, from: plaintext) else { continue }
            onEnvelope?(envelope)
        }
    }
}

extension BluetoothLETransport: CBPeripheralManagerDelegate {
    nonisolated func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        Task { @MainActor in if self.isHost { self.startAdvertisingIfReady() } }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        Task { @MainActor in
            guard error == nil, self.isHost else { return }
            peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: CardsBLEContract.serviceUUID)]])
        }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        Task { @MainActor in self.peerIDs.insert(central.identifier.uuidString); self.onPeersChanged?(self.peerIDs.sorted()) }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        Task { @MainActor in self.peerIDs.remove(central.identifier.uuidString); self.onPeersChanged?(self.peerIDs.sorted()) }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        Task { @MainActor in
            for request in requests where request.characteristic.uuid == CBUUID(string: CardsBLEContract.streamUUID) {
                if let value = request.value { self.receive(value) }
                peripheral.respond(to: request, withResult: .success)
            }
        }
    }
}

extension BluetoothLETransport: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in if !self.isHost { self.startScanningIfReady() } }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        Task { @MainActor in
            guard self.connectedPeripheral == nil, !self.isHost else { return }
            self.connectedPeripheral = peripheral
            peripheral.delegate = self
            central.stopScan()
            central.connect(peripheral)
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([CBUUID(string: CardsBLEContract.serviceUUID)])
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.connectedPeripheral = nil
            self.remoteStreamCharacteristic = nil
            self.peerIDs = []
            self.onPeersChanged?([])
            self.startScanningIfReady()
        }
    }
}

extension BluetoothLETransport: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else { return }
        peripheral.services?.forEach { peripheral.discoverCharacteristics([CBUUID(string: CardsBLEContract.streamUUID)], for: $0) }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil, let characteristic = service.characteristics?.first(where: { $0.uuid == CBUUID(string: CardsBLEContract.streamUUID) }) else { return }
        Task { @MainActor in
            self.remoteStreamCharacteristic = characteristic
            self.peerIDs = [peripheral.identifier.uuidString]
            self.onPeersChanged?(self.peerIDs.sorted())
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let value = characteristic.value else { return }
        Task { @MainActor in self.receive(value) }
    }
}
