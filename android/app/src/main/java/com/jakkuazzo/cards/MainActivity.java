package com.jakkuazzo.cards;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import com.jakkuazzo.cards.core.GameState;
import com.jakkuazzo.cards.core.MultiplayerEngine;

public final class MainActivity extends Activity {
    private final MultiplayerEngine engine = new MultiplayerEngine();
    private TextView status;
    private TextView card;
    private LinearLayout actions;
    private int guestNumber = 1;

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(buildContent());
        try {
            engine.join("host", "You");
        } catch (Exception ignored) { }
        requestNearbyPermissions();
        render();
    }

    private View buildContent() {
        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(Color.rgb(8, 10, 16));
        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(dp(20), dp(32), dp(20), dp(32));

        TextView title = text("Live Table", 30, Color.WHITE);
        title.setTypeface(null, android.graphics.Typeface.BOLD);
        content.addView(title);
        TextView subtitle = text("The same deterministic nearby-game core as iPhone.", 15, Color.LTGRAY);
        subtitle.setPadding(0, dp(6), 0, dp(20));
        content.addView(subtitle);

        status = text("", 14, Color.LTGRAY);
        content.addView(status);

        card = text("", 24, Color.WHITE);
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setPadding(dp(22), dp(22), dp(22), dp(22));
        card.setBackgroundColor(Color.rgb(93, 45, 145));
        LinearLayout.LayoutParams cardParams = new LinearLayout.LayoutParams(-1, dp(300));
        cardParams.setMargins(0, dp(18), 0, dp(18));
        content.addView(card, cardParams);

        actions = new LinearLayout(this);
        actions.setOrientation(LinearLayout.VERTICAL);
        content.addView(actions, new LinearLayout.LayoutParams(-1, -2));

        Button ar = button("Open AR table capability");
        ar.setOnClickListener(view -> startActivity(new Intent(this, ArTableActivity.class)));
        content.addView(ar);
        scroll.addView(content);
        return scroll;
    }

    private void render() {
        GameState state = engine.state();
        String active = state.activePlayer() == null ? "None" : state.activePlayer().name;
        status.setText("Phase: " + state.phase + "  ·  Revision: " + state.revision + "  ·  Active: " + active);
        card.setText(state.currentCard == null ? (state.phase == GameState.Phase.FINISHED ? "Game complete" : "Ready to draw") : state.currentCard.text);
        actions.removeAllViews();

        if (state.phase == GameState.Phase.LOBBY) {
            Button join = button("Simulate nearby player");
            join.setOnClickListener(view -> runAction(() -> {
                int number = guestNumber++;
                engine.join("guest-" + number, "Player " + (number + 1));
            }));
            actions.addView(join);

            Button start = button("Start with seed 42");
            start.setEnabled(state.players.size() >= MultiplayerEngine.MINIMUM_PLAYERS);
            start.setOnClickListener(view -> runAction(() -> engine.start(42L)));
            actions.addView(start);
        } else if (state.phase == GameState.Phase.WAITING_FOR_DRAW) {
            Button draw = button("Draw for " + active);
            draw.setOnClickListener(view -> runAction(() -> engine.draw(state.activePlayer().id)));
            actions.addView(draw);
        } else if (state.phase == GameState.Phase.SHOWING_CARD) {
            Button end = button("End turn");
            end.setOnClickListener(view -> runAction(() -> engine.endTurn(state.activePlayer().id)));
            actions.addView(end);
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

    private void runAction(Action action) {
        try {
            action.run();
            render();
        } catch (Exception error) {
            status.setText("Cannot continue: " + error.getMessage());
        }
    }

    private Button button(String label) {
        Button button = new Button(this);
        button.setText(label);
        button.setAllCaps(false);
        return button;
    }

    private TextView text(String value, int size, int colour) {
        TextView view = new TextView(this);
        view.setText(value);
        view.setTextSize(size);
        view.setTextColor(colour);
        return view;
    }

    private int dp(int value) { return Math.round(value * getResources().getDisplayMetrics().density); }

    private interface Action { void run() throws Exception; }
}

