import Foundation
import Combine

/// Binds a playable room to the versioned host-authoritative transport. The
/// runtime supplies its rule callbacks; this type never inspects a hand/target.
@MainActor
final class GameRoomSyncController: ObservableObject {
    enum TransportKind: String, CaseIterable, Identifiable { case bluetooth = "Bluetooth"; case appleNearby = "Apple nearby"; var id: String { rawValue } }

    @Published private(set) var status = "Local game"
    @Published private(set) var roomCode = ""
    @Published private(set) var pairingSecret = ""
    @Published private(set) var connectedPeers: [String] = []
    @Published private(set) var isGuest = false

    private let localID = UUID().uuidString
    private var session: GameRoomNetworkSession?
    private var roomKind: GameRoomKind?
    private var onHostCommand: ((GameRoomCommand) -> Bool)?
    private var makePublicState: (() -> Data)?
    private var makePrivateState: (() -> Data?)?

    func configure(
        kind: GameRoomKind,
        onHostCommand: @escaping (GameRoomCommand) -> Bool,
        makePublicState: @escaping () -> Data,
        makePrivateState: @escaping () -> Data?,
        applyPublicState: @escaping (Data) -> Void,
        applyPrivateState: @escaping (Data) -> Void
    ) {
        roomKind = kind
        self.onHostCommand = onHostCommand
        self.makePublicState = makePublicState
        self.makePrivateState = makePrivateState
        self.applyPublicState = applyPublicState
        self.applyPrivateState = applyPrivateState
    }

    private var applyPublicState: ((Data) -> Void)?
    private var applyPrivateState: ((Data) -> Void)?

    func host(using kind: TransportKind) {
        guard let roomKind else { return }
        disconnect()
        roomCode = "CARDS-" + String(Int.random(in: 1000...9999))
        pairingSecret = kind == .bluetooth ? BLEEnvelopeCipher.makePairingSecret() : ""
        let transport: any NearbyTransport = kind == .bluetooth
            ? BluetoothLETransport(localPeerID: localID, displayName: "Host", sessionID: roomCode, pairingSecret: pairingSecret)
            : AppleNearbyTransport(localPeerID: localID, displayName: "Host")
        connect(kind: roomKind, role: .host, transport: transport)
    }

    func join(code: String, pairingSecret: String, using kind: TransportKind) {
        guard let roomKind else { return }
        let normalized = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, kind != .bluetooth || !pairingSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            status = "Enter the room code" + (kind == .bluetooth ? " and pairing secret." : ".")
            return
        }
        disconnect()
        roomCode = normalized
        self.pairingSecret = pairingSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        let transport: any NearbyTransport = kind == .bluetooth
            ? BluetoothLETransport(localPeerID: localID, displayName: "Guest", sessionID: normalized, pairingSecret: self.pairingSecret)
            : AppleNearbyTransport(localPeerID: localID, displayName: "Guest")
        connect(kind: roomKind, role: .guest, transport: transport)
    }

    func submit(action: String, characterID: String? = nil, amount: Int? = nil) {
        session?.submit(.init(action: action, playerID: localID, characterID: characterID, amount: amount))
    }

    func publish() {
        guard let session, let makePublicState else { return }
        let privateStates: [String: Data]
        if let peer = session.peers.first, let privateState = makePrivateState?() { privateStates = [peer: privateState] } else { privateStates = [:] }
        session.publish(publicState: makePublicState(), privateStates: privateStates)
        status = "Host published game revision \(session.revision)"
    }

    func disconnect() {
        session?.disconnect()
        session = nil
        connectedPeers = []
        isGuest = false
        roomCode = ""
        pairingSecret = ""
        status = "Local game"
    }

    private func connect(kind: GameRoomKind, role: GameRoomNetworkSession.Role, transport: any NearbyTransport) {
        let next = GameRoomNetworkSession(roomKind: kind, localPlayerID: localID, localPlayerName: role == .host ? "Host" : "Guest", sessionCode: roomCode, role: role, transport: transport)
        next.onHostCommand = { [weak self] command in
            guard let self, self.onHostCommand?(command) == true else { return false }
            self.publish()
            return true
        }
        next.onPeerJoined = { [weak self] in self?.publish() }
        next.onPublicSnapshot = { [weak self] data in self?.applyPublicState?(data) }
        next.onPrivateState = { [weak self] data in self?.applyPrivateState?(data) }
        session = next
        isGuest = role == .guest
        next.connect()
        status = next.status
        observe(next)
    }

    private func observe(_ session: GameRoomNetworkSession) {
        // SwiftUI redraws after commands, but this status is also refreshed when peers change.
        connectedPeers = session.peers
    }
}
