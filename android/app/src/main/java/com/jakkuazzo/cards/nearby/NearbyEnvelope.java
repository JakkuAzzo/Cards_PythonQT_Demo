package com.jakkuazzo.cards.nearby;

import org.json.JSONException;
import org.json.JSONObject;

import java.nio.charset.StandardCharsets;
import java.util.UUID;

/** Versioned wire envelope shared by every nearby transport. */
public final class NearbyEnvelope {
    public static final int PROTOCOL_VERSION = 1;

    public final String sessionId;
    public final String messageId;
    public final String senderId;
    public final int revision;
    public final String type;
    public final String recipientId;
    public final JSONObject payload;

    public NearbyEnvelope(String sessionId, String senderId, int revision, String type, JSONObject payload) {
        this(sessionId, UUID.randomUUID().toString(), senderId, revision, type, null, payload);
    }

    public NearbyEnvelope(String sessionId, String messageId, String senderId, int revision, String type, String recipientId, JSONObject payload) {
        this.sessionId = sessionId;
        this.messageId = messageId;
        this.senderId = senderId;
        this.revision = revision;
        this.type = type;
        this.recipientId = recipientId;
        this.payload = payload == null ? new JSONObject() : payload;
    }

    public byte[] encode() throws JSONException {
        JSONObject json = new JSONObject();
        json.put("protocolVersion", PROTOCOL_VERSION);
        json.put("sessionID", sessionId);
        json.put("messageID", messageId);
        json.put("senderID", senderId);
        json.put("revision", revision);
        json.put("type", type);
        json.put("recipientID", recipientId == null ? JSONObject.NULL : recipientId);
        json.put("payload", payload);
        return json.toString().getBytes(StandardCharsets.UTF_8);
    }

    public static NearbyEnvelope decode(byte[] bytes) throws JSONException {
        JSONObject json = new JSONObject(new String(bytes, StandardCharsets.UTF_8));
        if (json.getInt("protocolVersion") != PROTOCOL_VERSION) throw new JSONException("Unsupported protocol version");
        String recipient = json.isNull("recipientID") ? null : json.getString("recipientID");
        return new NearbyEnvelope(
            json.getString("sessionID"), json.getString("messageID"), json.getString("senderID"),
            json.getInt("revision"), json.getString("type"), recipient, json.getJSONObject("payload")
        );
    }
}
