package com.jakkuazzo.cards.nearby;

import com.jakkuazzo.cards.core.CardRecord;
import com.jakkuazzo.cards.core.GameState;
import com.jakkuazzo.cards.core.Player;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/** Public Table Talk state only; private hands are intentionally not represented here. */
public final class GameSnapshotCodec {
    private GameSnapshotCodec() { }

    public static JSONObject encode(GameState state) throws JSONException {
        JSONObject json = new JSONObject();
        json.put("revision", state.revision);
        json.put("phase", state.phase.name());
        json.put("activePlayerIndex", state.activePlayerIndex);
        json.put("seed", state.seed == null ? JSONObject.NULL : state.seed);
        json.put("players", players(state.players));
        json.put("drawPile", cards(state.drawPile));
        json.put("discardPile", cards(state.discardPile));
        json.put("currentCard", state.currentCard == null ? JSONObject.NULL : card(state.currentCard));
        return json;
    }

    public static GameState decode(JSONObject json) throws JSONException {
        GameState state = new GameState();
        state.revision = json.getInt("revision");
        state.phase = GameState.Phase.valueOf(json.getString("phase"));
        state.activePlayerIndex = json.getInt("activePlayerIndex");
        state.seed = json.isNull("seed") ? null : json.getLong("seed");
        readPlayers(json.getJSONArray("players"), state.players);
        readCards(json.getJSONArray("drawPile"), state.drawPile);
        readCards(json.getJSONArray("discardPile"), state.discardPile);
        state.currentCard = json.isNull("currentCard") ? null : readCard(json.getJSONObject("currentCard"));
        if (state.players.isEmpty() || state.activePlayerIndex < 0 || state.activePlayerIndex >= state.players.size()) {
            throw new JSONException("Invalid active player");
        }
        return state;
    }

    private static JSONArray players(java.util.List<Player> players) throws JSONException {
        JSONArray array = new JSONArray();
        for (Player player : players) {
            JSONObject json = new JSONObject();
            json.put("id", player.id);
            json.put("name", player.name);
            json.put("host", player.host);
            array.put(json);
        }
        return array;
    }

    private static JSONArray cards(java.util.List<CardRecord> cards) throws JSONException {
        JSONArray array = new JSONArray();
        for (CardRecord card : cards) array.put(card(card));
        return array;
    }

    private static JSONObject card(CardRecord card) throws JSONException {
        return new JSONObject().put("id", card.id).put("text", card.text);
    }

    private static void readPlayers(JSONArray source, java.util.List<Player> destination) throws JSONException {
        for (int index = 0; index < source.length(); index++) {
            JSONObject json = source.getJSONObject(index);
            destination.add(new Player(json.getString("id"), json.getString("name"), json.getBoolean("host")));
        }
    }

    private static void readCards(JSONArray source, java.util.List<CardRecord> destination) throws JSONException {
        for (int index = 0; index < source.length(); index++) destination.add(readCard(source.getJSONObject(index)));
    }

    private static CardRecord readCard(JSONObject json) throws JSONException {
        return new CardRecord(json.getString("id"), json.getString("text"));
    }
}
