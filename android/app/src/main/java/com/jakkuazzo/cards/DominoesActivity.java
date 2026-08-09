package com.jakkuazzo.cards;

import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.view.Gravity;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import com.jakkuazzo.cards.core.DominoesGame;

/** Local Draw Dominoes room. Its state shape is deliberately transport-ready. */
public final class DominoesActivity extends android.app.Activity {
    private enum Mode { COMBINED, TABLE, HAND }
    private final DominoesGame game = new DominoesGame();
    private final Handler handler = new Handler();
    private Mode mode = Mode.COMBINED;
    private boolean cardsAI;
    private LinearLayout content;

    @Override protected void onCreate(Bundle state) { super.onCreate(state); game.startRound(2); render(); }

    private void render() {
        ScrollView scroll = new ScrollView(this); scroll.setBackgroundColor(Color.rgb(8, 10, 16));
        content = new LinearLayout(this); content.setOrientation(LinearLayout.VERTICAL); content.setPadding(dp(20), dp(24), dp(20), dp(28)); scroll.addView(content); setContentView(scroll);
        title("Double-Six Dominoes"); body("Draw dominoes · 2–4 players · shared train and private hands."); body(localMessage());
        LinearLayout modes = new LinearLayout(this); modes.setOrientation(LinearLayout.HORIZONTAL);
        for (Mode value : Mode.values()) { Button button = button(value == Mode.COMBINED ? "Combined" : value == Mode.TABLE ? "Table" : "Your hand"); button.setEnabled(value != mode); button.setOnClickListener(v -> { mode = value; render(); }); modes.addView(button, new LinearLayout.LayoutParams(0, -2, 1)); }
        content.addView(modes);
        if (mode != Mode.HAND) table();
        if (mode != Mode.TABLE) hand();
        Button ai = button(cardsAI ? "Cards AI opponent on" : "Play against Cards AI"); ai.setOnClickListener(v -> { cardsAI = !cardsAI; render(); scheduleAI(); }); content.addView(ai);
        Button ar = button("Open camera table placement"); ar.setOnClickListener(v -> startActivity(new Intent(this, ArTableActivity.class).putExtra(ArTableActivity.EXTRA_SURFACE_TITLE, "Dominoes shared table"))); content.addView(ar);
        Button reset = button("New round"); reset.setOnClickListener(v -> { game.startRound(2); render(); }); content.addView(reset);
    }

    private void table() {
        section("Shared table");
        String train = game.train().isEmpty() ? "No tile placed yet." : labels(game.train());
        body(game.isFinished() ? "Round complete · " + activePlayerLabel() + " scored " + game.score(game.activePlayer()) : "Boneyard: " + game.boneyardCount() + " · " + activePlayerLabel() + " to play");
        if (!game.train().isEmpty()) { LinearLayout row = new LinearLayout(this); for (DominoesGame.Tile tile : game.train()) row.addView(dominoTile(tile, true), new LinearLayout.LayoutParams(dp(76), dp(52))); content.addView(row); }
        Button draw = button("Draw tile"); draw.setEnabled(!game.isFinished() && game.boneyardCount() > 0 && (!cardsAI || game.activePlayer() == 0)); draw.setOnClickListener(v -> { game.draw(game.activePlayer()); afterMove(); }); content.addView(draw);
        Button pass = button("Pass (only if no legal tile)"); pass.setEnabled(!game.isFinished() && game.boneyardCount() == 0 && !game.hasPlayable(game.activePlayer()) && (!cardsAI || game.activePlayer() == 0)); pass.setOnClickListener(v -> { game.pass(game.activePlayer()); afterMove(); }); content.addView(pass);
        body("Scores · You: " + game.score(0) + " · Player 2: " + game.score(1));
    }

