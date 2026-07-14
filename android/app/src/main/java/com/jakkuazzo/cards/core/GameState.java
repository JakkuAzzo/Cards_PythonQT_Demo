package com.jakkuazzo.cards.core;

import java.util.ArrayList;
import java.util.List;

public final class GameState {
    public enum Phase { LOBBY, WAITING_FOR_DRAW, SHOWING_CARD, FINISHED }

    public int revision = 0;
    public Phase phase = Phase.LOBBY;
    public final List<Player> players = new ArrayList<>();
    public int activePlayerIndex = 0;
    public final List<CardRecord> drawPile = new ArrayList<>();
    public final List<CardRecord> discardPile = new ArrayList<>();
    public CardRecord currentCard;
    public Long seed;

    public Player activePlayer() {
        return players.isEmpty() ? null : players.get(activePlayerIndex);
    }
}

