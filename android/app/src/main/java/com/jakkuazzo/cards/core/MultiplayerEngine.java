package com.jakkuazzo.cards.core;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class MultiplayerEngine {
    public static final int MINIMUM_PLAYERS = 2;
    public static final int MAXIMUM_PLAYERS = 8;

    public enum Error {
        LOBBY_CLOSED, DUPLICATE_PLAYER, LOBBY_FULL, NOT_ENOUGH_PLAYERS,
        ALREADY_STARTED, NOT_PLAYERS_TURN, WRONG_PHASE, DECK_EMPTY
    }

    public static final class RuleException extends Exception {
        private static final long serialVersionUID = 1L;
        public final Error error;
        RuleException(Error error) { super(error.name()); this.error = error; }
    }

    private final GameState state = new GameState();
    private final List<CardRecord> sourceDeck;

    public MultiplayerEngine() {
        sourceDeck = Arrays.asList(
            new CardRecord("tt-01", "What tiny decision changed your life more than you expected?"),
            new CardRecord("tt-02", "Which place have you visited that still feels vivid?"),
            new CardRecord("tt-03", "What skill would you love to become excellent at overnight?"),
            new CardRecord("tt-04", "What is a hill you are willing to die on?"),
            new CardRecord("tt-05", "Which ordinary day would you happily relive?"),
            new CardRecord("tt-06", "What has made you laugh hardest this year?"),
            new CardRecord("tt-07", "What is something you changed your mind about recently?"),
            new CardRecord("tt-08", "Which fictional world would you visit for one week?")
        );
    }

    public GameState state() { return state; }

    public void join(String id, String name) throws RuleException {
        require(state.phase == GameState.Phase.LOBBY, Error.LOBBY_CLOSED);
        require(state.players.stream().noneMatch(player -> player.id.equals(id)), Error.DUPLICATE_PLAYER);
        require(state.players.size() < MAXIMUM_PLAYERS, Error.LOBBY_FULL);
        state.players.add(new Player(id, name, state.players.isEmpty()));
        state.revision++;
    }

    public void start(long seed) throws RuleException {
        require(state.phase == GameState.Phase.LOBBY, Error.ALREADY_STARTED);
        require(state.players.size() >= MINIMUM_PLAYERS, Error.NOT_ENOUGH_PLAYERS);
        state.seed = seed;
        state.drawPile.clear();
        state.drawPile.addAll(SeededShuffle.shuffle(sourceDeck, seed));
        state.activePlayerIndex = 0;
        state.phase = GameState.Phase.WAITING_FOR_DRAW;
        state.revision++;
    }

    public CardRecord draw(String playerId) throws RuleException {
        requireTurn(playerId);
        require(state.phase == GameState.Phase.WAITING_FOR_DRAW, Error.WRONG_PHASE);
        require(!state.drawPile.isEmpty(), Error.DECK_EMPTY);
        state.currentCard = state.drawPile.remove(0);
        state.phase = GameState.Phase.SHOWING_CARD;
        state.revision++;
        return state.currentCard;
    }

    public void endTurn(String playerId) throws RuleException {
        requireTurn(playerId);
        require(state.phase == GameState.Phase.SHOWING_CARD, Error.WRONG_PHASE);
        state.discardPile.add(state.currentCard);
        state.currentCard = null;
        if (state.drawPile.isEmpty()) {
            state.phase = GameState.Phase.FINISHED;
        } else {
            state.activePlayerIndex = (state.activePlayerIndex + 1) % state.players.size();
            state.phase = GameState.Phase.WAITING_FOR_DRAW;
        }
        state.revision++;
    }

    public List<CardRecord> sourceDeck() { return new ArrayList<>(sourceDeck); }

    /** Guests only apply snapshots authored by the host and never mutate state directly. */
    public void applyHostSnapshot(GameState snapshot) {
        if (snapshot.revision < state.revision) return;
        state.revision = snapshot.revision;
        state.phase = snapshot.phase;
        state.players.clear();
        state.players.addAll(snapshot.players);
        state.activePlayerIndex = snapshot.activePlayerIndex;
        state.drawPile.clear();
        state.drawPile.addAll(snapshot.drawPile);
        state.discardPile.clear();
        state.discardPile.addAll(snapshot.discardPile);
        state.currentCard = snapshot.currentCard;
        state.seed = snapshot.seed;
    }

    public void reset() {
        state.revision = 0;
        state.phase = GameState.Phase.LOBBY;
        state.players.clear();
        state.activePlayerIndex = 0;
        state.drawPile.clear();
        state.discardPile.clear();
        state.currentCard = null;
        state.seed = null;
    }

    private void requireTurn(String playerId) throws RuleException {
        require(state.activePlayer() != null && state.activePlayer().id.equals(playerId), Error.NOT_PLAYERS_TURN);
    }

    private static void require(boolean condition, Error error) throws RuleException {
        if (!condition) throw new RuleException(error);
    }
}
