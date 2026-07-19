import com.jakkuazzo.cards.core.CardRecord;
import com.jakkuazzo.cards.core.BlePacketFramer;
import com.jakkuazzo.cards.core.GameState;
import com.jakkuazzo.cards.core.MultiplayerEngine;
import com.jakkuazzo.cards.core.SeededShuffle;
import com.jakkuazzo.cards.core.SharedArAlignment;

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

        GameState hostSnapshot = engine.state();
        MultiplayerEngine guest = new MultiplayerEngine();
        guest.applyHostSnapshot(hostSnapshot);
        require(guest.state().revision == hostSnapshot.revision, "guest snapshot revision");
        require(guest.state().activePlayer().id.equals("guest"), "guest snapshot player");

        GameState stale = new GameState();
        stale.revision = 1;
        guest.applyHostSnapshot(stale);
        require(guest.state().revision == hostSnapshot.revision, "stale snapshot rejection");

        guest.reset();
        require(guest.state().phase == GameState.Phase.LOBBY && guest.state().players.isEmpty(), "engine reset");
        testBleFraming();
        testSharedAlignment();
        System.out.println("Android core conformance tests passed.");
    }

    private static void testBleFraming() {
        byte[] first = "first-envelope".getBytes(java.nio.charset.StandardCharsets.UTF_8);
        byte[] second = new byte[400];
        Arrays.fill(second, (byte) 0x42);
        BlePacketFramer receiver = new BlePacketFramer();
        java.util.List<byte[]> decoded = new java.util.ArrayList<>();
        for (byte[] packet : BlePacketFramer.packets(first)) decoded.addAll(receiver.append(packet));
        for (byte[] packet : BlePacketFramer.packets(second)) decoded.addAll(receiver.append(packet));
        require(decoded.size() == 2, "BLE framing count");
        require(Arrays.equals(decoded.get(0), first), "BLE first envelope");
        require(Arrays.equals(decoded.get(1), second), "BLE second envelope");
    }

    private static void testSharedAlignment() {
        SharedArAlignment valid = new SharedArAlignment(SharedArAlignment.MARKER_ID, 0.16, 2, "ready");
        SharedArAlignment invalid = new SharedArAlignment("other", 0.16, 2, "ready");
        require(valid.isValid(), "shared marker valid");
        require(!invalid.isValid(), "shared marker rejected");
    }

    private static void require(boolean condition, String name) {
        if (!condition) throw new AssertionError("Failed: " + name);
    }
}
