package com.jakkuazzo.cards.core;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/** Host-authoritative double-six draw dominoes rules; UI and transport consume this state. */
public final class DominoesGame {
    public static final int MIN_PLAYERS = 2;
    public static final int MAX_PLAYERS = 4;
    public static final int HAND_SIZE = 7;

    public static final class Tile {
        public final int left;
        public final int right;
        public Tile(int left, int right) { this.left = left; this.right = right; }
        public int pips() { return left + right; }
        public boolean matches(int value) { return left == value || right == value; }
        public String label() { return left + " | " + right; }
    }

    private final List<List<Tile>> hands = new ArrayList<>();
    private final List<Tile> train = new ArrayList<>();
    private final List<Tile> boneyard = new ArrayList<>();
    private int activePlayer;
    private int consecutivePasses;
    private boolean finished;
    private Tile openingTile;
    private int[] scores = new int[0];
    private String message = "Add players and start a round.";

    public void startRound(int players) {
        if (players < MIN_PLAYERS || players > MAX_PLAYERS) throw new IllegalArgumentException("Dominoes needs 2–4 players.");
        hands.clear(); train.clear(); boneyard.clear(); finished = false; consecutivePasses = 0;
        List<Tile> tiles = new ArrayList<>();
        for (int left = 0; left <= 6; left++) for (int right = left; right <= 6; right++) tiles.add(new Tile(left, right));
        Collections.shuffle(tiles);
        for (int player = 0; player < players; player++) {
            List<Tile> hand = new ArrayList<>();
            for (int card = 0; card < HAND_SIZE; card++) hand.add(tiles.remove(0));
            hands.add(hand);
        }
        boneyard.addAll(tiles);
        scores = new int[players];
        activePlayer = openingPlayer();
        message = "Player " + (activePlayer + 1) + " opens with " + openingTile.label() + ".";
    }

    public int players() { return hands.size(); }
    public int activePlayer() { return activePlayer; }
    public List<Tile> hand(int player) { return Collections.unmodifiableList(hands.get(player)); }
    public List<Tile> train() { return Collections.unmodifiableList(train); }
    public int boneyardCount() { return boneyard.size(); }
    public int score(int player) { return scores[player]; }
    public String message() { return message; }
    public boolean isStarted() { return !hands.isEmpty(); }
    public boolean isFinished() { return finished; }

    public boolean canPlay(int player, Tile tile) {
        if (!isStarted() || finished || player != activePlayer || !hands.get(player).contains(tile)) return false;
        return train.isEmpty() ? tile == openingTile : tile.matches(leftEnd()) || tile.matches(rightEnd());
    }

    public boolean play(int player, Tile tile, boolean atLeft) {
        if (!canPlay(player, tile)) return false;
        Tile oriented = orient(tile, atLeft);
        hands.get(player).remove(tile);
        consecutivePasses = 0;
        if (atLeft) train.add(0, oriented); else train.add(oriented);
        if (hands.get(player).isEmpty()) {
            int awarded = 0;
            for (int index = 0; index < hands.size(); index++) if (index != player) for (Tile remaining : hands.get(index)) awarded += remaining.pips();
            scores[player] += awarded;
            finished = true;
            message = "Player " + (player + 1) + " emptied their hand and scores " + awarded + ". Start a new round.";
            return true;
        }
        activePlayer = (activePlayer + 1) % hands.size();
        message = "Tile placed. Player " + (activePlayer + 1) + " plays next.";
        return true;
    }

    public boolean draw(int player) {
        if (!isStarted() || finished || player != activePlayer || boneyard.isEmpty()) return false;
        Tile tile = boneyard.remove(0);
        hands.get(player).add(tile);
        message = "Player " + (player + 1) + " drew " + tile.label() + ".";
        return true;
    }

    public boolean pass(int player) {
        if (!isStarted() || finished || player != activePlayer || !boneyard.isEmpty() || hasPlayable(player)) return false;
        consecutivePasses++;
        if (consecutivePasses >= hands.size()) {
            int winner = 0;
            int lowest = handPips(0);
            for (int index = 1; index < hands.size(); index++) if (handPips(index) < lowest) { winner = index; lowest = handPips(index); }
            int awarded = 0;
            for (int index = 0; index < hands.size(); index++) if (index != winner) awarded += handPips(index);
            scores[winner] += awarded;
            activePlayer = winner;
            finished = true;
            message = "Blocked round. Player " + (winner + 1) + " has the lowest hand and scores " + awarded + ". Start a new round.";
            return true;
        }
        activePlayer = (activePlayer + 1) % hands.size();
        message = "Player " + (player == 0 ? "1" : Integer.toString(player + 1)) + " passes. Player " + (activePlayer + 1) + " plays next.";
        return true;
    }

    public boolean hasPlayable(int player) {
        if (finished) return false;
        if (train.isEmpty()) return !hands.get(player).isEmpty();
        for (Tile tile : hands.get(player)) if (tile.matches(leftEnd()) || tile.matches(rightEnd())) return true;
        return false;
    }

    private int openingPlayer() {
        for (int value = 6; value >= 0; value--) for (int player = 0; player < hands.size(); player++) for (Tile tile : hands.get(player)) if (tile.left == value && tile.right == value) { openingTile = tile; return player; }
        openingTile = hands.get(0).get(0);
        return 0;
    }
    private int leftEnd() { return train.get(0).left; }
    private int rightEnd() { return train.get(train.size() - 1).right; }
    private int handPips(int player) { int total = 0; for (Tile tile : hands.get(player)) total += tile.pips(); return total; }
    private Tile orient(Tile tile, boolean atLeft) {
        if (train.isEmpty()) return tile;
        int required = atLeft ? leftEnd() : rightEnd();
        if (atLeft) return tile.right == required ? tile : new Tile(tile.right, tile.left);
        return tile.left == required ? tile : new Tile(tile.right, tile.left);
    }
}
