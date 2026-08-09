import Foundation
import Combine

/// Purpose: local, deterministic state models for the supported game rooms.
///
/// Responsibilities: Poker, Guess Who, and Dominoes rules, turn progression,
/// public snapshots, and deterministic solo-AI decisions. SwiftUI views render
/// these models but must not duplicate their rule decisions. Network adapters
/// serialize only their public data plus recipient-only private state.
///
/// Constraint: a gameplay-rule change here normally needs matching Android
/// behaviour and conformance/regression tests; AR remains a presentation layer.
@MainActor
final class PokerGame: ObservableObject {
    enum Street: String, CaseIterable, Codable {
        case preflop = "Pre-flop"
        case flop = "Flop"
        case turn = "Turn"
        case river = "River"
        case showdown = "Showdown"

        var nextLabel: String {
            switch self {
            case .preflop: return "Reveal flop"
            case .flop: return "Reveal turn"
            case .turn: return "Reveal river"
            case .river: return "Show hands"
            case .showdown: return "New hand"
            }
        }
    }

    struct Player: Identifiable, Equatable {
        let id: UUID
        let name: String
        var hand: [PlayingCard]
        var chips: Int
        var folded = false
    }

    struct HandScore: Comparable, Equatable {
        let category: Int
        let values: [Int]

        static func < (lhs: HandScore, rhs: HandScore) -> Bool {
            if lhs.category != rhs.category { return lhs.category < rhs.category }
            for (left, right) in zip(lhs.values, rhs.values) where left != right {
                return left < right
            }
            return lhs.values.count < rhs.values.count
        }

        var label: String {
            ["High card", "Pair", "Two pair", "Three of a kind", "Straight", "Flush", "Full house", "Four of a kind", "Straight flush"][category]
        }
    }

    @Published private(set) var players: [Player]
    @Published private(set) var communityCards: [PlayingCard] = []
    @Published private(set) var street: Street = .preflop
    @Published private(set) var pot = 0
    @Published private(set) var dealerIndex = 0
    @Published private(set) var actionMessage = "Deal a hand to begin."

    private var deck: [PlayingCard] = []
    private var winnerIndexes: [Int] = []

    struct PublicSnapshot: Codable, Equatable {
        struct PlayerState: Codable, Equatable { let chips: Int; let folded: Bool }
        let street: Street
        let communityCards: [PlayingCard]
        let pot: Int
        let dealerIndex: Int
        let players: [PlayerState]
        let winnerIndexes: [Int]
        let actionMessage: String
    }

    init(playerNames: [String]) {
        players = playerNames.prefix(8).map { Player(id: UUID(), name: $0, hand: [], chips: 1_000) }
        deal()
    }

    var winner: Player? {
        winners.first
    }

    var winners: [Player] { winnerIndexes.compactMap { players.indices.contains($0) ? players[$0] : nil } }

    var activePlayers: [Player] { players.filter { !$0.folded } }

    func deal() {
        deck = Self.standardDeck().shuffled()
        communityCards = []
        street = .preflop
        pot = 0
        winnerIndexes = []
        players.indices.forEach { index in
            players[index].hand = [drawCard(), drawCard()]
            players[index].folded = false
        }
        actionMessage = "Private hands dealt. Choose a table action, then reveal the flop."
    }

    func advanceStreet() {
        switch street {
        case .preflop:
            communityCards = [drawCard(), drawCard(), drawCard()]
            street = .flop
            actionMessage = "The flop is on the table."
        case .flop:
            communityCards.append(drawCard())
            street = .turn
            actionMessage = "The turn card is on the table."
        case .turn:
            communityCards.append(drawCard())
            street = .river
            actionMessage = "The river card is on the table."
        case .river:
            street = .showdown
            settlePot(with: showdownWinnerIndexes())
        case .showdown:
            dealerIndex = (dealerIndex + 1) % max(players.count, 1)
            deal()
        }
    }

