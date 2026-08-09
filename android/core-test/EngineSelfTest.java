import com.jakkuazzo.cards.core.CardRecord;
import com.jakkuazzo.cards.core.BlePacketFramer;
import com.jakkuazzo.cards.core.GameState;
import com.jakkuazzo.cards.core.MultiplayerEngine;
import com.jakkuazzo.cards.core.SeededShuffle;
import com.jakkuazzo.cards.core.SharedArAlignment;
import com.jakkuazzo.cards.core.DominoesGame;
import com.jakkuazzo.cards.core.PokerHandEvaluator;
import com.jakkuazzo.cards.core.GameDraftParser;

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
        testDrawDominoes();
        testPokerHands();
        testCreatorDrafts();
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

    private static void testDrawDominoes() {
        DominoesGame dominoes = new DominoesGame();
        dominoes.startRound(2);
        require(dominoes.players() == 2, "dominoes player count");
        require(dominoes.hand(0).size() == 7 && dominoes.hand(1).size() == 7, "dominoes initial hands");
        require(dominoes.boneyardCount() == 14, "dominoes boneyard");
        int player = dominoes.activePlayer();
        DominoesGame.Tile opening = null;
        for (DominoesGame.Tile tile : dominoes.hand(player)) if (dominoes.canPlay(player, tile)) opening = tile;
        require(opening != null, "dominoes opening tile");
        require(dominoes.play(player, opening, false), "dominoes opening play");
        require(dominoes.train().size() == 1, "dominoes train updated");
        int next = dominoes.activePlayer();
        if (!dominoes.hasPlayable(next)) { require(!dominoes.pass(next), "dominoes cannot pass while boneyard has tiles"); require(dominoes.draw(next), "dominoes draw when blocked"); }

        DominoesGame fullRound = new DominoesGame();
        fullRound.startRound(2);
        int safety = 0;
        while (!fullRound.isFinished() && safety++ < 200) {
            int active = fullRound.activePlayer();
            DominoesGame.Tile legal = null;
            for (DominoesGame.Tile tile : fullRound.hand(active)) if (fullRound.canPlay(active, tile)) { legal = tile; break; }
            if (legal != null) require(fullRound.play(active, legal, false), "dominoes automated legal play");
            else if (fullRound.boneyardCount() > 0) require(fullRound.draw(active), "dominoes automated draw");
            else require(fullRound.pass(active), "dominoes automated pass");
        }
        require(fullRound.isFinished(), "dominoes round completes");
    }

    private static void testPokerHands() {
        List<String> community = Arrays.asList("10♥", "J♥", "Q♥", "K♥", "2♣");
        long straightFlush = PokerHandEvaluator.score(Arrays.asList("A♥", "3♦"), community);
        long fourOfAKind = PokerHandEvaluator.score(Arrays.asList("2♥", "2♦"), Arrays.asList("2♣", "2♠", "A♦", "K♣", "Q♣"));
        require(straightFlush > fourOfAKind, "poker hand ordering");
        require("straight flush".equals(PokerHandEvaluator.label(straightFlush)), "poker hand label");
    }

    private static void testCreatorDrafts() {
        GameDraftParser.Draft poker = GameDraftParser.parse("idea: Friday poker\nmax_user: 4\nar: n\ntabledesign: poker_2.png");
        require("poker".equals(poker.template) && poker.maximumPlayers == 4 && !poker.arEnabled, "poker draft should use bounded settings");
        GameDraftParser.Draft dominoes = GameDraftParser.parse("dominoes\nmax_users: 2");
        require("dominoes".equals(dominoes.template) && "domino-yard".equals(dominoes.tableDesign), "dominoes draft should use bundled template");
        try { GameDraftParser.parse("idea: mystery\nmax_user: 99"); throw new AssertionError("invalid creator draft should fail"); }
        catch (IllegalArgumentException expected) { }
    }

    private static void require(boolean condition, String name) {
        if (!condition) throw new AssertionError("Failed: " + name);
    }
}
