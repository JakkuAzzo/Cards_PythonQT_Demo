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

    func testPokerShowdownAwardsPotAndPreservesTotalChips() {
        let game = PokerGame(playerNames: ["Avery", "Jordan"])
        let startingChips = game.players.reduce(0) { $0 + $1.chips }
        for player in game.players { game.placeBet(for: player.id, amount: 40) }

        game.advanceStreet()
        game.advanceStreet()
        game.advanceStreet()
        game.advanceStreet()

        XCTAssertEqual(game.street, .showdown)
        XCTAssertEqual(game.pot, 0)
        XCTAssertFalse(game.winners.isEmpty)
        XCTAssertEqual(game.players.reduce(0) { $0 + $1.chips }, startingChips)
    }

    func testPokerFoldAwardsPotToRemainingPlayer() {
        let game = PokerGame(playerNames: ["Avery", "Jordan"])
        let winnerID = game.players[0].id
        game.placeBet(for: winnerID, amount: 30)
        game.placeBet(for: game.players[1].id, amount: 30)
        game.fold(playerID: game.players[1].id)

        XCTAssertEqual(game.street, .showdown)
        XCTAssertEqual(game.pot, 0)
        XCTAssertEqual(game.winner?.id, winnerID)
        XCTAssertEqual(game.players[0].chips, 1_030)
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

    func testDominoesDealsSevenTilesToEachOfTwoPlayers() {
        let game = DominoesGame(playerNames: ["Avery", "Jordan"])

        XCTAssertEqual(game.hand(for: "Avery").count, 7)
        XCTAssertEqual(game.hand(for: "Jordan").count, 7)
        XCTAssertEqual(game.boneyard.count, 14)
        XCTAssertEqual(GameManifest.dominoes.players.minimum, 2)
    }

    func testDominoesPlacesOpeningTileAndAdvancesTurn() {
        let game = DominoesGame(playerNames: ["Avery", "Jordan"])
        let opener = game.activePlayer
        let openingTile = game.playableTiles(for: opener)[0]

        game.play(openingTile, on: .left)

        XCTAssertEqual(game.table.count, 1)
        XCTAssertEqual(game.hand(for: opener).count, 6)
        XCTAssertNotEqual(game.activePlayer, opener)
    }

    func testDominoesDrawOrPassNeverChangesFinishedRound() {
        let deck: [DominoesGame.Tile] = [
            .init(left: 6, right: 6), .init(left: 0, right: 0), .init(left: 0, right: 1), .init(left: 0, right: 2), .init(left: 0, right: 3), .init(left: 0, right: 4), .init(left: 0, right: 5),
            .init(left: 1, right: 1), .init(left: 1, right: 2), .init(left: 1, right: 3), .init(left: 1, right: 4), .init(left: 1, right: 5), .init(left: 2, right: 2), .init(left: 2, right: 3)
        ]
        let game = DominoesGame(playerNames: ["Avery", "Jordan"], deckOrder: deck)
        let openingTile = game.playableTiles(for: game.activePlayer)[0]
        game.play(openingTile, on: .left)

        game.drawOrPass()
        game.drawOrPass()

        XCTAssertTrue(game.isFinished)
        let winner = game.winnerName
        game.drawOrPass()
        XCTAssertEqual(game.winnerName, winner)
    }

    private func cards(_ values: [(PlayingCard.Rank, PlayingCard.Suit)]) -> [PlayingCard] {
        values.map { PlayingCard(suit: $0.1, rank: $0.0) }
    }
}
