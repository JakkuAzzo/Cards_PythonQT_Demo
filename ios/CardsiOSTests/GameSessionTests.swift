import XCTest
@testable import CardsiOS

@MainActor
final class GameSessionTests: XCTestCase {
    func testClassicDeckContainsEveryCardOnce() {
        let deck = GameSession.makeDeck(for: makePack(mode: .classic))

        XCTAssertEqual(deck.count, 52)
        XCTAssertEqual(Set(deck.map(\.id)).count, 52)
    }

    func testPromptDeckUsesPackPrompts() {
        let pack = makePack(mode: .prompts, prompts: ["One", "Two", "Three"])
        let session = GameSession(pack: pack, shuffle: false)

        XCTAssertEqual(session.cardsDrawn, 1)
        XCTAssertEqual(session.cardsRemaining, 2)
        XCTAssertEqual(session.currentCard?.content, .prompt("One"))
    }

    func testDrawingCompletesDeckWithoutRepeatingCards() {
        let session = GameSession(pack: makePack(mode: .prompts, prompts: ["One", "Two"]), shuffle: false)

        XCTAssertFalse(session.isComplete)
        XCTAssertEqual(session.draw()?.content, .prompt("Two"))
        XCTAssertTrue(session.isComplete)
        XCTAssertNil(session.draw())
    }

    private func makePack(mode: PackRecord.PlayMode, prompts: [String]? = nil) -> PackRecord {
        PackRecord(
            id: "test",
            name: "Test",
            summary: "Test pack",
            status: "Included",
            badge: "Test",
            accentStartHex: "000000",
            accentEndHex: "FFFFFF",
            featured: false,
            config: [:],
            playMode: mode,
            prompts: prompts
        )
    }
}
