package com.jakkuazzo.cards.nearby;

import android.util.Base64;

import org.json.JSONException;
import org.json.JSONObject;

import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.UUID;

/**
 * Host-authoritative room protocol shared with the iOS GameRoomNetworkSession.
 * Engines decide whether a command is legal; this class guarantees that guests
 * cannot impersonate another player and that private state stays recipient-only.
 */
public final class GameRoomNetworkSession {
    public enum Role { HOST, GUEST }

    public interface Sender { void send(NearbyEnvelope envelope) throws JSONException; }
    public interface Callbacks {
        boolean onHostCommand(Command command);
        void onPeerJoined(String playerId);
        void onPublicSnapshot(JSONObject state);
        void onPrivateState(JSONObject state);
        void onStatus(String status);
    }

    public static final class Command {
        public final String action;
        public final String playerId;
        public final String characterId;
        public final Integer amount;

        public Command(String action, String playerId, String characterId, Integer amount) {
            this.action = action;
            this.playerId = playerId;
            this.characterId = characterId;
            this.amount = amount;
        }

        JSONObject encode() throws JSONException {
            JSONObject json = new JSONObject().put("action", action).put("playerID", playerId);
            if (characterId != null) json.put("characterID", characterId);
            if (amount != null) json.put("amount", amount);
            return json;
        }

        static Command decode(JSONObject json) throws JSONException {
            return new Command(json.getString("action"), json.getString("playerID"), json.optString("characterID", null), json.has("amount") ? json.getInt("amount") : null);
        }
    }

    private final String game;
    private final String localPlayerId;
    private final String localPlayerName;
    private final String sessionCode;
    private final Role role;
    private final Sender sender;
    private final Callbacks callbacks;
    private int revision;

    public GameRoomNetworkSession(String game, String localPlayerId, String localPlayerName, String sessionCode, Role role, Sender sender, Callbacks callbacks) {
        if (!"poker".equals(game) && !"guess-who".equals(game)) throw new IllegalArgumentException("Unsupported game room");
        this.game = game;
        this.localPlayerId = localPlayerId;
        this.localPlayerName = localPlayerName;
        this.sessionCode = sessionCode;
        this.role = role;
        this.sender = sender;
        this.callbacks = callbacks;
    }

    public int revision() { return revision; }

    public void connected() {
        if (role == Role.GUEST) {
            try { send("hello", null, new JSONObject().put("game", game).put("name", localPlayerName)); }
            catch (JSONException error) { callbacks.onStatus("Could not start room: " + error.getMessage()); }
        } else callbacks.onStatus("Hosting " + game + " · share " + sessionCode);
    }

    public void submit(Command command) {
        if (!localPlayerId.equals(command.playerId)) return;
        if (role == Role.HOST) {
            callbacks.onHostCommand(command);
            return;
        }
        try {
            JSONObject payload = new JSONObject().put("game", game).put("command", base64(command.encode().toString().getBytes(StandardCharsets.UTF_8)));
            send("command", null, payload);
            callbacks.onStatus("Command sent to host");
        } catch (JSONException error) { callbacks.onStatus("Could not encode command: " + error.getMessage()); }
    }

    public void publish(JSONObject publicState, Map<String, JSONObject> privateStates) {
        if (role != Role.HOST) return;
        try {
            revision++;
            send("snapshot", null, new JSONObject().put("game", game).put("state", base64(publicState.toString().getBytes(StandardCharsets.UTF_8))));
            for (Map.Entry<String, JSONObject> entry : privateStates.entrySet()) {
                send("private-event", entry.getKey(), new JSONObject().put("game", game).put("state", base64(entry.getValue().toString().getBytes(StandardCharsets.UTF_8))));
            }
        } catch (JSONException error) { callbacks.onStatus("Could not publish room state: " + error.getMessage()); }
    }

    public void receive(NearbyEnvelope envelope) {
        if (!sessionCode.equals(envelope.sessionId) || localPlayerId.equals(envelope.senderId)) return;
        if (envelope.recipientId != null && !localPlayerId.equals(envelope.recipientId)) return;
        if (envelope.payload.has("game") && !game.equals(envelope.payload.optString("game"))) return;
        try {
            if (role == Role.HOST && "hello".equals(envelope.type)) {
                callbacks.onStatus(envelope.payload.optString("name", "Guest") + " joined " + game);
                callbacks.onPeerJoined(envelope.senderId);
            } else if (role == Role.HOST && "command".equals(envelope.type)) {
                Command command = Command.decode(new JSONObject(new String(unbase64(envelope.payload.getString("command")), StandardCharsets.UTF_8)));
                if (!envelope.senderId.equals(command.playerId)) return;
                callbacks.onHostCommand(command);
            } else if (role == Role.GUEST && "snapshot".equals(envelope.type) && envelope.revision >= revision) {
                revision = envelope.revision;
                String publicState = new String(unbase64(envelope.payload.getString("state")), StandardCharsets.UTF_8);
                callbacks.onPublicSnapshot(new JSONObject(publicState));
                callbacks.onStatus("Synced at revision " + revision);
            } else if (role == Role.GUEST && "private-event".equals(envelope.type) && envelope.revision >= revision) {
                revision = envelope.revision;
                String privateState = new String(unbase64(envelope.payload.getString("state")), StandardCharsets.UTF_8);
                callbacks.onPrivateState(new JSONObject(privateState));
            }
        } catch (Exception error) { callbacks.onStatus("Ignored invalid room message: " + error.getMessage()); }
    }

    private void send(String type, String recipientId, JSONObject payload) {
        try { sender.send(new NearbyEnvelope(sessionCode, UUID.randomUUID().toString(), localPlayerId, revision, type, recipientId, payload)); }
        catch (JSONException error) { callbacks.onStatus("Could not send room message: " + error.getMessage()); }
    }

    private static String base64(byte[] data) { return Base64.encodeToString(data, Base64.NO_WRAP); }
    private static byte[] unbase64(String value) { return Base64.decode(value, Base64.DEFAULT); }
}
