package com.jakkuazzo.cards.core;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/** BLE-independent framing shared with the iOS client: two-byte length then envelope bytes. */
public final class BlePacketFramer {
    public static final int MAXIMUM_PACKET_PAYLOAD = 160;
    private final ByteArrayOutputStream pending = new ByteArrayOutputStream();

    public static List<byte[]> packets(byte[] envelope) {
        if (envelope.length > 65535) throw new IllegalArgumentException("Envelope exceeds BLE frame limit");
        byte[] stream = new byte[envelope.length + 2];
        stream[0] = (byte) ((envelope.length >>> 8) & 0xff);
        stream[1] = (byte) (envelope.length & 0xff);
        System.arraycopy(envelope, 0, stream, 2, envelope.length);
        List<byte[]> packets = new ArrayList<>();
        for (int offset = 0; offset < stream.length; offset += MAXIMUM_PACKET_PAYLOAD) {
            packets.add(Arrays.copyOfRange(stream, offset, Math.min(offset + MAXIMUM_PACKET_PAYLOAD, stream.length)));
        }
        return packets;
    }

    public List<byte[]> append(byte[] packet) {
        pending.write(packet, 0, packet.length);
        byte[] bytes = pending.toByteArray();
        int offset = 0;
        List<byte[]> envelopes = new ArrayList<>();
        while (bytes.length - offset >= 2) {
            int length = ((bytes[offset] & 0xff) << 8) | (bytes[offset + 1] & 0xff);
            if (bytes.length - offset < length + 2) break;
            envelopes.add(Arrays.copyOfRange(bytes, offset + 2, offset + 2 + length));
            offset += length + 2;
        }
        pending.reset();
        pending.write(bytes, offset, bytes.length - offset);
        return envelopes;
    }
}
