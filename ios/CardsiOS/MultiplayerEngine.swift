import Foundation

@MainActor
final class MultiplayerEngine: ObservableObject {
    let manifest: GameManifest
    @Published private(set) var state = MultiplayerGameState()
    @Published private(set) var eventLog: [MultiplayerEvent] = []

    init(manifest: GameManifest = .tableTalk) {
        self.manifest = manifest
    }

    @discardableResult
    func handle(_ command: MultiplayerCommand) throws -> MultiplayerEvent {
        let event: MultiplayerEvent

        switch command {
        case .join(let id, let name):
            guard state.phase == .lobby else { throw MultiplayerRuleError.lobbyClosed }
            guard !state.players.contains(where: { $0.id == id }) else { throw MultiplayerRuleError.duplicatePlayer }
            guard state.players.count < manifest.players.maximum else { throw MultiplayerRuleError.lobbyFull }
            let player = MultiplayerPlayer(id: id, name: name, isHost: state.players.isEmpty)
            state.players.append(player)
            event = .playerJoined(player)

        case .start(let seed):
            guard state.phase == .lobby else { throw MultiplayerRuleError.alreadyStarted }
            guard state.players.count >= manifest.players.minimum else { throw MultiplayerRuleError.notEnoughPlayers }
            state.seed = seed
            state.drawPile = SeededShuffle.shuffle(manifest.deck.cards, seed: seed)
            state.activePlayerIndex = 0
            state.phase = .waitingForDraw
            event = .gameStarted(seed: seed)

        case .draw(let playerID):
            try requireTurn(playerID)
            guard state.phase == .waitingForDraw else { throw MultiplayerRuleError.wrongPhase }
            guard !state.drawPile.isEmpty else { throw MultiplayerRuleError.deckEmpty }
            let card = state.drawPile.removeFirst()
            state.currentCard = card
            state.phase = .showingCard
            event = .cardRevealed(cardID: card.id, playerID: playerID)

        case .endTurn(let playerID):
            try requireTurn(playerID)
            guard state.phase == .showingCard else { throw MultiplayerRuleError.wrongPhase }
            if let card = state.currentCard {
                state.discardPile.append(card)
            }
            state.currentCard = nil
            if state.drawPile.isEmpty {
                state.phase = .finished
                event = .gameFinished
            } else {
                state.activePlayerIndex = (state.activePlayerIndex + 1) % state.players.count
                state.phase = .waitingForDraw
                event = .turnAdvanced(playerID: state.activePlayer?.id ?? "")
            }
        }

        state.revision += 1
        eventLog.append(event)
        return event
    }

    func reset() {
        state = MultiplayerGameState()
        eventLog = []
    }

    private func requireTurn(_ playerID: String) throws {
        guard state.activePlayer?.id == playerID else { throw MultiplayerRuleError.notPlayersTurn }
    }
}

enum SeededShuffle {
    static func shuffle<Element>(_ elements: [Element], seed: UInt64) -> [Element] {
        guard elements.count > 1 else { return elements }
        var result = elements
        var generator = SplitMix64(seed: seed)
        for index in stride(from: result.count - 1, through: 1, by: -1) {
            let other = Int(generator.next() % UInt64(index + 1))
            result.swapAt(index, other)
        }
        return result
    }
}

private struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}
