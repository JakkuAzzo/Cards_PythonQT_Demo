import SwiftUI

struct PackRecord: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let summary: String
    let status: String
    let badge: String
    let accentStartHex: String
    let accentEndHex: String
    let featured: Bool
    let config: [String: String]
    let playMode: PlayMode?
    let prompts: [String]?

    enum PlayMode: String, Codable {
        case classic
        case prompts
    }

    var resolvedPlayMode: PlayMode {
        playMode ?? ((prompts?.isEmpty == false) ? .prompts : .classic)
    }

    var configItems: [(key: String, value: String)] {
        config.keys.sorted().map { ($0, config[$0] ?? "") }
    }

    var titleLine: String {
        "\(badge) · \(status)"
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: accentStartHex), Color(hex: accentEndHex)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct PlayingCard: Identifiable, Hashable {
    enum Suit: String, CaseIterable {
        case hearts = "♥"
        case diamonds = "♦"
        case clubs = "♣"
        case spades = "♠"

        var isRed: Bool { self == .hearts || self == .diamonds }
    }

    enum Rank: String, CaseIterable {
        case ace = "A"
        case two = "2"
        case three = "3"
        case four = "4"
        case five = "5"
        case six = "6"
        case seven = "7"
        case eight = "8"
        case nine = "9"
        case ten = "10"
        case jack = "J"
        case queen = "Q"
        case king = "K"
    }

    let suit: Suit
    let rank: Rank
    var id: String { "\(rank.rawValue)-\(suit.rawValue)" }
}

struct SessionCard: Identifiable, Hashable {
    enum Content: Hashable {
        case playing(PlayingCard)
        case prompt(String)
    }

    let id: String
    let content: Content
}

struct PackStats: Codable, Equatable {
    var sessionsStarted = 0
    var cardsDrawn = 0
    var lastPlayed: Date?
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red, green, blue, alpha: Double
        switch cleaned.count {
        case 6:
            red = Double((value & 0xFF0000) >> 16) / 255
            green = Double((value & 0x00FF00) >> 8) / 255
            blue = Double(value & 0x0000FF) / 255
            alpha = 1
        case 8:
            red = Double((value & 0xFF000000) >> 24) / 255
            green = Double((value & 0x00FF0000) >> 16) / 255
            blue = Double((value & 0x0000FF00) >> 8) / 255
            alpha = Double(value & 0x000000FF) / 255
        default:
            red = 0.2
            green = 0.2
            blue = 0.25
            alpha = 1
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
