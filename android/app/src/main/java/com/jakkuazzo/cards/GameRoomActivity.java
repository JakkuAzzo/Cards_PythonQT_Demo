package com.jakkuazzo.cards;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Local game room shared by the bundled Poker and Guess Who templates. */
public final class GameRoomActivity extends Activity {
    public static final String EXTRA_TEMPLATE = "template";
    private enum RoomMode { COMBINED, TABLE, DECK }

    private boolean poker;
    private RoomMode roomMode = RoomMode.COMBINED;
    private final List<String> community = new ArrayList<>();
    private final List<String> hand = new ArrayList<>();
    private final Set<String> eliminated = new HashSet<>();
    private final List<String> characters = Arrays.asList("Alex", "Blair", "Casey", "Drew", "Emery", "Frankie", "Gray", "Harper", "Indigo", "Jules", "Kai", "Lane");
    private String target;
    private boolean targetVisible;
    private String status = "Choose a digital view or open the shared AR surface.";
    private LinearLayout content;

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        poker = "poker".equals(getIntent().getStringExtra(EXTRA_TEMPLATE));
        resetGame();
        render();
    }

    private void resetGame() {
        community.clear(); hand.clear(); eliminated.clear(); targetVisible = false;
        if (poker) {
            List<String> deck = pokerDeck();
            Collections.shuffle(deck);
            hand.add(deck.remove(0)); hand.add(deck.remove(0));
            status = "Classic Pack dealt. Your private cards stay on the deck page.";
        } else {
            List<String> targets = new ArrayList<>(characters);
            Collections.shuffle(targets);
            target = targets.get(0);
            status = "Private target assigned. Use the shared board to eliminate possibilities.";
        }
    }

    private void render() {
        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(Color.rgb(8, 10, 16));
        content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(dp(20), dp(28), dp(20), dp(28));
        scroll.addView(content);
        setContentView(scroll);

        title(poker ? "Classic Pack Poker" : "Guess Who Board", 29);
        body(poker ? "Texas Hold'em with a shared table, private cards, and optional AR surface." : "A private target game with a shared board and optional AR score surface.");
        body(status);
        roomSelector();

        if (roomMode != RoomMode.DECK) tablePage();
        if (roomMode != RoomMode.TABLE) deckPage();

        Button ar = button(poker ? "Open AR table" : "Open AR board");
        ar.setOnClickListener(view -> {
            Intent intent = new Intent(this, ArTableActivity.class);
            intent.putExtra(ArTableActivity.EXTRA_SURFACE_TITLE, poker ? "Classic Pack Poker shared table" : "Guess Who shared board");
            startActivity(intent);
        });
        content.addView(ar);
        Button reset = button("New game");
        reset.setOnClickListener(view -> { resetGame(); render(); });
        content.addView(reset);
    }

    private void roomSelector() {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        for (RoomMode mode : RoomMode.values()) {
            Button button = button(mode == RoomMode.COMBINED ? "Combined" : mode == RoomMode.TABLE ? "Table" : "Your deck");
            button.setEnabled(roomMode != mode);
            button.setOnClickListener(view -> { roomMode = mode; render(); });
            row.addView(button, new LinearLayout.LayoutParams(0, -2, 1));
        }
        content.addView(row);
    }

    private void tablePage() {
        section(poker ? "Shared table" : "Shared board / score tracker");
        if (poker) {
            body("Pot: 0 chips · Community cards: " + (community.isEmpty() ? "hidden" : join(community)));
            Button next = button(community.size() < 3 ? "Reveal flop" : community.size() < 4 ? "Reveal turn" : community.size() < 5 ? "Reveal river" : "Showdown ready");
            next.setEnabled(community.size() < 5);
            next.setOnClickListener(view -> revealStreet());
            content.addView(next);
            body("Players · You · Avery · Jordan · Riley");
        } else {
            body((characters.size() - eliminated.size()) + " possibilities remain. Tap a character to eliminate or restore it.");
            for (String character : characters) {
                Button tile = button((eliminated.contains(character) ? "✓ " : "") + character);
                tile.setOnClickListener(view -> {
                    if (eliminated.contains(character)) eliminated.remove(character); else eliminated.add(character);
                    status = character + (eliminated.contains(character) ? " eliminated from the shared board." : " restored to the shared board.");
                    render();
                });
                content.addView(tile);
            }
        }
    }

    private void deckPage() {
        section("Your deck");
        if (poker) {
            body("Private hand: " + join(hand));
            Button bet = button("Bet 20 chips");
            bet.setOnClickListener(view -> { status = "You added 20 chips to the pot."; render(); });
            content.addView(bet);
        } else {
            body(targetVisible ? "Your private target: " + target : "Private target hidden");
            Button reveal = button(targetVisible ? "Hide target" : "Reveal target");
            reveal.setOnClickListener(view -> { targetVisible = !targetVisible; render(); });
            content.addView(reveal);
            Button pass = button("Ask a question / pass device");
            pass.setOnClickListener(view -> { targetVisible = false; status = "Question asked. Pass the device to the other player."; render(); });
            content.addView(pass);
        }
    }

    private void revealStreet() {
        String[] cards = {"A♥", "10♣", "7♦", "4♠", "K♥"};
        int next = community.size();
        int amount = next == 0 ? 3 : 1;
        for (int index = 0; index < amount && community.size() < cards.length; index++) community.add(cards[community.size()]);
        status = "Shared table updated. Private cards remain on each player’s deck page.";
        render();
    }

    private List<String> pokerDeck() {
        List<String> deck = new ArrayList<>();
        for (String suit : Arrays.asList("♥", "♦", "♣", "♠")) for (String rank : Arrays.asList("A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K")) deck.add(rank + suit);
        return deck;
    }

    private void title(String value, int size) { TextView view = text(value, size, Color.WHITE); view.setPadding(0, 0, 0, dp(4)); content.addView(view); }
    private void section(String value) { TextView view = text(value, 19, Color.rgb(245, 183, 43)); view.setPadding(0, dp(18), 0, dp(8)); content.addView(view); }
    private void body(String value) { TextView view = text(value, 14, Color.LTGRAY); view.setPadding(0, 0, 0, dp(10)); content.addView(view); }
    private TextView text(String value, int size, int colour) { TextView view = new TextView(this); view.setText(value); view.setTextSize(size); view.setTextColor(colour); return view; }
    private Button button(String label) { Button button = new Button(this); button.setText(label); button.setAllCaps(false); return button; }
    private String join(List<String> values) { return String.join(" · ", values); }
    private int dp(int value) { return Math.round(value * getResources().getDisplayMetrics().density); }
}