    func placeBet(for playerID: UUID, amount: Int = 20) {
        guard street != .showdown,
              let index = players.firstIndex(where: { $0.id == playerID }),
              !players[index].folded else { return }
        let wager = min(amount, players[index].chips)
        guard wager > 0 else { return }
        players[index].chips -= wager
        pot += wager
        actionMessage = "\(players[index].name) adds \(wager) chips to the pot."
    }

    func fold(playerID: UUID) {
        guard street != .showdown,
              let index = players.firstIndex(where: { $0.id == playerID }),
              !players[index].folded else { return }
        players[index].folded = true
        if activePlayers.count == 1, let winner = activePlayers.first {
            street = .showdown
            guard let winnerIndex = players.firstIndex(where: { $0.id == winner.id }) else { return }
            settlePot(with: [winnerIndex], description: "\(winner.name) takes the pot after the fold.")
        } else {
            actionMessage = "\(players[index].name) folded."
        }
    }

    func publicSnapshot() -> PublicSnapshot {
        PublicSnapshot(street: street, communityCards: communityCards, pot: pot, dealerIndex: dealerIndex, players: players.map { .init(chips: $0.chips, folded: $0.folded) }, winnerIndexes: winnerIndexes, actionMessage: actionMessage)
    }

    func apply(publicSnapshot: PublicSnapshot) {
        guard publicSnapshot.players.count == players.count else { return }
        street = publicSnapshot.street
        communityCards = publicSnapshot.communityCards
        pot = publicSnapshot.pot
        dealerIndex = min(max(publicSnapshot.dealerIndex, 0), max(players.count - 1, 0))
        winnerIndexes = publicSnapshot.winnerIndexes.filter { players.indices.contains($0) }
        actionMessage = publicSnapshot.actionMessage
        for index in players.indices {
            players[index].chips = publicSnapshot.players[index].chips
            players[index].folded = publicSnapshot.players[index].folded
        }
    }

    func applyPrivateHand(_ hand: [PlayingCard]) {
        guard !players.isEmpty, hand.count == 2 else { return }
        players[0].hand = hand
    }

    func score(for player: Player) -> HandScore {
        let cards = player.hand + communityCards
        guard cards.count >= 5 else { return HandScore(category: 0, values: []) }
        return Self.combinations(of: cards, choose: 5)
            .map(Self.score)
            .max() ?? HandScore(category: 0, values: [])
    }

    private func showdownWinnerIndexes() -> [Int] {
        let eligible = players.indices.filter { !players[$0].folded }
        guard let best = eligible.map({ score(for: players[$0]) }).max() else { return [] }
        return eligible.filter { score(for: players[$0]) == best }
    }

    private func settlePot(with indexes: [Int], description: String? = nil) {
        guard !indexes.isEmpty else { return }
        winnerIndexes = indexes
        let total = pot
        let share = total / indexes.count
        var remainder = total % indexes.count
        for index in indexes {
            players[index].chips += share + (remainder > 0 ? 1 : 0)
            if remainder > 0 { remainder -= 1 }
        }
        pot = 0
        if let description {
            actionMessage = description
        } else {
            let names = indexes.map { players[$0].name }.joined(separator: ", ")
            let hand = score(for: players[indexes[0]]).label.lowercased()
            actionMessage = indexes.count == 1
                ? "\(names) wins \(total) chips with \(hand)."
                : "\(names) split \(total) chips with \(hand)."
        }
    }

