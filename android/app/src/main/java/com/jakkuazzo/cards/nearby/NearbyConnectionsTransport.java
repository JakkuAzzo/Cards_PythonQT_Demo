package com.jakkuazzo.cards.nearby;

import android.content.Context;

import com.google.android.gms.nearby.Nearby;
import com.google.android.gms.nearby.connection.AdvertisingOptions;
import com.google.android.gms.nearby.connection.ConnectionInfo;
import com.google.android.gms.nearby.connection.ConnectionLifecycleCallback;
import com.google.android.gms.nearby.connection.ConnectionResolution;
import com.google.android.gms.nearby.connection.ConnectionsClient;
import com.google.android.gms.nearby.connection.DiscoveredEndpointInfo;
import com.google.android.gms.nearby.connection.DiscoveryOptions;
import com.google.android.gms.nearby.connection.EndpointDiscoveryCallback;
import com.google.android.gms.nearby.connection.Payload;
import com.google.android.gms.nearby.connection.PayloadCallback;
import com.google.android.gms.nearby.connection.PayloadTransferUpdate;
import com.google.android.gms.nearby.connection.Strategy;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

public final class NearbyConnectionsTransport {
    public interface Listener {
        void onVerificationRequired(String endpointId, String endpointName, String authenticationDigits);
        void onPeersChanged(Set<String> endpointIds);
        void onBytesReceived(String endpointId, byte[] bytes);
        void onError(String message);
    }

    private static final Strategy STRATEGY = Strategy.P2P_STAR;
    private final ConnectionsClient client;
    private final String serviceId;
    private final String localName;
    private final Listener listener;
    private final Set<String> connected = new HashSet<>();

    public NearbyConnectionsTransport(Context context, String localName, Listener listener) {
        this.client = Nearby.getConnectionsClient(context);
        this.serviceId = context.getPackageName();
        this.localName = localName;
        this.listener = listener;
    }

    public void startHosting() {
        AdvertisingOptions options = new AdvertisingOptions.Builder().setStrategy(STRATEGY).build();
        client.startAdvertising(localName, serviceId, lifecycle, options)
            .addOnFailureListener(error -> listener.onError(error.getMessage()));
    }

    public void startJoining() {
        DiscoveryOptions options = new DiscoveryOptions.Builder().setStrategy(STRATEGY).build();
        client.startDiscovery(serviceId, discovery, options)
            .addOnFailureListener(error -> listener.onError(error.getMessage()));
    }

    public void accept(String endpointId) {
        client.acceptConnection(endpointId, payloads)
            .addOnFailureListener(error -> listener.onError(error.getMessage()));
    }

    public void reject(String endpointId) {
        client.rejectConnection(endpointId);
    }

    public void send(byte[] bytes) {
        if (!connected.isEmpty()) {
            client.sendPayload(connected, Payload.fromBytes(bytes));
        }
    }

    public void stop() {
        client.stopAdvertising();
        client.stopDiscovery();
        client.stopAllEndpoints();
        connected.clear();
        publishPeers();
    }

    private final EndpointDiscoveryCallback discovery = new EndpointDiscoveryCallback() {
        @Override public void onEndpointFound(String endpointId, DiscoveredEndpointInfo info) {
            client.requestConnection(localName, endpointId, lifecycle)
                .addOnFailureListener(error -> listener.onError(error.getMessage()));
        }

        @Override public void onEndpointLost(String endpointId) {
            connected.remove(endpointId);
            publishPeers();
        }
    };

    private final ConnectionLifecycleCallback lifecycle = new ConnectionLifecycleCallback() {
        @Override public void onConnectionInitiated(String endpointId, ConnectionInfo info) {
            listener.onVerificationRequired(endpointId, info.getEndpointName(), info.getAuthenticationDigits());
        }

        @Override public void onConnectionResult(String endpointId, ConnectionResolution resolution) {
            if (resolution.getStatus().isSuccess()) {
                connected.add(endpointId);
                publishPeers();
            } else {
                listener.onError("Connection rejected: " + resolution.getStatus());
            }
        }

        @Override public void onDisconnected(String endpointId) {
            connected.remove(endpointId);
            publishPeers();
        }
    };

    private final PayloadCallback payloads = new PayloadCallback() {
        @Override public void onPayloadReceived(String endpointId, Payload payload) {
            if (payload.getType() == Payload.Type.BYTES && payload.asBytes() != null) {
                listener.onBytesReceived(endpointId, payload.asBytes());
            }
        }

        @Override public void onPayloadTransferUpdate(String endpointId, PayloadTransferUpdate update) {
            // Byte payloads are delivered atomically in onPayloadReceived.
        }
    };

    private void publishPeers() {
        listener.onPeersChanged(Collections.unmodifiableSet(new HashSet<>(connected)));
    }
}

