import XCTest
@testable import CardsiOS

@MainActor
final class MultiplayerEngineTests: XCTestCase {
    func testSeed42MatchesSharedShuffleFixture() throws {
        let shuffled = SeededShuffle.shuffle(GameManifest.tableTalk.deck.cards, seed: 42)

        XCTAssertEqual(shuffled.map(\.id), ["tt-04", "tt-02", "tt-07", "tt-03", "tt-05", "tt-01", "tt-08", "tt-06"])
    }

    func testHostRunsAnOrderedTwoPlayerTurn() throws {
        let engine = MultiplayerEngine()

        try engine.handle(.join(id: "host", name: "Host"))
        try engine.handle(.join(id: "guest", name: "Guest"))
        try engine.handle(.start(seed: 42))
        let reveal = try engine.handle(.draw(playerID: "host"))
        let advance = try engine.handle(.endTurn(playerID: "host"))

        XCTAssertEqual(reveal, .cardRevealed(cardID: "tt-04", playerID: "host"))
        XCTAssertEqual(advance, .turnAdvanced(playerID: "guest"))
        XCTAssertEqual(engine.state.revision, 5)
        XCTAssertEqual(engine.state.activePlayer?.id, "guest")
        XCTAssertEqual(engine.state.discardPile.map(\.id), ["tt-04"])
    }

    func testGuestCannotActDuringHostsTurn() throws {
        let engine = MultiplayerEngine()
        try engine.handle(.join(id: "host", name: "Host"))
        try engine.handle(.join(id: "guest", name: "Guest"))
        try engine.handle(.start(seed: 42))

        XCTAssertThrowsError(try engine.handle(.draw(playerID: "guest"))) { error in
            XCTAssertEqual(error as? MultiplayerRuleError, .notPlayersTurn)
        }
        XCTAssertEqual(engine.state.revision, 3)
    }

    func testManifestValidationRejectsDuplicateCards() {
        let card = GameManifest.Deck.Card(id: "same", text: "Duplicate")
        let manifest = GameManifest(
            schemaVersion: 1,
            id: "bad-game",
            name: "Bad",
            archetype: .promptDraw,
            summary: "",
            players: .init(minimum: 1, maximum: 2),
            capabilities: .init(multiplayer: true, nearby: true, ar: false),
            resources: .init(tableDesign: "green-classic", cardBack: "classic-red", cardSet: "prompt-basic"),
            deck: .init(kind: .prompts, cards: [card, card]),
            rules: .init(initialHandSize: 0, drawPerTurn: 1, playPerTurn: 0, turnOrder: .clockwise, winCondition: .deckEmpty),
            presentation: .init(accentStartHex: "000000", accentEndHex: "FFFFFF", supportsAR: false)
        )

        XCTAssertThrowsError(try manifest.validate()) { error in
            XCTAssertEqual(error as? GameManifest.ManifestError, .duplicateCardID)
        }
    }
}
