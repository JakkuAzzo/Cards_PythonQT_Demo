import XCTest
@testable import CardsiOS

final class GameDraftInterpreterTests: XCTestCase {
    func testBuildsValidatedManifestFromConstrainedDescription() throws {
        let draft = try GameDraftInterpreter().interpret("""
        Name: Tiny Test
        Summary: A small game.
        Players: 2-4
        - First card
        - Second card
        """)

        XCTAssertEqual(draft.id, "tiny-test")
        XCTAssertEqual(draft.archetype, .promptDraw)
        XCTAssertEqual(draft.players, .init(minimum: 2, maximum: 4))
        XCTAssertEqual(draft.deck.cards.map(\.text), ["First card", "Second card"])
        XCTAssertNoThrow(try draft.validate())
    }

    func testPokerIdeaSelectsPokerDefaultsAndAppliesOverrides() throws {
        let draft = try GameDraftInterpreter().interpret("""
        idea: four-player poker night
        multiplayer: y
        max_user: 4
        ar: n
        tabledesign: poker_2.png
        """)

        XCTAssertEqual(draft.archetype, .poker)
        XCTAssertEqual(draft.players, .init(minimum: 2, maximum: 4))
        XCTAssertEqual(draft.resources.tableDesign, "poker-2")
        XCTAssertEqual(draft.resources.cardSet, "classic-pack-52")
        XCTAssertEqual(draft.resources.cardBack, "classic-pack-red")
        XCTAssertEqual(draft.rules.initialHandSize, 2)
        XCTAssertFalse(draft.capabilities.ar)
    }

    func testGuessWhoSelectsCharacterGridTemplate() throws {
        let draft = try GameDraftInterpreter().interpret("idea: a nearby Guess Who game")

        XCTAssertEqual(draft.archetype, .guessWho)
        XCTAssertEqual(draft.players, .init(minimum: 2, maximum: 2))
        XCTAssertEqual(draft.deck.kind, .characters)
        XCTAssertEqual(draft.resources.cardSet, "classic-characters")
        XCTAssertEqual(draft.deck.cards.count, 12)
    }

    func testRejectsDescriptionsWithoutEnoughCards() {
        XCTAssertThrowsError(try GameDraftInterpreter().interpret("Name: Empty\nPlayers: 2-4")) { error in
            XCTAssertEqual(error as? GameDraftInterpreter.DraftError, .notEnoughCards)
        }
    }

    func testRejectsUnsafePlayerRange() {
        XCTAssertThrowsError(try GameDraftInterpreter().interpret("Name: Huge\nPlayers: 2-99\n- One\n- Two")) { error in
            XCTAssertEqual(error as? GameDraftInterpreter.DraftError, .invalidPlayerRange)
        }
    }

    @MainActor
    func testPackStorePersistsAndRemovesSavedDraftsLocally() {
        let suiteName = "CardsiOSTests.saved-drafts"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = PackStore(defaults: defaults)

        store.saveDraft(.dominoes)
        XCTAssertEqual(store.savedDrafts.map(\.id), ["double-six-dominoes"])

        let restored = PackStore(defaults: defaults)
        XCTAssertEqual(restored.savedDrafts.map(\.id), ["double-six-dominoes"])
        restored.removeDraft(.dominoes)
        XCTAssertTrue(restored.savedDrafts.isEmpty)
        defaults.removePersistentDomain(forName: suiteName)
    }
}
