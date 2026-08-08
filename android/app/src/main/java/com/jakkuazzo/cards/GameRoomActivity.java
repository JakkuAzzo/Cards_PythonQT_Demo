package com.jakkuazzo.cards;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
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
import com.jakkuazzo.cards.core.PokerHandEvaluator;

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

/**
 * Purpose: renders the Android Poker and Guess Who rooms.
 *
 * Responsibilities: owns their current local UI state, switches among Table,
 * Deck, and Combined views, and coordinates optional encrypted BLE room
 * delivery through {@link GameRoomNetworkSession}.
 *
 * Constraints: the host remains authoritative; public room state must not
 * reveal a guest hand or Guess Who target. Keep deterministic game rules in a
 * focused model when extracting behaviour from this activity.
 */
public final class GameRoomActivity extends Activity implements BluetoothGattTransport.Listener {
    public static final String EXTRA_TEMPLATE = "template";
    private enum RoomMode { COMBINED, TABLE, DECK }
    private final String localPlayerId = UUID.randomUUID().toString();
    private final List<String> characters = Arrays.asList("Alex", "Blair", "Casey", "Drew", "Emery", "Frankie", "Gray", "Harper", "Indigo", "Jules", "Kai", "Lane");
    private final List<String> community = new ArrayList<>(), hand = new ArrayList<>(), guestHand = new ArrayList<>();
    private final Set<String> eliminated = new HashSet<>();
    private boolean poker, hosting, targetVisible, guestFolded, hostFolded, nearbyExpanded;
    private boolean cardsAI;
    private final Handler handler = new Handler();
    private RoomMode roomMode = RoomMode.COMBINED;
    private String target, guestTarget, selectedCharacter, winner = "", status = "Play locally, or host/join one encrypted Bluetooth room.";
    private int pot, hostChips, guestChips;
    private int guessTurn;
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
        community.clear(); hand.clear(); guestHand.clear(); eliminated.clear(); targetVisible = false; guestFolded = false; hostFolded = false; winner = ""; selectedCharacter = null; pot = 0; hostChips = 1_000; guestChips = 1_000; guessTurn = 0;
        if (poker) { List<String> deck = pokerDeck(); Collections.shuffle(deck); hand.add(deck.remove(0)); hand.add(deck.remove(0)); guestHand.add(deck.remove(0)); guestHand.add(deck.remove(0)); }
        else { List<String> targets = new ArrayList<>(characters); Collections.shuffle(targets); target = targets.get(0); guestTarget = targets.get(1); }
        status = poker ? "Classic Pack dealt. Each phone keeps its own hand private." : "Private targets assigned. The shared board is public.";
    }

    private void render() {
        ScrollView scroll = new ScrollView(this); scroll.setBackgroundColor(Color.rgb(8, 10, 16));
        content = new LinearLayout(this); content.setOrientation(LinearLayout.VERTICAL); content.setPadding(dp(20), dp(28), dp(20), dp(28)); scroll.addView(content); setContentView(scroll);
        title(poker ? "Classic Pack Poker" : "Guess Who Board", 29);
        body(poker ? "Two-phone Texas Hold'em · public table, private hands, optional AR." : "Two-phone private-target game · shared board, private deck, optional AR.");
        body(status); roomSelector();
        if (network == null) { Button ai = button(cardsAI ? "Cards AI opponent on" : "Play against Cards AI"); ai.setOnClickListener(v -> { cardsAI = !cardsAI; status = cardsAI ? "Cards AI will answer after your local actions." : "Local opponent mode."; render(); }); content.addView(ai); }
        if (roomMode != RoomMode.DECK) tablePage(); if (roomMode != RoomMode.TABLE) deckPage();
        roomControls();
        Button ar = button(poker ? "Open AR table" : "Open AR board"); ar.setOnClickListener(v -> { Intent i = new Intent(this, ArTableActivity.class); i.putExtra(ArTableActivity.EXTRA_SURFACE_TITLE, poker ? "Poker shared table" : "Guess Who board"); startActivity(i); }); content.addView(ar);
        Button reset = button("New game"); reset.setOnClickListener(v -> { if (hosting || network == null) { resetGame(); publish(); render(); } else network.submit(new GameRoomNetworkSession.Command("restart", localPlayerId, null, null)); }); content.addView(reset);
    }

    private void roomControls() {
        section("Play together");
        if (network == null && !nearbyExpanded) {
            body("Solo play is ready now. Set up a nearby Bluetooth room only when another phone is joining.");
            Button open = button("Set up nearby Bluetooth table"); open.setOnClickListener(v -> { nearbyExpanded = true; render(); }); content.addView(open);
            return;
        }
        if (network == null) {
            Button host = button("Host with Bluetooth"); host.setOnClickListener(v -> hostRoom()); content.addView(host);
            joinCode = new EditText(this); joinCode.setHint("Room code, e.g. CARDS-1234"); joinCode.setSingleLine(true); content.addView(joinCode);
            joinSecret = new EditText(this); joinSecret.setHint("Pairing secret from host"); joinSecret.setSingleLine(true); content.addView(joinSecret);
            Button join = button("Join with Bluetooth"); join.setOnClickListener(v -> joinRoom(joinCode.getText().toString(), joinSecret.getText().toString())); content.addView(join);
            Button close = button("Keep playing locally"); close.setOnClickListener(v -> { nearbyExpanded = false; render(); }); content.addView(close);
        } else {
            body((hosting ? "Hosting " : "Joining ") + sessionCode + (pairingSecret.isEmpty() ? "" : "\nSecret: " + pairingSecret));
            Button leave = button("Leave nearby room"); leave.setOnClickListener(v -> { leaveRoom(); render(); }); content.addView(leave);
        }
    }

    private void roomSelector() { LinearLayout row = new LinearLayout(this); for (RoomMode mode : RoomMode.values()) { Button b = button(mode == RoomMode.COMBINED ? "Combined" : mode == RoomMode.TABLE ? "Table" : "Your deck"); b.setEnabled(roomMode != mode); b.setOnClickListener(v -> { roomMode = mode; render(); }); LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, dp(48), 1); params.setMargins(dp(3), 0, dp(3), dp(8)); row.addView(b, params); } content.addView(row); }
    private void tablePage() {
        section(poker ? "Shared table" : "Shared board / score tracker");
        if (poker) { body("Pot: " + pot + " chips · You: " + localChips() + " · Opponent: " + opponentChips() + "\nCommunity cards: " + (community.isEmpty() ? "hidden" : join(community)) + (hostFolded ? " · Host folded" : "") + (guestFolded ? " · Guest folded" : "") + (winner.isEmpty() ? "" : "\n" + winner)); String nextLabel = community.size() < 3 ? "Reveal flop" : community.size() < 4 ? "Reveal turn" : community.size() < 5 ? "Reveal river" : "Show hands & settle pot"; Button next = button(nextLabel); next.setEnabled(winner.isEmpty()); next.setOnClickListener(v -> action(community.size() < 5 ? "advance-street" : "showdown", null, null)); content.addView(next); Button fold = button("Fold"); fold.setEnabled(winner.isEmpty()); fold.setOnClickListener(v -> action("fold", null, null)); content.addView(fold); }
        else { boolean yours = guessTurn == 0; body((yours ? "Your turn. " : "Cards AI's turn. ") + (characters.size() - eliminated.size()) + " possibilities remain." + (selectedCharacter == null ? " Select a character." : " Selected: " + selectedCharacter) + (winner.isEmpty() ? "" : " Winner: " + winner)); characterGrid(); Button eliminate = button("Eliminate selected character"); eliminate.setEnabled(yours && selectedCharacter != null && winner.isEmpty()); eliminate.setOnClickListener(v -> action("toggle-elimination", selectedCharacter, null)); content.addView(eliminate); Button guess = button("Make your guess"); guess.setEnabled(yours && selectedCharacter != null && winner.isEmpty()); guess.setOnClickListener(v -> action("guess", selectedCharacter, null)); content.addView(guess); }
    }
    private void deckPage() {
        section("Your deck");
        if (poker) { body("Private hand: " + join(hand)); Button bet = button("Bet 20 chips"); bet.setEnabled(winner.isEmpty() && localChips() >= 20); bet.setOnClickListener(v -> action("bet", null, 20)); content.addView(bet); }
        else { body(targetVisible ? "Your private target: " + target : "Private target hidden"); Button reveal = button(targetVisible ? "Hide target" : "Reveal target"); reveal.setEnabled(winner.isEmpty()); reveal.setOnClickListener(v -> { targetVisible = !targetVisible; render(); }); content.addView(reveal); Button question = button("Ask a question"); question.setEnabled(guessTurn == 0 && winner.isEmpty()); question.setOnClickListener(v -> action("ask-question", null, null)); content.addView(question); }
    }

    private void action(String name, String character, Integer amount) { if (network != null && !hosting) network.submit(new GameRoomNetworkSession.Command(name, localPlayerId, character, amount)); else if (applyHostCommand(new GameRoomNetworkSession.Command(name, localPlayerId, character, amount))) { publish(); render(); scheduleAI(); } }
    private boolean applyHostCommand(GameRoomNetworkSession.Command command) {
        if (poker) { if ("advance-street".equals(command.action)) revealStreet(); else if ("showdown".equals(command.action)) { if (community.size() < 5) return false; settleShowdown(); } else if ("bet".equals(command.action)) { int amount = command.amount == null ? 20 : command.amount; if (amount <= 0 || amount > 1_000) return false; boolean hostBet = localPlayerId.equals(command.playerId); if (hostBet && hostChips < amount || !hostBet && guestChips < amount) return false; if (hostBet) hostChips -= amount; else guestChips -= amount; pot += amount; status = "A player added " + amount + " chips to the pot."; } else if ("fold".equals(command.action)) { boolean hostFoldedNow = localPlayerId.equals(command.playerId); if (hostFoldedNow) hostFolded = true; else guestFolded = true; settleFold(hostFoldedNow ? 1 : 0); } else if ("restart".equals(command.action)) resetGame(); else return false; }
        else { if (network == null && !"restart".equals(command.action) && guessTurn != 0) return false; if ("toggle-elimination".equals(command.action)) { if (command.characterId == null) return false; if (eliminated.contains(command.characterId)) eliminated.remove(command.characterId); else eliminated.add(command.characterId); } else if ("ask-question".equals(command.action)) { guessTurn = 1; status = "Question asked. Cards AI is considering its answer."; } else if ("guess".equals(command.action)) { if (command.characterId == null) return false; if (guestTarget.equals(command.characterId)) winner = "You guessed " + command.characterId + " correctly"; else { guessTurn = 1; status = "Not " + command.characterId + ". Cards AI takes a turn."; } } else if ("restart".equals(command.action)) resetGame(); else return false; }
        return true;
    }
    private void revealStreet() { String[] cards = {"A♥", "10♣", "7♦", "4♠", "K♥"}; int amount = community.isEmpty() ? 3 : 1; for (int i = 0; i < amount && community.size() < cards.length; i++) community.add(cards[community.size()]); status = "Shared table updated. Private cards remain private."; }
    private void settleFold(int winningPlayer) { int award = pot; if (winningPlayer == 0) hostChips += award; else guestChips += award; pot = 0; winner = (winningPlayer == 0 ? "Host" : "Guest") + " wins by fold and takes " + award + " chips"; status = "Hand complete. " + winner + "."; }
    private void settleShowdown() { long hostScore = PokerHandEvaluator.score(hand, community), guestScore = PokerHandEvaluator.score(guestHand, community); int award = pot; if (hostScore > guestScore) { hostChips += pot; winner = "Host wins with " + PokerHandEvaluator.label(hostScore) + " and takes " + award + " chips"; } else if (guestScore > hostScore) { guestChips += pot; winner = "Guest wins with " + PokerHandEvaluator.label(guestScore) + " and takes " + award + " chips"; } else { int hostShare = (pot + 1) / 2; hostChips += hostShare; guestChips += pot - hostShare; winner = "Split pot with " + PokerHandEvaluator.label(hostScore) + ". Host receives the odd chip."; } pot = 0; status = "Showdown complete. " + winner + "."; }
    private int localChips() { return network == null || hosting ? hostChips : guestChips; }
    private int opponentChips() { return network == null || hosting ? guestChips : hostChips; }
    private void scheduleAI() { if (!cardsAI || network != null || !winner.isEmpty()) return; handler.postDelayed(() -> { if (!cardsAI || network != null || !winner.isEmpty()) return; if (poker) { if (community.size() < 5) revealStreet(); else if (guestChips >= 20) { guestChips -= 20; pot += 20; status = "Cards AI calls 20 chips. Your turn."; } } else if (guessTurn == 1) { for (String character : characters) if (!eliminated.contains(character)) { eliminated.add(character); status = "Cards AI eliminated " + character + ". Your turn to choose or guess."; break; } guessTurn = 0; } publish(); render(); }, 600); }

    private void characterGrid() {
        for (int start = 0; start < characters.size(); start += 3) {
            LinearLayout row = new LinearLayout(this);
            for (int index = start; index < Math.min(start + 3, characters.size()); index++) {
                String character = characters.get(index);
                Button tile = button((eliminated.contains(character) ? "✓ " : "") + character);
                tile.setTextSize(13); tile.setEnabled(winner.isEmpty());
                tile.setOnClickListener(v -> { selectedCharacter = character; render(); });
                LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, dp(56), 1); params.setMargins(dp(3), dp(3), dp(3), dp(3)); row.addView(tile, params);
            }
            content.addView(row);
        }
    }

    private void hostRoom() { if (!ensureBluetoothReady("host a room")) return; leaveRoom(); hosting = true; sessionCode = String.format("CARDS-%04d", (int) (Math.random() * 10000)); pairingSecret = BLEEnvelopeCipher.makePairingSecret(); bluetooth = new BluetoothGattTransport(this, this, sessionCode, pairingSecret); configureNetwork(GameRoomNetworkSession.Role.HOST); bluetooth.host(); status = "Bluetooth host ready. Share code and secret with one guest."; render(); }
    private void joinRoom(String code, String secret) { if (!ensureBluetoothReady("join a room")) return; String normalized = code.toUpperCase().trim(); if (!normalized.matches("CARDS-[0-9]{4}") || secret.trim().isEmpty()) { status = "Enter the host's CARDS-1234 code and pairing secret."; render(); return; } leaveRoom(); hosting = false; sessionCode = normalized; pairingSecret = secret.trim(); bluetooth = new BluetoothGattTransport(this, this, sessionCode, pairingSecret); configureNetwork(GameRoomNetworkSession.Role.GUEST); bluetooth.join(); status = "Scanning for " + sessionCode + "…"; render(); }
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
    private JSONObject publicState() { try { JSONObject state = new JSONObject(); state.put("community", new JSONArray(community)); state.put("pot", pot); state.put("hostFolded", hostFolded); state.put("guestFolded", guestFolded); state.put("hostChips", hostChips); state.put("guestChips", guestChips); state.put("eliminated", new JSONArray(eliminated)); state.put("winner", winner); state.put("guessTurn", guessTurn); state.put("status", status); return state; } catch (Exception error) { return new JSONObject(); } }
    private JSONObject privateState() { try { JSONObject state = new JSONObject(); state.put("hand", new JSONArray(guestHand)); state.put("target", guestTarget); return state; } catch (Exception error) { return new JSONObject(); } }
    private void applyPublic(JSONObject state) { community.clear(); JSONArray cards = state.optJSONArray("community"); if (cards != null) for (int i = 0; i < cards.length(); i++) community.add(cards.optString(i)); eliminated.clear(); JSONArray removed = state.optJSONArray("eliminated"); if (removed != null) for (int i = 0; i < removed.length(); i++) eliminated.add(removed.optString(i)); pot = state.optInt("pot"); hostFolded = state.optBoolean("hostFolded"); guestFolded = state.optBoolean("guestFolded"); hostChips = state.optInt("hostChips", hostChips); guestChips = state.optInt("guestChips", guestChips); winner = state.optString("winner"); guessTurn = state.optInt("guessTurn", guessTurn); status = state.optString("status", status); }
    private void applyPrivate(JSONObject state) { JSONArray cards = state.optJSONArray("hand"); if (cards != null) { hand.clear(); for (int i = 0; i < cards.length(); i++) hand.add(cards.optString(i)); } if (state.has("target")) target = state.optString("target"); }
    private void leaveRoom() { if (bluetooth != null) bluetooth.stop(); bluetooth = null; network = null; hosting = false; nearbyExpanded = false; sessionCode = pairingSecret = guestPlayerId = ""; status = "Local game. Play on this phone or set up a nearby Bluetooth room."; }
    @Override public void onPeersChanged(Set<String> peers) { runOnUiThread(() -> { if (network != null && !hosting && !peers.isEmpty()) network.connected(); }); }
    @Override public void onBytesReceived(String peer, byte[] bytes) { runOnUiThread(() -> { try { if (network != null) network.receive(NearbyEnvelope.decode(bytes)); } catch (Exception error) { status = "Ignored invalid nearby message."; render(); } }); }
    @Override public void onError(String message) { runOnUiThread(() -> { status = "Bluetooth error: " + message; render(); }); }
    private void requestBluetoothPermissions() { if (Build.VERSION.SDK_INT >= 31) requestPermissions(new String[] {Manifest.permission.BLUETOOTH_ADVERTISE, Manifest.permission.BLUETOOTH_CONNECT, Manifest.permission.BLUETOOTH_SCAN}, 101); }
    private boolean ensureBluetoothReady(String action) { BluetoothManager manager = getSystemService(BluetoothManager.class); BluetoothAdapter adapter = manager == null ? null : manager.getAdapter(); if (adapter == null || !adapter.isEnabled()) { status = "Bluetooth is switched off. Turn it on, then try again to " + action + "."; render(); return false; } if (Build.VERSION.SDK_INT >= 31 && (checkSelfPermission(Manifest.permission.BLUETOOTH_ADVERTISE) != PackageManager.PERMISSION_GRANTED || checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED || checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED)) { requestBluetoothPermissions(); status = "Allow Nearby devices, then tap again to " + action + "."; render(); return false; } return true; }
    private List<String> pokerDeck() { List<String> deck = new ArrayList<>(); for (String suit : Arrays.asList("♥", "♦", "♣", "♠")) for (String rank : Arrays.asList("A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K")) deck.add(rank + suit); return deck; }
    private void title(String value, int size) { TextView v = text(value, size, Color.WHITE); v.setTypeface(null, 1); content.addView(v); } private void section(String value) { TextView v = text(value, 19, Color.rgb(245,183,43)); v.setPadding(0,dp(18),0,dp(8)); content.addView(v); } private void body(String value) { TextView v = text(value,14,Color.LTGRAY); v.setPadding(0,0,0,dp(10)); content.addView(v); } private TextView text(String value,int size,int color){ TextView v=new TextView(this);v.setText(value);v.setTextSize(size);v.setTextColor(color);return v;} private Button button(String label){Button b=new Button(this);b.setText(label);b.setTextSize(16);b.setAllCaps(false);b.setTextColor(Color.WHITE);b.setPadding(dp(12),0,dp(12),0); GradientDrawable background=new GradientDrawable(); background.setColor(label.startsWith("Reveal") || label.startsWith("Show") || label.startsWith("Make") || label.startsWith("Play against") ? Color.rgb(26,150,134) : Color.rgb(48,67,106)); background.setCornerRadius(dp(16)); b.setBackground(background); LinearLayout.LayoutParams params=new LinearLayout.LayoutParams(-1,dp(56)); params.setMargins(0,dp(5),0,dp(5)); b.setLayoutParams(params); return b;} private String join(List<String> values){return String.join(" · ",values);} private int dp(int value){return Math.round(value*getResources().getDisplayMetrics().density);}
}
