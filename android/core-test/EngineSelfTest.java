import com.jakkuazzo.cards.core.CardRecord;
import com.jakkuazzo.cards.core.GameState;
import com.jakkuazzo.cards.core.MultiplayerEngine;
import com.jakkuazzo.cards.core.SeededShuffle;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

public final class EngineSelfTest {
    public static void main(String[] args) throws Exception {
        MultiplayerEngine engine = new MultiplayerEngine();
        List<String> shuffled = SeededShuffle.shuffle(engine.sourceDeck(), 42L).stream().map(card -> card.id).collect(Collectors.toList());
        require(shuffled.equals(Arrays.asList("tt-04", "tt-02", "tt-07", "tt-03", "tt-05", "tt-01", "tt-08", "tt-06")), "shuffle fixture");

        engine.join("host", "Host");
        engine.join("guest", "Guest");
        engine.start(42L);
        CardRecord first = engine.draw("host");
        require(first.id.equals("tt-04"), "first card");
        engine.endTurn("host");
        require(engine.state().activePlayer().id.equals("guest"), "turn advancement");
        require(engine.state().revision == 5, "revision count");
        require(engine.state().phase == GameState.Phase.WAITING_FOR_DRAW, "phase");

        boolean rejected = false;
        try {
            engine.draw("host");
        } catch (MultiplayerEngine.RuleException error) {
            rejected = error.error == MultiplayerEngine.Error.NOT_PLAYERS_TURN;
        }
        require(rejected, "out-of-turn command rejection");
        System.out.println("Android core conformance tests passed.");
    }

    private static void require(boolean condition, String name) {
        if (!condition) throw new AssertionError("Failed: " + name);
    }
}