    static func score(_ cards: [PlayingCard]) -> HandScore {
        let values = cards.map { rankValue($0.rank) }.sorted(by: >)
        var counts: [Int: Int] = [:]
        for value in values { counts[value, default: 0] += 1 }
        let grouped = counts.map { (value: $0.key, count: $0.value) }
            .sorted { left, right in
                if left.count == right.count { return left.value > right.value }
                return left.count > right.count
            }
        let flush = Set(cards.map(\.suit)).count == 1
        let distinct = Array(Set(values)).sorted(by: >)
        let straightHigh: Int? = {
            guard distinct.count == 5 else { return nil }
            if distinct == [14, 5, 4, 3, 2] { return 5 }
            return distinct[0] - distinct[4] == 4 ? distinct[0] : nil
        }()
        if flush, let high = straightHigh { return HandScore(category: 8, values: [high]) }
        if grouped[0].count == 4 { return HandScore(category: 7, values: [grouped[0].value, grouped[1].value]) }
        if grouped[0].count == 3, grouped[1].count == 2 { return HandScore(category: 6, values: [grouped[0].value, grouped[1].value]) }
        if flush { return HandScore(category: 5, values: values) }
        if let high = straightHigh { return HandScore(category: 4, values: [high]) }
        if grouped[0].count == 3 { return HandScore(category: 3, values: [grouped[0].value] + values.filter { $0 != grouped[0].value }) }
        if grouped[0].count == 2, grouped[1].count == 2 { return HandScore(category: 2, values: [grouped[0].value, grouped[1].value, grouped[2].value]) }
        if grouped[0].count == 2 { return HandScore(category: 1, values: [grouped[0].value] + values.filter { $0 != grouped[0].value }) }
        return HandScore(category: 0, values: values)
    }

    private func drawCard() -> PlayingCard { deck.removeFirst() }

    private static func standardDeck() -> [PlayingCard] {
        PlayingCard.Suit.allCases.flatMap { suit in PlayingCard.Rank.allCases.map { PlayingCard(suit: suit, rank: $0) } }
    }

    private static func rankValue(_ rank: PlayingCard.Rank) -> Int {
        switch rank {
        case .ace: return 14; case .king: return 13; case .queen: return 12; case .jack: return 11; case .ten: return 10
        case .nine: return 9; case .eight: return 8; case .seven: return 7; case .six: return 6; case .five: return 5
        case .four: return 4; case .three: return 3; case .two: return 2
        }
    }

    private static func combinations<T>(of values: [T], choose count: Int) -> [[T]] {
        guard count > 0 else { return [[]] }
        guard values.count >= count else { return [] }
        if count == 1 { return values.map { [$0] } }
        if count == values.count { return [values] }
        return values.indices.flatMap { index -> [[T]] in
            guard values.count - index >= count else { return [] }
            return combinations(of: Array(values[(index + 1)...]), choose: count - 1).map { [values[index]] + $0 }
        }
    }
}

@MainActor
final class GuessWhoGame: ObservableObject {
    struct Character: Identifiable, Equatable {
        let id: String
        let name: String
    }

    @Published private(set) var characters: [Character]
    @Published private(set) var eliminated: Set<String> = []
    @Published private(set) var targets: [String: Character] = [:]
    @Published private(set) var activePlayerIndex = 0
    @Published private(set) var winnerName: String?
    @Published private(set) var message = "Ask a yes-or-no question, then eliminate possibilities."

    let players: [String]

    init(playerNames: [String], names: [String] = ["Alex", "Blair", "Casey", "Drew", "Emery", "Frankie", "Gray", "Harper", "Indigo", "Jules", "Kai", "Lane"]) {
        players = Array(playerNames.prefix(2))
        characters = names.enumerated().map { Character(id: "character-\($0.offset + 1)", name: $0.element) }
        assignTargets()
    }

    var activePlayer: String { players[activePlayerIndex] }

    func toggleElimination(_ character: Character) {
        guard winnerName == nil else { return }
        if eliminated.contains(character.id) { eliminated.remove(character.id) } else { eliminated.insert(character.id) }
        message = "\(character.name) is \(eliminated.contains(character.id) ? "eliminated" : "back in play")."
    }

    func askQuestion() {
        guard winnerName == nil else { return }
        message = "Question asked. Pass the device to \(opponentName)."
        activePlayerIndex = (activePlayerIndex + 1) % players.count
    }

    func guess(_ character: Character) {
        guard winnerName == nil else { return }
        let target = targets[opponentName]
        if target == character {
            winnerName = activePlayer
            message = "\(activePlayer) guessed \(character.name) correctly."
        } else {
            message = "Not \(character.name). \(opponentName) gets the next question."
            activePlayerIndex = (activePlayerIndex + 1) % players.count
        }
    }

    func restart() {
        eliminated = []
        winnerName = nil
        activePlayerIndex = 0
        assignTargets()
        message = "New targets assigned. \(activePlayer) asks first."
    }

