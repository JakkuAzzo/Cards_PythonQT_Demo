package com.jakkuazzo.cards;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import com.jakkuazzo.cards.core.GameDraftParser;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

/** The product hub. Connection controls intentionally live in the Table destination. */
public final class HubActivity extends Activity {
    private static final int HOME = 0, LIBRARY = 1, TABLE = 2, CREATE = 3, DISCOVER = 4;
    private static final String DRAFTS_KEY = "saved_creator_drafts";
    private LinearLayout page, nav;
    private int tab = HOME;

    @Override public void onCreate(Bundle state) { super.onCreate(state); setContentView(layout()); render(); }

    private View layout() {
        LinearLayout root = new LinearLayout(this); root.setOrientation(LinearLayout.VERTICAL); root.setBackgroundColor(Color.rgb(8, 10, 16));
        ScrollView scroll = new ScrollView(this); scroll.setFillViewport(true);
        page = new LinearLayout(this); page.setOrientation(LinearLayout.VERTICAL); page.setPadding(dp(20), dp(20), dp(20), dp(20)); scroll.addView(page);
        root.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1));
        nav = new LinearLayout(this); nav.setOrientation(LinearLayout.HORIZONTAL); nav.setPadding(dp(8), dp(7), dp(8), dp(12)); nav.setBackgroundColor(Color.rgb(18, 21, 30));
        root.addView(nav, new LinearLayout.LayoutParams(-1, -2)); return root;
    }

    private void render() {
        page.removeAllViews(); nav.removeAllViews();
        if (tab == HOME) home(); else if (tab == LIBRARY) library(); else if (tab == TABLE) table(); else if (tab == CREATE) create(); else discover();
        String[] labels = {"Home", "Library", "Table", "Create", "Discover"};
        for (int i = 0; i < labels.length; i++) { final int next = i; Button b = button(labels[i], i == tab, 12); b.setOnClickListener(v -> { tab = next; render(); }); nav.addView(b, new LinearLayout.LayoutParams(0, dp(48), 1)); }
    }

    private void home() {
        TextView appName = text("Cards", 17, Color.WHITE); appName.setGravity(Gravity.CENTER_HORIZONTAL); page.addView(appName);
        eyebrow("READY WHEN YOU ARE"); title("Deal yourself in."); body("Pick a deck and make the next card the moment."); space(18);
        LinearLayout pack = card(Color.rgb(20, 157, 143), 26);
        LinearLayout packHeader = new LinearLayout(this); packHeader.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout packCopy = new LinearLayout(this); packCopy.setOrientation(LinearLayout.VERTICAL);
        TextView badge = text("CLASSIC", 11, Color.WHITE); badge.setLetterSpacing(.12f); packCopy.addView(badge);
        TextView name = text("Classic Pack 52", 27, Color.WHITE); name.setTypeface(null, Typeface.BOLD); name.setPadding(0, dp(7), 0, 0); packCopy.addView(name);
        packHeader.addView(packCopy, new LinearLayout.LayoutParams(0, -2, 1));
        TextView ace = text("A\n♠", 30, Color.rgb(18, 25, 31)); ace.setGravity(Gravity.CENTER); ace.setTypeface(null, Typeface.BOLD); ace.setBackground(background(Color.WHITE, 18)); packHeader.addView(ace, new LinearLayout.LayoutParams(dp(82), dp(112)));
        pack.addView(packHeader);
        TextView copy = text("The original Cards deck: a complete 52-card pack with bundled SVG faces and backs.", 14, Color.WHITE); copy.setPadding(0, dp(8), 0, 0); pack.addView(copy);
        TextView facts = text("Classic · Included     Offline ready", 13, Color.WHITE); facts.setPadding(0, dp(17), 0, 0); pack.addView(facts); page.addView(pack, full());
        Button solo = button("Start a solo game", true, 16); solo.setOnClickListener(v -> openTable()); page.addView(solo, full());
        LinearLayout row = new LinearLayout(this); row.setOrientation(LinearLayout.HORIZONTAL);
        Button shuffle = button("Shuffle", false, 14); shuffle.setOnClickListener(v -> Toast.makeText(this, "Classic Pack shuffled.", Toast.LENGTH_SHORT).show());
        Button details = button("Deck details", false, 14); details.setOnClickListener(v -> { tab = LIBRARY; render(); });
        row.addView(shuffle, half(0)); row.addView(details, half(dp(10))); page.addView(row, full());
        space(16); heading("Your table, so far");
        LinearLayout stats = card(Color.rgb(31, 36, 45), 22); stats.addView(text("0     Sessions", 17, Color.WHITE)); stats.addView(text("0     Cards drawn", 17, Color.WHITE));
        TextView hint = text("Host or join a nearby table from the Table tab.", 13, Color.rgb(188, 198, 213)); hint.setPadding(0, dp(12), 0, 0); stats.addView(hint); page.addView(stats, full());
    }

    private void library() {
        title("Deck Library"); body("Games included with Cards. Choose one to start playing."); space(12);
        game("Classic Pack Poker", "Private hands and a shared table", "poker"); game("Guess Who Board", "Private target, shared board", "guess-who"); game("Double-Six Dominoes", "2–4 players · shared tile table", "dominoes");
        List<SavedDraft> drafts = savedDrafts();
        if (!drafts.isEmpty()) {
            space(12); heading("Your created games");
            body("Saved only on this phone. Each uses a bundled, validated template.");
            for (SavedDraft draft : drafts) creatorGame(draft);
        }
    }
    private void table() { eyebrow("PLAY TOGETHER"); title("Your live table"); body("Host or join nearby. Bluetooth and nearby availability are checked before anything is advertised."); space(12); Button open = button("Open table controls", true, 16); open.setOnClickListener(v -> openTable()); page.addView(open, full()); body("Use this destination for table codes, Bluetooth pairing, player status, and leaving a table."); }
    private void create() { eyebrow("CREATE YOUR OWN"); title("Make a game."); body("Describe poker, guess who, dominoes, or a prompt game. Settings only select tested templates and bundled resources."); space(12); EditText draft = new EditText(this); draft.setText("idea: four-player poker night\nmultiplayer: y\nmax_users: 4\nar: n\ntabledesign: poker_2.png"); draft.setTextColor(Color.WHITE); draft.setTextSize(14); draft.setMinLines(7); draft.setGravity(Gravity.TOP); draft.setBackground(background(Color.rgb(35, 44, 64), 22)); draft.setPadding(dp(16), dp(16), dp(16), dp(16)); page.addView(draft, full()); Button build = button("Save validated draft", true, 16); build.setOnClickListener(v -> startDraft(draft.getText().toString())); page.addView(build, full()); body("Unknown game types, player ranges outside 1–16, and unbundled resources are rejected. Saved games appear in your Library and never run generated code."); }
    private void discover() { title("Discover"); body("Included games and starter templates worth trying next."); space(12); LinearLayout item = card(Color.rgb(14, 112, 105), 24); item.addView(text("NEW BUILT-IN GAME", 11, Color.WHITE)); TextView name = text("Double-Six Dominoes", 25, Color.WHITE); name.setTypeface(null, Typeface.BOLD); name.setPadding(0, dp(7), 0, 0); item.addView(name); TextView copy = text("Place matching tiles on a shared table. Each player has a private hand.", 14, Color.WHITE); copy.setPadding(0, dp(8), 0, 0); item.addView(copy); page.addView(item, full()); Button dominoes = button("Play Double-Six Dominoes", true, 16); dominoes.setOnClickListener(v -> openDominoes()); page.addView(dominoes, full()); Button poker = button("Try Classic Pack Poker", false, 16); poker.setOnClickListener(v -> gameRoom("poker")); page.addView(poker, full()); Button guess = button("Try Guess Who", false, 16); guess.setOnClickListener(v -> gameRoom("guess-who")); page.addView(guess, full()); }

    private void game(String name, String copy, String template) { LinearLayout item = card(Color.rgb(28, 34, 48), 20); TextView label = text(name, 19, Color.WHITE); label.setTypeface(null, Typeface.BOLD); item.addView(label); TextView detail = text(copy, 13, Color.rgb(188, 198, 213)); detail.setPadding(0, dp(6), 0, 0); item.addView(detail); Button play = button("Play", true, 14); play.setOnClickListener(v -> { if ("dominoes".equals(template)) openDominoes(); else gameRoom(template); }); item.addView(play); page.addView(item, full()); }
    private void creatorGame(SavedDraft draft) { LinearLayout item = card(Color.rgb(27, 70, 77), 20); TextView label = text(draft.name, 19, Color.WHITE); label.setTypeface(null, Typeface.BOLD); item.addView(label); TextView detail = text("" + draft.template + " · up to " + draft.maximumPlayers + " players · " + draft.tableDesign + " · AR " + (draft.arEnabled ? "on" : "off"), 13, Color.rgb(214, 236, 233)); detail.setPadding(0, dp(6), 0, 0); item.addView(detail); LinearLayout controls = new LinearLayout(this); controls.setOrientation(LinearLayout.HORIZONTAL); Button play = button("Play", true, 14); play.setOnClickListener(v -> launchDraft(draft)); controls.addView(play, new LinearLayout.LayoutParams(0, dp(50), 1)); Button remove = button("Remove", false, 14); remove.setContentDescription("Remove " + draft.name + " from your library"); remove.setOnClickListener(v -> { removeDraft(draft); render(); }); LinearLayout.LayoutParams removeParams = new LinearLayout.LayoutParams(0, dp(50), 1); removeParams.setMargins(dp(8), 0, 0, 0); controls.addView(remove, removeParams); item.addView(controls); page.addView(item, full()); }
    private void gameRoom(String template) { Intent intent = new Intent(this, GameRoomActivity.class); intent.putExtra(GameRoomActivity.EXTRA_TEMPLATE, template); startActivity(intent); }
    private void openDominoes() { startActivity(new Intent(this, DominoesActivity.class)); }
    private void openTable() { startActivity(new Intent(this, MainActivity.class)); }
    private void startDraft(String value) { try { GameDraftParser.Draft draft = GameDraftParser.parse(value); saveDraft(new SavedDraft(draft)); Toast.makeText(this, "Saved " + draft.name + " to your Library.", Toast.LENGTH_LONG).show(); tab = LIBRARY; render(); } catch (IllegalArgumentException error) { Toast.makeText(this, error.getMessage(), Toast.LENGTH_LONG).show(); } }
    private void launchDraft(SavedDraft draft) { if ("dominoes".equals(draft.template)) openDominoes(); else if ("poker".equals(draft.template) || "guess-who".equals(draft.template)) gameRoom(draft.template); else openTable(); }
    private List<SavedDraft> savedDrafts() { List<SavedDraft> drafts = new ArrayList<>(); String stored = getSharedPreferences("cards", MODE_PRIVATE).getString(DRAFTS_KEY, "[]"); try { JSONArray values = new JSONArray(stored); for (int index = 0; index < values.length(); index++) { JSONObject value = values.optJSONObject(index); if (value != null) drafts.add(new SavedDraft(value)); } } catch (Exception ignored) { } return drafts; }
    private void saveDraft(SavedDraft draft) { List<SavedDraft> drafts = savedDrafts(); for (int index = drafts.size() - 1; index >= 0; index--) if (drafts.get(index).name.equalsIgnoreCase(draft.name)) drafts.remove(index); drafts.add(draft); JSONArray values = new JSONArray(); for (SavedDraft value : drafts) values.put(value.json()); getSharedPreferences("cards", MODE_PRIVATE).edit().putString(DRAFTS_KEY, values.toString()).apply(); }
    private void removeDraft(SavedDraft draft) { List<SavedDraft> drafts = savedDrafts(); drafts.removeIf(value -> value.name.equals(draft.name)); JSONArray values = new JSONArray(); for (SavedDraft value : drafts) values.put(value.json()); getSharedPreferences("cards", MODE_PRIVATE).edit().putString(DRAFTS_KEY, values.toString()).apply(); }
    private static final class SavedDraft { final String name, template, tableDesign; final int maximumPlayers; final boolean arEnabled; SavedDraft(GameDraftParser.Draft draft) { name = draft.name; template = draft.template; maximumPlayers = draft.maximumPlayers; arEnabled = draft.arEnabled; tableDesign = draft.tableDesign; } SavedDraft(JSONObject value) { name = value.optString("name", "Created game"); template = value.optString("template", "prompt-draw"); tableDesign = value.optString("tableDesign", "green-classic"); maximumPlayers = value.optInt("maximumPlayers", 4); arEnabled = value.optBoolean("arEnabled"); } JSONObject json() { JSONObject value = new JSONObject(); try { value.put("name", name); value.put("template", template); value.put("tableDesign", tableDesign); value.put("maximumPlayers", maximumPlayers); value.put("arEnabled", arEnabled); } catch (Exception ignored) { } return value; } }
    private void eyebrow(String value) { TextView v = text(value, 11, Color.rgb(108, 221, 183)); v.setTypeface(null, Typeface.BOLD); v.setLetterSpacing(.12f); page.addView(v); }
    private void title(String value) { TextView v = text(value, 33, Color.WHITE); v.setTypeface(null, Typeface.BOLD); v.setPadding(0, dp(7), 0, 0); page.addView(v); }
    private void heading(String value) { TextView v = text(value, 19, Color.WHITE); v.setTypeface(null, Typeface.BOLD); page.addView(v); }
    private void body(String value) { TextView v = text(value, 15, Color.rgb(190, 198, 213)); v.setPadding(0, dp(8), 0, 0); page.addView(v); }
    private Button button(String value, boolean primary, int size) { Button v = new Button(this); v.setText(value); v.setAllCaps(false); v.setTextSize(size); v.setTextColor(primary ? Color.rgb(8, 20, 18) : Color.WHITE); v.setGravity(Gravity.CENTER); v.setPadding(dp(8), 0, dp(8), 0); v.setBackground(background(primary ? Color.rgb(70, 220, 170) : Color.rgb(51, 67, 99), 18)); return v; }
    private LinearLayout card(int color, int radius) { LinearLayout v = new LinearLayout(this); v.setOrientation(LinearLayout.VERTICAL); v.setPadding(dp(18), dp(18), dp(18), dp(18)); v.setBackground(background(color, radius)); return v; }
    private GradientDrawable background(int color, int radius) { GradientDrawable d = new GradientDrawable(); d.setColor(color); d.setCornerRadius(dp(radius)); return d; }
    private LinearLayout.LayoutParams full() { LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2); p.setMargins(0, dp(6), 0, dp(6)); return p; }
    private LinearLayout.LayoutParams half(int left) { LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, dp(52), 1); p.setMargins(left, 0, 0, 0); return p; }
    private void space(int pixels) { page.addView(new View(this), new LinearLayout.LayoutParams(1, dp(pixels))); }
    private TextView text(String value, int size, int color) { TextView v = new TextView(this); v.setText(value); v.setTextSize(size); v.setTextColor(color); return v; }
    private int dp(int value) { return Math.round(value * getResources().getDisplayMetrics().density); }
}
