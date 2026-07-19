package com.jakkuazzo.cards.nearby;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattServer;
import android.bluetooth.BluetoothGattServerCallback;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanFilter;
import android.bluetooth.le.ScanResult;
import android.bluetooth.le.ScanSettings;
import android.content.Context;
import android.os.ParcelUuid;

import com.jakkuazzo.cards.core.BlePacketFramer;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Cross-platform BLE fallback. The host exposes a GATT stream characteristic;
 * guests scan, subscribe, and write framed nearby envelopes. Runtime permission
 * prompts remain the responsibility of the hosting Activity.
 */
public final class BluetoothGattTransport {
    public interface Listener {
        void onPeersChanged(Set<String> peerIds);
        void onBytesReceived(String peerId, byte[] bytes);
        void onError(String message);
    }

    public static final UUID SERVICE_UUID = UUID.fromString("B9BB2D71-0B11-4E39-A5DF-0F17C4E81001");
    public static final UUID STREAM_UUID = UUID.fromString("B9BB2D71-0B11-4E39-A5DF-0F17C4E81002");
    private static final UUID CCCD_UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");

    private final Context context;
    private final Listener listener;
    private final BluetoothAdapter adapter;
    private final BLEEnvelopeCipher cipher;
    private final Map<String, BlePacketFramer> framers = new HashMap<>();
    private final Set<BluetoothDevice> subscribers = new HashSet<>();
    private BluetoothLeAdvertiser advertiser;
    private BluetoothLeScanner scanner;
    private BluetoothGattServer server;
    private BluetoothGatt guestGatt;
    private BluetoothGattCharacteristic stream;
    private boolean hosting;

    public BluetoothGattTransport(Context context, Listener listener, String sessionId, String pairingSecret) {
        this.context = context.getApplicationContext();
        this.listener = listener;
        this.cipher = new BLEEnvelopeCipher(pairingSecret, sessionId);
        BluetoothManager manager = context.getSystemService(BluetoothManager.class);
        this.adapter = manager == null ? null : manager.getAdapter();
    }