    var opponentName: String { players[(activePlayerIndex + 1) % players.count] }

    private func assignTargets() {
        let shuffled = characters.shuffled()
        for (index, player) in players.enumerated() { targets[player] = shuffled[index] }
    }

    struct PublicSnapshot: Codable, Equatable {
        let eliminated: Set<String>
        let activePlayerIndex: Int
        let winnerName: String?
        let message: String
    }

    func publicSnapshot() -> PublicSnapshot {
        PublicSnapshot(eliminated: eliminated, activePlayerIndex: activePlayerIndex, winnerName: winnerName, message: message)
    }

    func apply(publicSnapshot: PublicSnapshot) {
        guard players.indices.contains(publicSnapshot.activePlayerIndex) else { return }
        eliminated = publicSnapshot.eliminated
        activePlayerIndex = publicSnapshot.activePlayerIndex
        winnerName = publicSnapshot.winnerName
        message = publicSnapshot.message
    }

    func applyPrivateTarget(id: String) {
        guard let character = characters.first(where: { $0.id == id }), let localName = players.first else { return }
        targets[localName] = character
    }

    static let defaultNames = ["Alex", "Blair", "Casey", "Drew", "Emery", "Frankie", "Gray", "Harper", "Indigo", "Jules", "Kai", "Lane"]
}

@MainActor
final class DominoesGame: ObservableObject {
    struct Tile: Identifiable, Equatable {
        let left: Int
        let right: Int

        var id: String { "domino-\(min(left, right))-\(max(left, right))" }
        var pips: Int { left + right }
        func matches(_ value: Int) -> Bool { left == value || right == value }
    }

    enum End: String, CaseIterable, Identifiable { case left, right; var id: String { rawValue } }

    struct PlacedTile: Identifiable, Equatable {
        let id = UUID()
        let tile: Tile
        let exposedLeft: Int
        let exposedRight: Int
    }

    @Published private(set) var players: [String]
    @Published private(set) var hands: [[Tile]]
    @Published private(set) var boneyard: [Tile] = []
    @Published private(set) var table: [PlacedTile] = []
    @Published private(set) var activePlayerIndex = 0
    @Published private(set) var winnerName: String?
    @Published private(set) var scores: [String: Int] = [:]
    @Published private(set) var message = "Deal the tiles, then play from either end of the table."
    private var consecutivePasses = 0
    private let deckOrder: [Tile]?

    /// `deckOrder` provides deterministic local/test rounds. Production passes
    /// nil and receives a freshly shuffled double-six set.
    init(playerNames: [String], deckOrder: [Tile]? = nil) {
        let names = Array(playerNames.prefix(4))
        precondition(names.count >= 2, "Dominoes needs at least two players.")
        if let deckOrder { precondition(deckOrder.count >= names.count * 7, "Dominoes deck must deal seven tiles to every player.") }
        players = names
        hands = Array(repeating: [], count: names.count)
        self.deckOrder = deckOrder
        restart()
    }

    var activePlayer: String { players[activePlayerIndex] }
    var leftEnd: Int? { table.first?.exposedLeft }
    var rightEnd: Int? { table.last?.exposedRight }
    var isFinished: Bool { winnerName != nil }
    var activeScore: Int { scores[activePlayer, default: 0] }

    func hand(for player: String) -> [Tile] {
        guard let index = players.firstIndex(of: player) else { return [] }
        return hands[index]
    }

    func playableTiles(for player: String) -> [Tile] {
        let hand = hand(for: player)
        guard let leftEnd, let rightEnd else {
            guard player == activePlayer else { return [] }
            return hand.filter { $0.id == openingTileID }
        }
        return hand.filter { $0.matches(leftEnd) || $0.matches(rightEnd) }
    }

