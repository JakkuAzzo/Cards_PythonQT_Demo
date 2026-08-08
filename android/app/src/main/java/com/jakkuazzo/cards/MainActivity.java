package com.jakkuazzo.cards;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import com.jakkuazzo.cards.core.GameState;
import com.jakkuazzo.cards.core.MultiplayerEngine;
import com.jakkuazzo.cards.nearby.GameSnapshotCodec;
import com.jakkuazzo.cards.nearby.BLEEnvelopeCipher;
import com.jakkuazzo.cards.nearby.BluetoothGattTransport;
import com.jakkuazzo.cards.nearby.NearbyConnectionsTransport;
import com.jakkuazzo.cards.nearby.NearbyEnvelope;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Locale;
import java.util.UUID;

/**
 * Purpose: legacy Android entry for creating and joining a generic nearby
 * table.
 *
 * Relationships: {@link HubActivity} is the launcher and opens this activity
 * from its Table destination. The transport adapters own discovery and bytes;
 * this activity only drives the generic table UI and engine.
 *
 * Constraint: retain its public/private snapshot and connection-state checks
 * while the controls are migrated into the persistent Hub table experience.
 */
public final class MainActivity extends Activity implements NearbyConnectionsTransport.Listener, BluetoothGattTransport.Listener {
    private final MultiplayerEngine engine = new MultiplayerEngine();
    private final String localPlayerId = UUID.randomUUID().toString();
    private final String localName = "Android player";
    private TextView status;
    private TextView card;
    private LinearLayout sessionControls;
    private LinearLayout actions;
    private EditText joinCode;
    private EditText bluetoothSecret;
    private NearbyConnectionsTransport nearby;
    private BluetoothGattTransport bluetooth;
    private boolean bluetoothMode;
    private boolean hosting;
    private boolean localPreview;
    private String sessionCode = "";
    private int guestNumber = 1;
    private int nearbyPeerCount;
    private String connectionMessage = "Choose a nearby table or start a one-device preview.";
    private String bluetoothPairingSecret = "";

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(buildContent());
        requestNearbyPermissions();
        render();
    }

    private View buildContent() {
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setBackgroundColor(Color.rgb(10, 14, 24));
        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(dp(20), dp(28), dp(20), dp(28));

        TextView eyebrow = text("CARDS · NEARBY PLAY", 12, Color.rgb(108, 221, 183));
        eyebrow.setLetterSpacing(0.12f);
        content.addView(eyebrow);
        TextView title = text("Choose a table.\nBring friends.", 32, Color.WHITE);
        title.setTypeface(null, android.graphics.Typeface.BOLD);
        title.setPadding(0, dp(7), 0, 0);
        content.addView(title);
        TextView subtitle = text("Start with a familiar game, play together on one phone, or create a verified nearby table.", 16, Color.rgb(190, 198, 213));
        subtitle.setPadding(0, dp(10), 0, dp(22));
        content.addView(subtitle);

        content.addView(sectionTitle("PLAY A GAME"));
        LinearLayout templates = new LinearLayout(this);
        templates.setOrientation(LinearLayout.HORIZONTAL);
        Button poker = button("♠  Poker", true);
        poker.setOnClickListener(view -> openGameRoom("poker"));
        templates.addView(poker, new LinearLayout.LayoutParams(0, -2, 1));
        Button guess = button("?  Guess Who", false);
        guess.setOnClickListener(view -> openGameRoom("guess-who"));
        LinearLayout.LayoutParams guessParams = new LinearLayout.LayoutParams(0, -2, 1);
        guessParams.setMargins(dp(10), 0, 0, 0);
        templates.addView(guess, guessParams);
        content.addView(templates);

        status = text("", 14, Color.LTGRAY);
        status.setPadding(dp(16), dp(14), dp(16), dp(14));
        status.setBackground(panelBackground(Color.rgb(20, 27, 43), 16));
        LinearLayout.LayoutParams statusParams = new LinearLayout.LayoutParams(-1, -2);
        statusParams.setMargins(0, dp(20), 0, dp(12));
        content.addView(status, statusParams);

        sessionControls = new LinearLayout(this);
        sessionControls.setOrientation(LinearLayout.VERTICAL);
        content.addView(sessionControls, new LinearLayout.LayoutParams(-1, -2));

        card = text("", 24, Color.WHITE);
        card.setGravity(Gravity.CENTER);
        card.setPadding(dp(22), dp(22), dp(22), dp(22));
        card.setBackground(panelBackground(Color.rgb(49, 34, 100), 22));
        LinearLayout.LayoutParams cardParams = new LinearLayout.LayoutParams(-1, dp(184));
        cardParams.setMargins(0, dp(18), 0, dp(18));
        content.addView(card, cardParams);

        actions = new LinearLayout(this);
        actions.setOrientation(LinearLayout.VERTICAL);
        content.addView(actions, new LinearLayout.LayoutParams(-1, -2));

        Button ar = button("Open camera table placement", false);
        ar.setOnClickListener(view -> startActivity(new Intent(this, ArTableActivity.class)));
        content.addView(ar);
        scroll.addView(content);
        return scroll;
    }

    private void render() {
        GameState state = engine.state();
        String active = state.activePlayer() == null ? "None" : state.activePlayer().name;
        String mode = localPreview ? "One-device preview" : hosting ? "Hosting " + sessionCode : sessionCode.isEmpty() ? "Not connected" : "Joined " + sessionCode;
        status.setText(mode + "\n" + connectionMessage + "\nPhase: " + state.phase + " · Revision: " + state.revision + " · Active: " + active);
        card.setText(state.currentCard == null ? (state.phase == GameState.Phase.FINISHED ? "Game complete" : "Ready to draw") : state.currentCard.text);
        renderSessionControls();
        actions.removeAllViews();

        if (state.phase == GameState.Phase.LOBBY) {
            if (localPreview) {
                Button join = button("Add local player");
                join.setOnClickListener(view -> runAction(() -> {
                    int number = guestNumber++;
                    engine.join("local-" + number, "Player " + (number + 1));
                }));
                join.setEnabled(state.players.size() < MultiplayerEngine.MAXIMUM_PLAYERS);
                actions.addView(join);
            }
            Button start = button(hosting ? "Start nearby game" : "Start table");
            start.setEnabled((hosting || localPreview) && state.players.size() >= MultiplayerEngine.MINIMUM_PLAYERS);
            start.setOnClickListener(view -> runHostAction("start", null));
            actions.addView(start);
        } else if (state.phase == GameState.Phase.WAITING_FOR_DRAW && state.activePlayer() != null) {
            Button draw = button("Draw for " + active);
            boolean allowed = (hosting || localPreview) && state.activePlayer().id.equals(localPlayerId)
                || (!hosting && !localPreview && state.activePlayer().id.equals(localPlayerId));
            draw.setEnabled(allowed);
            draw.setOnClickListener(view -> runHostAction("draw", state.activePlayer().id));
            actions.addView(draw);
        } else if (state.phase == GameState.Phase.SHOWING_CARD && state.activePlayer() != null) {
            Button end = button("End turn");
            boolean allowed = (hosting || localPreview) && state.activePlayer().id.equals(localPlayerId)
                || (!hosting && !localPreview && state.activePlayer().id.equals(localPlayerId));
            end.setEnabled(allowed);
            end.setOnClickListener(view -> runHostAction("end-turn", state.activePlayer().id));
            actions.addView(end);
        }
    }

    private void renderSessionControls() {
        sessionControls.removeAllViews();
        if (sessionCode.isEmpty() && !localPreview) {
            contentSpacer(sessionControls, 8);
            sessionControls.addView(sectionTitle("PLAY TOGETHER"));
            Button host = button("Create nearby table", true);
            host.setOnClickListener(view -> startHosting());
            sessionControls.addView(host);

            Button bluetoothHost = button("Create Bluetooth table", false);
            bluetoothHost.setOnClickListener(view -> startBluetoothHosting());
            sessionControls.addView(bluetoothHost);

            LinearLayout joinRow = new LinearLayout(this);
            joinRow.setOrientation(LinearLayout.HORIZONTAL);
            joinCode = new EditText(this);
            joinCode.setHint("Table code, e.g. CARDS-1234");
            joinCode.setSingleLine(true);
            joinRow.addView(joinCode, new LinearLayout.LayoutParams(0, -2, 1));
            Button join = button("Join", true);
            join.setOnClickListener(view -> startJoining(joinCode.getText().toString()));
            joinRow.addView(join, new LinearLayout.LayoutParams(-2, -2));
            sessionControls.addView(joinRow);

            Button bluetoothJoin = button("Join Bluetooth table", false);
            bluetoothJoin.setOnClickListener(view -> startBluetoothJoining(joinCode.getText().toString()));
            sessionControls.addView(bluetoothJoin);

            bluetoothSecret = new EditText(this);
            bluetoothSecret.setHint("Bluetooth pairing secret from host");
            bluetoothSecret.setSingleLine(true);
            sessionControls.addView(bluetoothSecret);

            Button local = button("Play on this phone", false);
            local.setOnClickListener(view -> startLocalPreview());
            sessionControls.addView(local);
        } else {
            TextView players = text("Players: " + engine.state().players.size() + " · Nearby peers: " + nearbyPeerCount, 14, Color.LTGRAY);
            sessionControls.addView(players);
            Button leave = button("Leave table", false);
            leave.setOnClickListener(view -> { leaveTable(); render(); });
            sessionControls.addView(leave);
        }
    }

    private void startHosting() {
        if (!ensureNearbyReady("create a nearby table")) return;
        leaveTable();
        hosting = true;
        sessionCode = "CARDS-" + String.format(Locale.US, "%04d", (int) (Math.random() * 10000));
        try {
            engine.join(localPlayerId, "Host");
            nearby = new NearbyConnectionsTransport(this, localName, this);
            nearby.startHosting();
            connectionMessage = "Share " + sessionCode + ", then compare authentication digits before accepting a guest.";
        } catch (Exception error) {
            connectionMessage = "Could not host: " + error.getMessage();
        }
        render();
    }

    private void startJoining(String enteredCode) {
        if (!ensureNearbyReady("join a nearby table")) return;
        String code = enteredCode.toUpperCase(Locale.US).replaceAll("[^A-Z0-9-]", "");
        if (!code.startsWith("CARDS-") || code.length() != 10) {
            connectionMessage = "Enter the host’s table code, for example CARDS-1234.";
            render();
            return;
        }
        leaveTable();
        sessionCode = code;
        hosting = false;
        nearby = new NearbyConnectionsTransport(this, localName, this);
        nearby.startJoining();
        connectionMessage = "Looking for " + sessionCode + ". Compare the authentication digits before accepting.";
        render();
    }

    private void startBluetoothHosting() {
        if (!ensureBluetoothReady("create a Bluetooth table")) return;
        leaveTable();
        hosting = true;
        bluetoothMode = true;
        sessionCode = "CARDS-" + String.format(Locale.US, "%04d", (int) (Math.random() * 10000));
        try {
            engine.join(localPlayerId, "Host");
            bluetoothPairingSecret = BLEEnvelopeCipher.makePairingSecret();
            bluetooth = new BluetoothGattTransport(this, this, sessionCode, bluetoothPairingSecret);
            bluetooth.host();
            connectionMessage = "Bluetooth host ready. Share code " + sessionCode + " and pairing secret " + bluetoothPairingSecret + ".";
        } catch (Exception error) {
            connectionMessage = "Could not host with Bluetooth: " + error.getMessage();
        }
        render();
    }

    private void startBluetoothJoining(String enteredCode) {
        if (!ensureBluetoothReady("join a Bluetooth table")) return;
        String code = enteredCode.toUpperCase(Locale.US).replaceAll("[^A-Z0-9-]", "");
        if (!code.startsWith("CARDS-") || code.length() != 10) {
            connectionMessage = "Enter the Bluetooth host’s CARDS-1234 table code.";
            render();
            return;
        }
        String secret = bluetoothSecret == null ? "" : bluetoothSecret.getText().toString().trim();
        if (secret.isEmpty()) {
            connectionMessage = "Enter the host’s Bluetooth pairing secret.";
            render();
            return;
        }
        leaveTable();
        sessionCode = code;
        bluetoothMode = true;
        hosting = false;
        bluetooth = new BluetoothGattTransport(this, this, sessionCode, secret);
        bluetooth.join();
        connectionMessage = "Scanning nearby Bluetooth tables for " + sessionCode + "…";
        render();
    }

    private void startLocalPreview() {
        leaveTable();
        localPreview = true;
        try {
            engine.join(localPlayerId, "You");
            connectionMessage = "One-device preview · add one player to start.";
        } catch (Exception error) {
            connectionMessage = error.getMessage();
        }
        render();
    }

    private void leaveTable() {
        if (nearby != null) nearby.stop();
        if (bluetooth != null) bluetooth.stop();
        nearby = null;
        bluetooth = null;
        bluetoothMode = false;
        bluetoothPairingSecret = "";
        nearbyPeerCount = 0;
        engine.reset();
        hosting = false;
        localPreview = false;
        sessionCode = "";
        connectionMessage = "Choose a nearby table or start a one-device preview.";
    }

    private void runHostAction(String action, String playerId) {
        if (!hosting && !localPreview) {
            sendCommand(action, playerId);
            return;
        }
        try {
            if ("start".equals(action)) engine.start(System.nanoTime());
            else if ("draw".equals(action)) engine.draw(playerId);
            else if ("end-turn".equals(action)) engine.endTurn(playerId);
            broadcastSnapshot();
            render();
        } catch (Exception error) {
            connectionMessage = "Cannot continue: " + error.getMessage();
            render();
        }
    }

    private void sendHello() {
        try {
            JSONObject payload = new JSONObject().put("code", sessionCode).put("name", localName);
            send(new NearbyEnvelope(sessionCode, localPlayerId, engine.state().revision, "hello", payload));
        } catch (JSONException error) {
            connectionMessage = error.getMessage();
        }
    }

    private void sendCommand(String action, String playerId) {
        try {
            JSONObject payload = new JSONObject().put("action", action).put("playerID", playerId);
            send(new NearbyEnvelope(sessionCode, localPlayerId, engine.state().revision, "command", payload));
            connectionMessage = "Sent action to the host…";
            render();
        } catch (JSONException error) {
            connectionMessage = error.getMessage();
            render();
        }
    }

    private void broadcastSnapshot() throws JSONException {
        send(new NearbyEnvelope(sessionCode, localPlayerId, engine.state().revision, "snapshot", GameSnapshotCodec.encode(engine.state())));
    }

    private void sendError(String message, String recipientId) {
        try {
            send(new NearbyEnvelope(sessionCode, UUID.randomUUID().toString(), localPlayerId, engine.state().revision, "error", recipientId, new JSONObject().put("message", message)));
        } catch (JSONException ignored) { }
    }

    private void send(NearbyEnvelope envelope) throws JSONException {
        if (bluetoothMode && bluetooth != null) bluetooth.send(envelope.encode());
        else if (nearby != null) nearby.send(envelope.encode());
    }

    @Override public void onVerificationRequired(String endpointId, String endpointName, String digits) {
        runOnUiThread(() -> new AlertDialog.Builder(this)
            .setTitle("Verify nearby player")
            .setMessage("Does " + endpointName + " show the same digits?\n\n" + digits)
            .setNegativeButton("Reject", (dialog, which) -> nearby.reject(endpointId))
            .setPositiveButton("Accept", (dialog, which) -> nearby.accept(endpointId))
            .setCancelable(false)
            .show());
    }

    @Override public void onPeersChanged(java.util.Set<String> endpointIds) {
        runOnUiThread(() -> {
            nearbyPeerCount = endpointIds.size();
            if (!hosting && !sessionCode.isEmpty() && !endpointIds.isEmpty()) sendHello();
            if (hosting) connectionMessage = endpointIds.isEmpty() ? "Waiting for nearby players." : endpointIds.size() + " nearby peer(s) connected. Waiting for valid table code.";
            render();
        });
    }

    @Override public void onBytesReceived(String endpointId, byte[] bytes) {
        runOnUiThread(() -> receiveEnvelope(bytes));
    }

    @Override public void onError(String message) {
        runOnUiThread(() -> {
            connectionMessage = "Nearby error: " + message;
            render();
        });
    }

    private void receiveEnvelope(byte[] bytes) {
        try {
            NearbyEnvelope envelope = NearbyEnvelope.decode(bytes);
            if (!sessionCode.equals(envelope.sessionId) || localPlayerId.equals(envelope.senderId)) return;
            if (envelope.recipientId != null && !localPlayerId.equals(envelope.recipientId)) return;
            if (hosting && "hello".equals(envelope.type)) {
                if (!sessionCode.equals(envelope.payload.optString("code"))) {
                    sendError("That table code does not match this host.", envelope.senderId);
                    return;
                }
                String name = envelope.payload.optString("name", "Guest").trim();
                if (name.isEmpty()) name = "Guest";
                try {
                    if (engine.state().players.stream().noneMatch(player -> player.id.equals(envelope.senderId))) {
                        engine.join(envelope.senderId, name);
                    }
                    connectionMessage = name + " joined the table.";
                    broadcastSnapshot();
                } catch (Exception error) {
                    sendError(error.getMessage(), envelope.senderId);
                }
            } else if (hosting && "command".equals(envelope.type)) {
                String playerId = envelope.payload.optString("playerID");
                if ("start".equals(envelope.payload.optString("action"))) {
                    sendError("Only the host can start the game.", envelope.senderId);
                    return;
                }
                if (!envelope.senderId.equals(playerId) && !"start".equals(envelope.payload.optString("action"))) {
                    sendError("A player can only act for their own seat.", envelope.senderId);
                    return;
                }
                runHostAction(envelope.payload.optString("action"), playerId);
            } else if (!hosting && "snapshot".equals(envelope.type)) {
                GameState snapshot = GameSnapshotCodec.decode(envelope.payload);
                engine.applyHostSnapshot(snapshot);
                connectionMessage = "Connected to host · revision " + snapshot.revision;
            } else if ("error".equals(envelope.type)) {
                connectionMessage = envelope.payload.optString("message", "The host rejected that action.");
            }
            render();
        } catch (Exception error) {
            connectionMessage = "Ignored invalid nearby message: " + error.getMessage();
            render();
        }
    }

    private void requestNearbyPermissions() {
        if (Build.VERSION.SDK_INT >= 31) {
            requestPermissions(new String[] {
                Manifest.permission.BLUETOOTH_ADVERTISE,
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN
            }, 100);
        } else if (Build.VERSION.SDK_INT >= 29) {
            requestPermissions(new String[] { Manifest.permission.ACCESS_FINE_LOCATION }, 100);
        }
    }

    private boolean ensureBluetoothReady(String action) {
        BluetoothManager manager = getSystemService(BluetoothManager.class);
        BluetoothAdapter adapter = manager == null ? null : manager.getAdapter();
        if (adapter != null && adapter.isEnabled()) return true;
        connectionMessage = "Bluetooth is switched off. Turn it on, then try again to " + action + ".";
        render();
        return false;
    }

    private boolean ensureNearbyReady(String action) {
        BluetoothManager manager = getSystemService(BluetoothManager.class);
        BluetoothAdapter adapter = manager == null ? null : manager.getAdapter();
        if (adapter == null || !adapter.isEnabled()) {
            connectionMessage = "Nearby play needs Bluetooth switched on to discover the other phone. Turn it on, then try again to " + action + ".";
            render();
            return false;
        }
        if (Build.VERSION.SDK_INT >= 31 && (checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED || checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED)) {
            requestNearbyPermissions();
            connectionMessage = "Allow Nearby devices, then tap again to " + action + ".";
            render();
            return false;
        }
        return true;
    }

    private Button button(String label) { return button(label, false); }

    private Button button(String label, boolean primary) {
        Button button = new Button(this);
        button.setText(label);
        button.setAllCaps(false);
        button.setTextColor(Color.WHITE);
        button.setTextSize(16);
        button.setGravity(Gravity.CENTER);
        button.setPadding(dp(14), dp(10), dp(14), dp(10));
        button.setBackground(panelBackground(primary ? Color.rgb(70, 172, 130) : Color.rgb(35, 44, 64), 14));
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(-1, dp(52));
        params.setMargins(0, dp(5), 0, dp(5));
        button.setLayoutParams(params);
        return button;
    }

    private TextView sectionTitle(String label) {
        TextView view = text(label, 12, Color.rgb(137, 151, 177));
        view.setLetterSpacing(0.1f);
        view.setPadding(0, 0, 0, dp(9));
        return view;
    }

    private GradientDrawable panelBackground(int colour, int radius) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(colour);
        drawable.setCornerRadius(dp(radius));
        return drawable;
    }

    private void contentSpacer(LinearLayout target, int height) {
        View spacer = new View(this);
        target.addView(spacer, new LinearLayout.LayoutParams(1, dp(height)));
    }

    private TextView text(String value, int size, int colour) {
        TextView view = new TextView(this);
        view.setText(value);
        view.setTextSize(size);
        view.setTextColor(colour);
        return view;
    }

    private int dp(int value) { return Math.round(value * getResources().getDisplayMetrics().density); }

    private void openGameRoom(String template) {
        Intent intent = new Intent(this, GameRoomActivity.class);
        intent.putExtra(GameRoomActivity.EXTRA_TEMPLATE, template);
        startActivity(intent);
    }

    private interface Action { void run() throws Exception; }
    private void runAction(Action action) {
        try {
            action.run();
            render();
        } catch (Exception error) {
            connectionMessage = "Cannot continue: " + error.getMessage();
            render();
        }
    }
}
