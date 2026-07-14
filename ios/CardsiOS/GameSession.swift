import Foundation

@MainActor
final class GameSession: ObservableObject {
    let pack: PackRecord

    @Published private(set) var currentCard: SessionCard?
    @Published private(set) var cardsRemaining = 0
    @Published private(set) var cardsDrawn = 0

    private var deck: [SessionCard] = []

    init(pack: PackRecord, shuffle: Bool = true) {
        self.pack = pack
        restart(shuffle: shuffle)
    }

    var totalCards: Int { deck.count + cardsDrawn }
    var isComplete: Bool { currentCard != nil && cardsRemaining == 0 }

    @discardableResult
    func draw() -> SessionCard? {
        guard !deck.isEmpty else { return nil }
        currentCard = deck.removeFirst()
        cardsDrawn += 1
        cardsRemaining = deck.count
        return currentCard
    }

    func restart(shuffle: Bool = true) {
        deck = Self.makeDeck(for: pack)
        if shuffle {
            deck.shuffle()
        }
        currentCard = nil
        cardsDrawn = 0
        cardsRemaining = deck.count
        _ = draw()
    }

    static func makeDeck(for pack: PackRecord) -> [SessionCard] {
        if pack.resolvedPlayMode == .prompts, let prompts = pack.prompts, !prompts.isEmpty {
            return prompts.enumerated().map { index, prompt in
                SessionCard(id: "\(pack.id)-prompt-\(index)", content: .prompt(prompt))
            }
        }

        return PlayingCard.Suit.allCases.flatMap { suit in
            PlayingCard.Rank.allCases.map { rank in
                let card = PlayingCard(suit: suit, rank: rank)
                return SessionCard(id: card.id, content: .playing(card))
            }
        }
    }
}