    func play(_ tile: Tile, on end: End) {
        guard !isFinished,
              let playerIndex = players.firstIndex(of: activePlayer),
              hands[playerIndex].contains(tile) else { return }

        if table.isEmpty, tile.id == openingTileID {
            table = [.init(tile: tile, exposedLeft: tile.left, exposedRight: tile.right)]
        } else if table.isEmpty {
            message = "Open with the highest double in the active hand."
            return
        } else if end == .left, let target = leftEnd, tile.matches(target) {
            let outer = tile.left == target ? tile.right : tile.left
            table.insert(.init(tile: tile, exposedLeft: outer, exposedRight: target), at: 0)
        } else if end == .right, let target = rightEnd, tile.matches(target) {
            let outer = tile.left == target ? tile.right : tile.left
            table.append(.init(tile: tile, exposedLeft: target, exposedRight: outer))
        } else {
            message = "That tile does not match the \(end.rawValue) end."
            return
        }

        hands[playerIndex].removeAll { $0 == tile }
        consecutivePasses = 0
        if hands[playerIndex].isEmpty {
            winnerName = activePlayer
            let awarded = hands.enumerated().filter { $0.offset != playerIndex }.flatMap(\.element).reduce(0) { $0 + $1.pips }
            scores[activePlayer, default: 0] += awarded
            message = "\(activePlayer) played every tile and scores \(awarded) points."
        } else {
            message = "\(activePlayer) played \(tile.left)|\(tile.right)."
            advanceTurn()
        }
    }

    func drawOrPass() {
        guard !isFinished else { return }
        guard playableTiles(for: activePlayer).isEmpty else { message = "A legal tile is available; place it instead of drawing."; return }
        while !boneyard.isEmpty, playableTiles(for: activePlayer).isEmpty { hands[activePlayerIndex].append(boneyard.removeFirst()) }
        if playableTiles(for: activePlayer).isEmpty {
            consecutivePasses += 1
            if consecutivePasses >= players.count {
                finishBlockedRound()
            } else {
                message = "No legal tile remains. \(activePlayer) passes."
                advanceTurn()
            }
        }
        else { message = "\(activePlayer) drew until a legal tile was available." }
    }

    func restart() {
        var deck = deckOrder ?? Self.doubleSixSet().shuffled()
        hands = []
        for _ in players {
            hands.append(Array(deck.prefix(7)))
            deck.removeFirst(min(7, deck.count))
        }
        boneyard = deck
        table = []
        winnerName = nil
        consecutivePasses = 0
        scores = Dictionary(uniqueKeysWithValues: players.map { ($0, scores[$0, default: 0]) })
        activePlayerIndex = openingPlayerIndex()
        message = "\(activePlayer) starts with \(openingTileID.replacingOccurrences(of: "domino-", with: "").replacingOccurrences(of: "-", with: "|"))."
    }

    private func advanceTurn() {
        activePlayerIndex = (activePlayerIndex + 1) % players.count
        message += " \(activePlayer)’s turn."
    }

    private func finishBlockedRound() {
        guard let winnerIndex = hands.indices.min(by: { handPips(at: $0) < handPips(at: $1) }) else { return }
        let winner = players[winnerIndex]
        let awarded = hands.indices.filter { $0 != winnerIndex }.reduce(0) { total, index in total + handPips(at: index) }
        scores[winner, default: 0] += awarded
        activePlayerIndex = winnerIndex
        winnerName = winner
        message = "Blocked round. \(winner) has the lowest hand and scores \(awarded) points."
    }

    private func handPips(at index: Int) -> Int { hands[index].reduce(0) { $0 + $1.pips } }

    private var openingTileID: String {
        for value in stride(from: 6, through: 0, by: -1) {
            if let tile = hands[activePlayerIndex].first(where: { $0.left == value && $0.right == value }) { return tile.id }
        }
        return hands[activePlayerIndex].first?.id ?? ""
    }

    private func openingPlayerIndex() -> Int {
        for value in stride(from: 6, through: 0, by: -1) {
            if let index = hands.indices.first(where: { hands[$0].contains(where: { $0.left == value && $0.right == value }) }) { return index }
        }
        return 0
    }

    static func doubleSixSet() -> [Tile] {
        (0...6).flatMap { left in (left...6).map { Tile(left: left, right: $0) } }
    }
}
