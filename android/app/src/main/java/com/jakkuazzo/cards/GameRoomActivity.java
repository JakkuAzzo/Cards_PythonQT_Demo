package com.jakkuazzo.cards;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.view.Gravity;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import com.jakkuazzo.cards.nearby.BLEEnvelopeCipher;
import com.jakkuazzo.cards.nearby.BluetoothGattTransport;
import com.jakkuazzo.cards.nearby.GameRoomNetworkSession;
import com.jakkuazzo.cards.nearby.NearbyEnvelope;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/** Two-phone Poker/Guess Who room with host-authoritative encrypted BLE state. */
public final class GameRoomActivity extends Activity implements BluetoothGattTransport.Listener {
    public static final String EXTRA_TEMPLATE = "template";
    private enum RoomMode { COMBINED, TABLE, DECK }
    private final String localPlayerId = UUID.randomUUID().toString();
    private final List<String> characters = Arrays.asList("Alex", "Blair", "Casey", "Drew", "Emery", "Frankie", "Gray", "Harper", "Indigo", "Jules", "Kai", "Lane");
    private final List<String> community = new ArrayList<>(), hand = new ArrayList<>(), guestHand = new ArrayList<>();
    private final Set<String> eliminated = new HashSet<>();
    private boolean poker, hosting, targetVisible, guestFolded;
    private RoomMode roomMode = RoomMode.COMBINED;
    private String target, guestTarget, selectedCharacter, winner = "", status = "Play locally, or host/join one encrypted Bluetooth room.";
    private int pot;
    private String sessionCode = "", pairingSecret = "", guestPlayerId = "";
    private BluetoothGattTransport bluetooth;
    private GameRoomNetworkSession network;
    private LinearLayout content;
    private EditText joinCode, joinSecret;

    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);
        poker = "poker".equals(getIntent().getStringExtra(EXTRA_TEMPLATE));
        requestBluetoothPermissions(); resetGame(); render();
    }

    private void resetGame() {
        community.clear(); hand.clear(); guestHand.clear(); eliminated.clear(); targetVisible = false; guestFolded = false; winner = ""; selectedCharacter = null; pot = 0;
        if (poker) { List<String> deck = pokerDeck(); Collections.shuffle(deck); hand.add(deck.remove(0)); hand.add(deck.remove(0)); guestHand.add(deck.remove(0)); guestHand.add(deck.remove(0)); }
        else { List<String> targets = new ArrayList<>(characters); Collections.shuffle(targets); target = targets.get(0); guestTarget = targets.get(1); }
        status = poker ? "Classic Pack dealt. Each phone keeps its own hand private." : "Private targets assigned. The shared board is public.";
    }

    private void render() {
        ScrollView scroll = new ScrollView(this); scroll.setBackgroundColor(Color.rgb(8, 10, 16));
        content = new LinearLayout(this); content.setOrientation(LinearLayout.VERTICAL); content.setPadding(dp(20), dp(28), dp(20), dp(28)); scroll.addView(content); setContentView(scroll);
        title(poker ? "Classic Pack Poker" : "Guess Who Board", 29);
        body(poker ? "Two-phone Texas Hold'em · public table, private hands, optional AR." : "Two-phone private-target game · shared board, private deck, optional AR.");
        body(status); roomControls(); roomSelector();
        if (roomMode != RoomMode.DECK) tablePage(); if (roomMode != RoomMode.TABLE) deckPage();
        Button ar = button(poker ? "Open AR table" : "Open AR board"); ar.setOnClickListener(v -> { Intent i = new Intent(this, ArTableActivity.class); i.putExtra(ArTableActivity.EXTRA_SURFACE_TITLE, poker ? "Poker shared table" : "Guess Who board"); startActivity(i); }); content.addView(ar);
        Button reset = button("New game"); reset.setOnClickListener(v -> { if (hosting || network == null) { resetGame(); publish(); render(); } else network.submit(new GameRoomNetworkSession.Command("restart", localPlayerId, null, null)); }); content.addView(reset);
    }

    private void roomControls() {
        section("Nearby room · two phones");
        if (network == null) {
            Button host = button("Host with Bluetooth"); host.setOnClickListener(v -> hostRoom()); content.addView(host);
            joinCode = new EditText(this); joinCode.setHint("Room code, e.g. CARDS-1234"); joinCode.setSingleLine(true); content.addView(joinCode);
            joinSecret = new EditText(this); joinSecret.setHint("Pairing secret from host"); joinSecret.setSingleLine(true); content.addView(joinSecret);
            Button join = button("Join with Bluetooth"); join.setOnClickListener(v -> joinRoom(joinCode.getText().toString(), joinSecret.getText().toString())); content.addView(join);
        } else {
            body((hosting ? "Hosting " : "Joining ") + sessionCode + (pairingSecret.isEmpty() ? "" : "\nSecret: " + pairingSecret));
            Button leave = button("Leave nearby room"); leave.setOnClickListener(v -> leaveRoom()); content.addView(leave);
        }
    }

    private void roomSelector() { LinearLayout row = new LinearLayout(this); for (RoomMode mode : RoomMode.values()) { Button b = button(mode == RoomMode.COMBINED ? "Combined" : mode == RoomMode.TABLE ? "Table" : "Your deck"); b.setEnabled(roomMode != mode); b.setOnClickListener(v -> { roomMode = mode; render(); }); row.addView(b, new LinearLayout.LayoutParams(0, -2, 1)); } content.addView(row); }
    private void tablePage() {
        section(poker ? "Shared table" : "Shared board / score tracker");
        if (poker) { body("Pot: " + pot + " chips · Community cards: " + (community.isEmpty() ? "hidden" : join(community)) + (guestFolded ? " · Guest folded" : "")); Button next = button(community.size() < 3 ? "Reveal flop" : community.size() < 4 ? "Reveal turn" : community.size() < 5 ? "Reveal river" : "Showdown ready"); next.setEnabled(community.size() < 5); next.setOnClickListener(v -> action("advance-street", null, null)); content.addView(next); Button fold = button("Fold"); fold.setOnClickListener(v -> action("fold", null, null)); content.addView(fold); }
        else { body((characters.size() - eliminated.size()) + " possibilities remain." + (selectedCharacter == null ? " Select a character." : " Selected: " + selectedCharacter) + (winner.isEmpty() ? "" : " Winner: " + winner)); for (String character : characters) { Button tile = button((eliminated.contains(character) ? "✓ " : "") + character); tile.setOnClickListener(v -> { selectedCharacter = character; render(); }); content.addView(tile); } Button eliminate = button("Toggle selected character"); eliminate.setEnabled(selectedCharacter != null); eliminate.setOnClickListener(v -> action("toggle-elimination", selectedCharacter, null)); content.addView(eliminate); Button guess = button("Guess selected character"); guess.setEnabled(selectedCharacter != null); guess.setOnClickListener(v -> action("guess", selectedCharacter, null)); content.addView(guess); }
    }
    private void deckPage() {
        section("Your deck");
        if (poker) { body("Private hand: " + join(hand)); Button bet = button("Bet 20 chips"); bet.setOnClickListener(v -> action("bet", null, 20)); content.addView(bet); }
        else { body(targetVisible ? "Your private target: " + target : "Private target hidden"); Button reveal = button(targetVisible ? "Hide target" : "Reveal target"); reveal.setOnClickListener(v -> { targetVisible = !targetVisible; render(); }); content.addView(reveal); Button question = button("Ask a question"); question.setOnClickListener(v -> action("ask-question", null, null)); content.addView(question); }
    }

    private void action(String name, String character, Integer amount) { if (network != null && !hosting) network.submit(new GameRoomNetworkSession.Command(name, localPlayerId, character, amount)); else { applyHostCommand(new GameRoomNetworkSession.Command(name, localPlayerId, character, amount)); publish(); render(); } }
    private boolean applyHostCommand(GameRoomNetworkSession.Command command) {
        if (poker) { if ("advance-street".equals(command.action)) revealStreet(); else if ("bet".equals(command.action)) { int amount = command.amount == null ? 20 : command.amount; pot += amount; status = "A player added " + amount + " chips to the pot."; } else if ("fold".equals(command.action)) { guestFolded = !localPlayerId.equals(command.playerId); status = "A player folded."; } else if ("restart".equals(command.action)) resetGame(); else return false; }
        else { if ("toggle-elimination".equals(command.action)) { if (command.characterId == null) return false; if (eliminated.contains(command.characterId)) eliminated.remove(command.characterId); else eliminated.add(command.characterId); } else if ("ask-question".equals(command.action)) status = "Question asked. Check your private target before answering."; else if ("guess".equals(command.action)) { if (command.characterId == null) return false; String wanted = localPlayerId.equals(command.playerId) ? guestTarget : target; winner = wanted.equals(command.characterId) ? "Correct guess" : "Incorrect guess"; } else if ("restart".equals(command.action)) resetGame(); else return false; }
        return true;
    }
    private void revealStreet() { String[] cards = {"A♥", "10♣", "7♦", "4♠", "K♥"}; int amount = community.isEmpty() ? 3 : 1; for (int i = 0; i < amount && community.size() < cards.length; i++) community.add(cards[community.size()]); status = "Shared table updated. Private cards remain private."; }

    private void hostRoom() { leaveRoom(); hosting = true; sessionCode = String.format("CARDS-%04d", (int) (Math.random() * 10000)); pairingSecret = BLEEnvelopeCipher.makePairingSecret(); bluetooth = new BluetoothGattTransport(this, this, sessionCode, pairingSecret); configureNetwork(GameRoomNetworkSession.Role.HOST); bluetooth.host(); status = "Bluetooth host ready. Share code and secret with one guest."; render(); }
    private void joinRoom(String code, String secret) { String normalized = code.toUpperCase().trim(); if (!normalized.matches("CARDS-[0-9]{4}") || secret.trim().isEmpty()) { status = "Enter the host's CARDS-1234 code and pairing secret."; render(); return; } leaveRoom(); hosting = false; sessionCode = normalized; pairingSecret = secret.trim(); bluetooth = new BluetoothGattTransport(this, this, sessionCode, pairingSecret); configureNetwork(GameRoomNetworkSession.Role.GUEST); bluetooth.join(); status = "Scanning for " + sessionCode + "…"; render(); }
    private void configureNetwork(GameRoomNetworkSession.Role role) {
        network = new GameRoomNetworkSession(poker ? "poker" : "guess-who", localPlayerId, role == GameRoomNetworkSession.Role.HOST ? "Host" : "Guest", sessionCode, role, envelope -> bluetooth.send(envelope.encode()), new GameRoomNetworkSession.Callbacks() {
            @Override public boolean onHostCommand(GameRoomNetworkSession.Command command) { boolean applied = applyHostCommand(command); if (applied) { publish(); render(); } return applied; }
            @Override public void onPeerJoined(String id) { guestPlayerId = id; publish(); }
            @Override public void onPublicSnapshot(JSONObject state) { applyPublic(state); render(); }
            @Override public void onPrivateState(JSONObject state) { applyPrivate(state); render(); }
            @Override public void onStatus(String value) { status = value; render(); }
        });
        network.connected();
    }
    private void publish() { if (network == null || !hosting) return; HashMap<String, JSONObject> privateStates = new HashMap<>(); if (!guestPlayerId.isEmpty()) privateStates.put(guestPlayerId, privateState()); network.publish(publicState(), privateStates); }
    private JSONObject publicState() { try { JSONObject state = new JSONObject(); state.put("community", new JSONArray(community)); state.put("pot", pot); state.put("guestFolded", guestFolded); state.put("eliminated", new JSONArray(eliminated)); state.put("winner", winner); return state; } catch (Exception error) { return new JSONObject(); } }
    private JSONObject privateState() { try { JSONObject state = new JSONObject(); state.put("hand", new JSONArray(guestHand)); state.put("target", guestTarget); return state; } catch (Exception error) { return new JSONObject(); } }
    private void applyPublic(JSONObject state) { community.clear(); JSONArray cards = state.optJSONArray("community"); if (cards != null) for (int i = 0; i < cards.length(); i++) community.add(cards.optString(i)); eliminated.clear(); JSONArray removed = state.optJSONArray("eliminated"); if (removed != null) for (int i = 0; i < removed.length(); i++) eliminated.add(removed.optString(i)); pot = state.optInt("pot"); guestFolded = state.optBoolean("guestFolded"); winner = state.optString("winner"); }
    private void applyPrivate(JSONObject state) { JSONArray cards = state.optJSONArray("hand"); if (cards != null) { hand.clear(); for (int i = 0; i < cards.length(); i++) hand.add(cards.optString(i)); } if (state.has("target")) target = state.optString("target"); }
    private void leaveRoom() { if (bluetooth != null) bluetooth.stop(); bluetooth = null; network = null; hosting = false; sessionCode = pairingSecret = guestPlayerId = ""; }
    @Override public void onPeersChanged(Set<String> peers) { runOnUiThread(() -> { if (network != null && !hosting && !peers.isEmpty()) network.connected(); }); }
    @Override public void onBytesReceived(String peer, byte[] bytes) { runOnUiThread(() -> { try { if (network != null) network.receive(NearbyEnvelope.decode(bytes)); } catch (Exception error) { status = "Ignored invalid nearby message."; render(); } }); }
    @Override public void onError(String message) { runOnUiThread(() -> { status = "Bluetooth error: " + message; render(); }); }
    private void requestBluetoothPermissions() { if (Build.VERSION.SDK_INT >= 31) requestPermissions(new String[] {Manifest.permission.BLUETOOTH_ADVERTISE, Manifest.permission.BLUETOOTH_CONNECT, Manifest.permission.BLUETOOTH_SCAN}, 101); }
    private List<String> pokerDeck() { List<String> deck = new ArrayList<>(); for (String suit : Arrays.asList("♥", "♦", "♣", "♠")) for (String rank : Arrays.asList("A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K")) deck.add(rank + suit); return deck; }
    private void title(String value, int size) { TextView v = text(value, size, Color.WHITE); content.addView(v); } private void section(String value) { TextView v = text(value, 19, Color.rgb(245,183,43)); v.setPadding(0,dp(18),0,dp(8)); content.addView(v); } private void body(String value) { TextView v = text(value,14,Color.LTGRAY); v.setPadding(0,0,0,dp(10)); content.addView(v); } private TextView text(String value,int size,int color){ TextView v=new TextView(this);v.setText(value);v.setTextSize(size);v.setTextColor(color);return v;} private Button button(String label){Button b=new Button(this);b.setText(label);b.setAllCaps(false);return b;} private String join(List<String> values){return String.join(" · ",values);} private int dp(int value){return Math.round(value*getResources().getDisplayMetrics().density);}
}