    private void hand() {
        int player = game.activePlayer();
        section(player == 0 ? "Your hand" : (cardsAI ? "Cards AI hand" : "Player 2 hand"));
        if (game.isFinished()) { body("Round complete. Start a new round whenever you are ready."); return; }
        if (cardsAI && player == 1) { body("Cards AI is choosing a legal tile…"); return; }
        body(cardsAI ? "Tap a legal domino to place it on the shared train." : "Pass the device privately, then tap a legal domino to play.");
        LinearLayout row = null;
        int index = 0;
        for (DominoesGame.Tile tile : game.hand(player)) { if (index % 3 == 0) { row = new LinearLayout(this); content.addView(row); } Button play = dominoTile(tile, false); play.setEnabled(game.canPlay(player, tile)); play.setOnClickListener(v -> { game.play(player, tile, false); afterMove(); }); LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, dp(72), 1); params.setMargins(dp(3), dp(3), dp(3), dp(3)); row.addView(play, params); index++; }
    }

    private String labels(java.util.List<DominoesGame.Tile> tiles) { StringBuilder out = new StringBuilder(); for (DominoesGame.Tile tile : tiles) { if (out.length() > 0) out.append("  ·  "); out.append(tile.label()); } return out.toString(); }
    private String localMessage() { return game.message().replace("Player 1", "You").replace("Player 2", cardsAI ? "Cards AI" : "Player 2"); }
    private String activePlayerLabel() { return game.activePlayer() == 0 ? "You" : (cardsAI ? "Cards AI" : "Player 2"); }
    private void afterMove() { render(); scheduleAI(); }
    private void scheduleAI() { if (!cardsAI || !game.isStarted() || game.activePlayer() != 1) return; handler.postDelayed(() -> { if (!cardsAI || game.activePlayer() != 1) return; DominoesGame.Tile choice = null; for (DominoesGame.Tile tile : game.hand(1)) if (game.canPlay(1, tile)) { choice = tile; break; } if (choice != null) game.play(1, choice, false); else if (game.boneyardCount() > 0) game.draw(1); else game.pass(1); afterMove(); }, 700); }
    private void title(String value) { TextView v = text(value, 29, Color.WHITE); v.setTypeface(null, android.graphics.Typeface.BOLD); content.addView(v); }
    private void section(String value) { TextView v = text(value, 18, Color.rgb(108, 221, 183)); v.setPadding(0, dp(16), 0, dp(7)); content.addView(v); }
    private void body(String value) { TextView v = text(value, 14, Color.LTGRAY); v.setPadding(0, dp(5), 0, dp(8)); content.addView(v); }
    private Button button(String value) { Button v = new Button(this); v.setText(value); v.setTextSize(16); v.setAllCaps(false); v.setTextColor(Color.WHITE); v.setGravity(Gravity.CENTER); GradientDrawable shape = new GradientDrawable(); shape.setColor(value.startsWith("Play against") || value.startsWith("Open camera") ? Color.rgb(26,150,134) : Color.rgb(48,67,106)); shape.setCornerRadius(dp(16)); v.setBackground(shape); LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(-1, dp(56)); params.setMargins(0,dp(5),0,dp(5)); v.setLayoutParams(params); return v; }
    private Button dominoTile(DominoesGame.Tile tile, boolean compact) { Button v = new Button(this); v.setText(pips(tile.left) + "  │  " + pips(tile.right)); v.setTextSize(compact ? 13 : 15); v.setAllCaps(false); v.setTextColor(Color.rgb(24,28,35)); v.setGravity(Gravity.CENTER); v.setContentDescription(tile.label() + " domino"); GradientDrawable shape = new GradientDrawable(); shape.setColor(Color.rgb(248,244,230)); shape.setCornerRadius(dp(12)); shape.setStroke(dp(1), Color.rgb(185,175,150)); v.setBackground(shape); return v; }
    private String pips(int count) { StringBuilder pips = new StringBuilder(); for (int index = 0; index < count; index++) pips.append("●"); return pips.length() == 0 ? "·" : pips.toString(); }
    private TextView text(String value, int size, int color) { TextView v = new TextView(this); v.setText(value); v.setTextSize(size); v.setTextColor(color); return v; }
    private int dp(int value) { return Math.round(value * getResources().getDisplayMetrics().density); }
}
