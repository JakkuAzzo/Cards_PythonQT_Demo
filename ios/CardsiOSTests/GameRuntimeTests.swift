import XCTest
@testable import CardsiOS

@MainActor
final class GameRuntimeTests: XCTestCase {
    func testPokerScoresStraightFlushAboveFourOfAKind() {
        let straightFlush = cards([(.ten, .hearts), (.jack, .hearts), (.queen, .hearts), (.king, .hearts), (.ace, .hearts)])
        let fourOfAKind = cards([(.ace, .hearts), (.ace, .diamonds), (.ace, .clubs), (.ace, .spades), (.king, .hearts)])

        XCTAssertGreaterThan(PokerGame.score(straightFlush), PokerGame.score(fourOfAKind))
        XCTAssertEqual(PokerGame.score(straightFlush).label, "Straight flush")
    }

    func testPokerDealsPrivateHandsAndFiveCommunityCards() {
        let game = PokerGame(playerNames: ["Avery", "Jordan"])

        XCTAssertEqual(game.players.map(\.hand.count), [2, 2])
        game.advanceStreet()
        game.advanceStreet()
        game.advanceStreet()
        XCTAssertEqual(game.communityCards.count, 5)
        XCTAssertEqual(game.street, .river)
    }

    func testGuessWhoCorrectGuessAssignsWinner() {
        let game = GuessWhoGame(playerNames: ["Avery", "Jordan"])
        guard let target = game.targets[game.opponentName] else {
            return XCTFail("Expected a target for the opponent")
        }

        game.guess(target)

        XCTAssertEqual(game.winnerName, "Avery")
    }

    func testGuessWhoEliminationCanBeToggled() {
        let game = GuessWhoGame(playerNames: ["Avery", "Jordan"])
        let character = game.characters[0]

        game.toggleElimination(character)
        XCTAssertTrue(game.eliminated.contains(character.id))
        game.toggleElimination(character)
        XCTAssertFalse(game.eliminated.contains(character.id))
    }

    private func cards(_ values: [(PlayingCard.Rank, PlayingCard.Suit)]) -> [PlayingCard] {
        values.map { PlayingCard(suit: $0.1, rank: $0.0) }
    }
}
