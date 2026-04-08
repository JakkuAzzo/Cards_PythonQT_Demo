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