    public void host() {
        stop();
        if (adapter == null || !adapter.isEnabled()) { listener.onError("Bluetooth is unavailable or switched off."); return; }
        BluetoothManager manager = context.getSystemService(BluetoothManager.class);
        if (manager == null || !adapter.isMultipleAdvertisementSupported()) { listener.onError("This device cannot host a Bluetooth table."); return; }
        hosting = true;
        server = manager.openGattServer(context, serverCallback);
        if (server == null) { listener.onError("Could not open the Bluetooth table service."); return; }
        stream = new BluetoothGattCharacteristic(STREAM_UUID,
            BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE | BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_WRITE);
        stream.addDescriptor(new BluetoothGattDescriptor(CCCD_UUID, BluetoothGattDescriptor.PERMISSION_READ | BluetoothGattDescriptor.PERMISSION_WRITE));
        BluetoothGattService service = new BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY);
        service.addCharacteristic(stream);
        server.addService(service);
        advertiser = adapter.getBluetoothLeAdvertiser();
        if (advertiser == null) { listener.onError("Bluetooth advertising is unavailable."); return; }
        AdvertiseSettings settings = new AdvertiseSettings.Builder().setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY).setConnectable(true).build();
        AdvertiseData data = new AdvertiseData.Builder().addServiceUuid(new ParcelUuid(SERVICE_UUID)).setIncludeDeviceName(false).build();
        advertiser.startAdvertising(settings, data, advertiseCallback);
    }

    public void join() {
        stop();
        if (adapter == null || !adapter.isEnabled()) { listener.onError("Bluetooth is unavailable or switched off."); return; }
        hosting = false;
        scanner = adapter.getBluetoothLeScanner();
        if (scanner == null) { listener.onError("Bluetooth scanning is unavailable."); return; }
        List<ScanFilter> filters = Arrays.asList(new ScanFilter.Builder().setServiceUuid(new ParcelUuid(SERVICE_UUID)).build());
        scanner.startScan(filters, new ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build(), scanCallback);
    }

    public void send(byte[] envelope) {
        final byte[] encrypted;
        try { encrypted = cipher.seal(envelope); }
        catch (Exception error) { listener.onError("Could not encrypt Bluetooth message: " + error.getMessage()); return; }
        for (byte[] packet : BlePacketFramer.packets(encrypted)) {
            if (hosting && server != null && stream != null) {
                for (BluetoothDevice device : subscribers) server.notifyCharacteristicChanged(device, stream, false, packet);
            } else if (guestGatt != null && stream != null) {
                stream.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE);
                stream.setValue(packet);
                if (!guestGatt.writeCharacteristic(stream)) listener.onError("Bluetooth write queue is busy.");
            }
        }
    }

    public void stop() {
        if (advertiser != null) advertiser.stopAdvertising(advertiseCallback);
        if (scanner != null) scanner.stopScan(scanCallback);
        if (guestGatt != null) { guestGatt.disconnect(); guestGatt.close(); }
        if (server != null) server.close();
        advertiser = null; scanner = null; guestGatt = null; server = null; stream = null;
        subscribers.clear(); framers.clear();
        listener.onPeersChanged(new HashSet<>());
    }

    private void receive(String peerId, byte[] packet) {
        BlePacketFramer framer = framers.get(peerId);
        if (framer == null) { framer = new BlePacketFramer(); framers.put(peerId, framer); }
        for (byte[] encrypted : framer.append(packet)) {
            try { listener.onBytesReceived(peerId, cipher.open(encrypted)); }
            catch (Exception error) { listener.onError("Ignored Bluetooth message with invalid authentication."); }
        }
    }

    private void publishPeers() {
        Set<String> ids = new HashSet<>();
        if (hosting) for (BluetoothDevice device : subscribers) ids.add(device.getAddress());
        else if (guestGatt != null) ids.add(guestGatt.getDevice().getAddress());
        listener.onPeersChanged(ids);
    }

    private final AdvertiseCallback advertiseCallback = new AdvertiseCallback() {
        @Override public void onStartFailure(int errorCode) { listener.onError("Bluetooth advertising failed: " + errorCode); }
    };

    private final ScanCallback scanCallback = new ScanCallback() {
        @Override public void onScanResult(int callbackType, ScanResult result) {
            if (guestGatt != null) return;
            if (scanner != null) scanner.stopScan(this);
            guestGatt = result.getDevice().connectGatt(context, false, guestCallback, BluetoothDevice.TRANSPORT_LE);
        }
        @Override public void onScanFailed(int errorCode) { listener.onError("Bluetooth scan failed: " + errorCode); }
    };

    private final BluetoothGattServerCallback serverCallback = new BluetoothGattServerCallback() {
        @Override public void onConnectionStateChange(BluetoothDevice device, int status, int newState) {
            if (newState == BluetoothProfile.STATE_DISCONNECTED) { subscribers.remove(device); framers.remove(device.getAddress()); publishPeers(); }
        }
        @Override public void onCharacteristicWriteRequest(BluetoothDevice device, int requestId, BluetoothGattCharacteristic characteristic, boolean preparedWrite, boolean responseNeeded, int offset, byte[] value) {
            if (STREAM_UUID.equals(characteristic.getUuid()) && value != null) receive(device.getAddress(), value);
            if (responseNeeded && server != null) server.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null);
        }
        @Override public void onDescriptorWriteRequest(BluetoothDevice device, int requestId, BluetoothGattDescriptor descriptor, boolean preparedWrite, boolean responseNeeded, int offset, byte[] value) {
            if (CCCD_UUID.equals(descriptor.getUuid()) && Arrays.equals(value, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)) subscribers.add(device);
            if (responseNeeded && server != null) server.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null);
            publishPeers();
        }
    };

    private final BluetoothGattCallback guestCallback = new BluetoothGattCallback();

    private final class BluetoothGattCallback extends android.bluetooth.BluetoothGattCallback {
        @Override public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
            if (status != BluetoothGatt.GATT_SUCCESS || newState == BluetoothProfile.STATE_DISCONNECTED) { publishPeers(); return; }
            if (newState == BluetoothProfile.STATE_CONNECTED) gatt.discoverServices();
        }
        @Override public void onServicesDiscovered(BluetoothGatt gatt, int status) {
            if (status != BluetoothGatt.GATT_SUCCESS) { listener.onError("Bluetooth service discovery failed."); return; }
            BluetoothGattService service = gatt.getService(SERVICE_UUID);
            stream = service == null ? null : service.getCharacteristic(STREAM_UUID);
            if (stream == null) { listener.onError("Cards Bluetooth stream was not found."); return; }
            gatt.setCharacteristicNotification(stream, true);
            BluetoothGattDescriptor descriptor = stream.getDescriptor(CCCD_UUID);
            if (descriptor != null) { descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE); gatt.writeDescriptor(descriptor); }
            publishPeers();
        }
        @Override public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
            if (STREAM_UUID.equals(characteristic.getUuid()) && characteristic.getValue() != null) receive(gatt.getDevice().getAddress(), characteristic.getValue());
        }
    }
}
