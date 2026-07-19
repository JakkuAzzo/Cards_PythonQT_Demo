import Foundation

struct GameManifest: Codable, Equatable, Identifiable {
    enum Archetype: String, Codable {
        case promptDraw = "prompt-draw"
        case poker
        case guessWho = "guess-who"
    }

    struct PlayerLimits: Codable, Equatable {
        let minimum: Int
        let maximum: Int
    }

    struct Deck: Codable, Equatable {
        enum Kind: String, Codable { case classic, prompts, characters }

        struct Card: Codable, Equatable, Identifiable {
            let id: String
            let text: String
        }

        let kind: Kind
        let cards: [Card]
    }

    struct Capabilities: Codable, Equatable {
        let multiplayer: Bool
        let nearby: Bool
        let ar: Bool
    }

    struct Resources: Codable, Equatable {
        let tableDesign: String
        let cardBack: String
        let cardSet: String
    }

    struct Rules: Codable, Equatable {
        enum TurnOrder: String, Codable { case clockwise }
        enum WinCondition: String, Codable { case deckEmpty = "deck-empty", lastPlayer = "last-player", manual }

        let initialHandSize: Int
        let drawPerTurn: Int
        let playPerTurn: Int
        let turnOrder: TurnOrder
        let winCondition: WinCondition
    }

    struct Presentation: Codable, Equatable {
        let accentStartHex: String
        let accentEndHex: String
        let supportsAR: Bool
    }

    let schemaVersion: Int
    let id: String
    let name: String
    let archetype: Archetype
    let summary: String
    let players: PlayerLimits
    let capabilities: Capabilities
    let resources: Resources
    let deck: Deck
    let rules: Rules
    let presentation: Presentation

    func validate() throws {
        guard schemaVersion == 1 else { throw ManifestError.unsupportedSchema }
        guard players.minimum > 0, players.minimum <= players.maximum, players.maximum <= 16 else {
            throw ManifestError.invalidPlayerLimits
        }
        guard capabilities.multiplayer == (players.maximum > 1) else { throw ManifestError.inconsistentCapabilities }
        guard ResourceCatalog.tableDesignIDs.contains(resources.tableDesign),
              ResourceCatalog.cardBackIDs.contains(resources.cardBack),
              ResourceCatalog.cardSetIDs.contains(resources.cardSet) else { throw ManifestError.unknownResource }
        guard Set(deck.cards.map(\.id)).count == deck.cards.count else { throw ManifestError.duplicateCardID }
        guard deck.cards.allSatisfy({ !$0.id.isEmpty && !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw ManifestError.invalidCard
        }
        let effectiveDeckCount = deck.kind == .classic && deck.cards.isEmpty ? 52 : deck.cards.count
        guard effectiveDeckCount >= rules.initialHandSize * players.minimum else { throw ManifestError.deckTooSmall }
    }

    enum ManifestError: Error, Equatable {
        case unsupportedSchema
        case invalidPlayerLimits
        case duplicateCardID
        case invalidCard
        case deckTooSmall
        case inconsistentCapabilities
        case unknownResource
    }

    static let tableTalk = GameManifest(
        schemaVersion: 1,
        id: "table-talk",
        name: "Table Talk",
        archetype: .promptDraw,
        summary: "Take turns drawing questions that skip the small talk.",
        players: PlayerLimits(minimum: 2, maximum: 8),
        capabilities: Capabilities(multiplayer: true, nearby: true, ar: true),
        resources: Resources(tableDesign: "green-classic", cardBack: "classic-pack-red", cardSet: "prompt-basic"),
        deck: Deck(kind: .prompts, cards: [
            .init(id: "tt-01", text: "What tiny decision changed your life more than you expected?"),
            .init(id: "tt-02", text: "Which place have you visited that still feels vivid?"),
            .init(id: "tt-03", text: "What skill would you love to become excellent at overnight?"),
            .init(id: "tt-04", text: "What is a hill you are willing to die on?"),
            .init(id: "tt-05", text: "Which ordinary day would you happily relive?"),
            .init(id: "tt-06", text: "What has made you laugh hardest this year?"),
            .init(id: "tt-07", text: "What is something you changed your mind about recently?"),
            .init(id: "tt-08", text: "Which fictional world would you visit for one week?")
        ]),
        rules: Rules(initialHandSize: 0, drawPerTurn: 1, playPerTurn: 0, turnOrder: .clockwise, winCondition: .deckEmpty),
        presentation: Presentation(accentStartHex: "7C3AED", accentEndHex: "DB2777", supportsAR: true)
    )
}

enum ResourceCatalog {
    static let tableDesignIDs: Set<String> = ["green-classic", "poker-2", "midnight", "guess-grid", "sunset-lounge", "paper-play"]
    static let cardBackIDs: Set<String> = ["classic-pack-red", "classic-red", "minimal-dark"]
    static let cardSetIDs: Set<String> = ["classic-pack-52", "standard-52", "prompt-basic", "classic-characters"]
}

struct MultiplayerPlayer: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let isHost: Bool
}

struct MultiplayerGameState: Codable, Equatable {
    enum Phase: String, Codable {
        case lobby
        case waitingForDraw
        case showingCard
        case finished
    }

    var revision = 0
    var phase: Phase = .lobby
    var players: [MultiplayerPlayer] = []
    var activePlayerIndex = 0
    var drawPile: [GameManifest.Deck.Card] = []
    var currentCard: GameManifest.Deck.Card?
    var discardPile: [GameManifest.Deck.Card] = []
    var seed: UInt64?

    var activePlayer: MultiplayerPlayer? {
        players.indices.contains(activePlayerIndex) ? players[activePlayerIndex] : nil
    }
}

enum MultiplayerCommand: Equatable {
    case join(id: String, name: String)
    case start(seed: UInt64)
    case draw(playerID: String)
    case endTurn(playerID: String)
}

enum MultiplayerEvent: Equatable {
    case playerJoined(MultiplayerPlayer)
    case gameStarted(seed: UInt64)
    case cardRevealed(cardID: String, playerID: String)
    case turnAdvanced(playerID: String)
    case gameFinished
}

enum MultiplayerRuleError: Error, Equatable {
    case lobbyClosed
    case duplicatePlayer
    case lobbyFull
    case notEnoughPlayers
    case alreadyStarted
    case notPlayersTurn
    case wrongPhase
    case deckEmpty
}
