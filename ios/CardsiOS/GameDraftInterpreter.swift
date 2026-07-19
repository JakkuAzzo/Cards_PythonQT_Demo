import Foundation

struct GameDraftInterpreter {
    enum DraftError: Error, Equatable, LocalizedError {
        case emptyDescription
        case notEnoughCards
        case invalidPlayerRange
        case unknownGameType
        case unknownResource(String)

        var errorDescription: String? {
            switch self {
            case .emptyDescription: return "Describe the game before creating a draft."
            case .notEnoughCards: return "Custom prompt games need at least two card lines beginning with a dash."
            case .invalidPlayerRange: return "The player range must be between 1 and 16."
            case .unknownGameType: return "Use poker, guess-who, or prompt-draw as the game type."
            case .unknownResource(let resource): return "\(resource) is not in the bundled resource catalogue."
            }
        }
    }

    func interpret(_ description: String) throws -> GameManifest {
        let lines = description
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !lines.isEmpty else { throw DraftError.emptyDescription }

        let archetype = try classify(lines: lines, fullDescription: description)
        let multiplayerDefault = true
        let multiplayer = booleanDirective(["multiplayer"], in: lines) ?? multiplayerDefault
        let defaultMaximum = archetype == .guessWho ? 2 : (archetype == .poker ? 4 : 8)
        var playerRange = try configuredPlayerRange(in: lines) ?? (multiplayer ? 2...defaultMaximum : 1...1)
        if !multiplayer { playerRange = 1...1 }

        let defaultAR = archetype == .poker
        let arEnabled = booleanDirective(["ar"], in: lines) ?? defaultAR
        let tableDesign = normalizeResource(
            directive(["tabledesign", "table_design", "shared_card_table_theme"], in: lines)
                ?? defaultTable(for: archetype)
        )
        let cardBack = normalizeResource(directive(["cardback", "card_back"], in: lines) ?? "classic-pack-red")
        guard ResourceCatalog.tableDesignIDs.contains(tableDesign) else { throw DraftError.unknownResource(tableDesign) }
        guard ResourceCatalog.cardBackIDs.contains(cardBack) else { throw DraftError.unknownResource(cardBack) }

        let template = try template(for: archetype, lines: lines)
        let name = directive(["name"], in: lines) ?? template.name
        let slug = name.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        let manifest = GameManifest(
            schemaVersion: 1,
            id: slug.isEmpty ? "untitled-game" : String(slug.prefix(64)),
            name: String(name.prefix(80)),
            archetype: archetype,
            summary: directive(["summary", "idea"], in: lines) ?? template.summary,
            players: .init(minimum: playerRange.lowerBound, maximum: playerRange.upperBound),
            capabilities: .init(multiplayer: multiplayer, nearby: multiplayer, ar: arEnabled),
            resources: .init(tableDesign: tableDesign, cardBack: cardBack, cardSet: template.cardSet),
            deck: .init(kind: template.deckKind, cards: template.cards),
            rules: template.rules,
            presentation: .init(accentStartHex: template.accentStart, accentEndHex: template.accentEnd, supportsAR: arEnabled)
        )
        try manifest.validate()
        return manifest
    }

    private func classify(lines: [String], fullDescription: String) throws -> GameManifest.Archetype {
        let explicit = directive(["type", "game", "archetype"], in: lines)?.lowercased()
        let value = explicit ?? fullDescription.lowercased()
        if value.contains("guess who") || value.contains("guess-who") || value.contains("guess_who") { return .guessWho }
        if value.contains("poker") { return .poker }
        if explicit == "prompt" || explicit == "prompts" || explicit == "prompt-draw" { return .promptDraw }
        if lines.contains(where: { $0.hasPrefix("-") }) { return .promptDraw }
        if explicit != nil { throw DraftError.unknownGameType }
        return .promptDraw
    }

    private func template(for archetype: GameManifest.Archetype, lines: [String]) throws -> Template {
        switch archetype {
        case .poker:
            return Template(
                name: "Poker",
                summary: "A nearby poker table using the bundled standard deck.",
                deckKind: .classic,
                cards: [],
                cardSet: "classic-pack-52",
                rules: .init(initialHandSize: 2, drawPerTurn: 0, playPerTurn: 0, turnOrder: .clockwise, winCondition: .manual),
                accentStart: "14532D",
                accentEnd: "166534"
            )
        case .guessWho:
            let names = ["Alex", "Blair", "Casey", "Drew", "Emery", "Frankie", "Gray", "Harper", "Indigo", "Jules", "Kai", "Lane"]
            return Template(
                name: "Guess Who",
                summary: "A two-player character deduction game with a private target and shared grid.",
                deckKind: .characters,
                cards: names.enumerated().map { .init(id: "character-\($0.offset + 1)", text: $0.element) },
                cardSet: "classic-characters",
                rules: .init(initialHandSize: 1, drawPerTurn: 0, playPerTurn: 0, turnOrder: .clockwise, winCondition: .manual),
                accentStart: "0369A1",
                accentEnd: "7C3AED"
            )
        case .promptDraw:
            let cards = lines.enumerated().compactMap { index, line -> GameManifest.Deck.Card? in
                guard line.hasPrefix("-") else { return nil }
                let text = line.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
                return text.isEmpty ? nil : .init(id: "draft-\(index + 1)", text: text)
            }
            guard cards.count >= 2 else { throw DraftError.notEnoughCards }
            return Template(
                name: "Custom Card Game",
                summary: "A custom draw-and-pass prompt game.",
                deckKind: .prompts,
                cards: cards,
                cardSet: "prompt-basic",
                rules: .init(initialHandSize: 0, drawPerTurn: 1, playPerTurn: 0, turnOrder: .clockwise, winCondition: .deckEmpty),
                accentStart: "2563EB",
                accentEnd: "7C3AED"
            )
        }
    }

    private func configuredPlayerRange(in lines: [String]) throws -> ClosedRange<Int>? {
        if let maximumValue = directive(["max_user", "max_users", "maximum_users"], in: lines),
           let maximum = Int(maximumValue) {
            guard (1...16).contains(maximum) else { throw DraftError.invalidPlayerRange }
            let minimum = min(2, maximum)
            return minimum...maximum
        }
        guard let value = directive(["players"], in: lines) else { return nil }
        let expression = try NSRegularExpression(pattern: "^(\\d+)\\s*(?:-|to)\\s*(\\d+)$", options: .caseInsensitive)
        let range = NSRange(value.startIndex..., in: value)
        guard let match = expression.firstMatch(in: value, range: range),
              let minimumRange = Range(match.range(at: 1), in: value),
              let maximumRange = Range(match.range(at: 2), in: value),
              let minimum = Int(value[minimumRange]),
              let maximum = Int(value[maximumRange]),
              minimum > 0, minimum <= maximum, maximum <= 16 else {
            throw DraftError.invalidPlayerRange
        }
        return minimum...maximum
    }

    private func directive(_ keys: [String], in lines: [String]) -> String? {
        for key in keys {
            let prefix = key.lowercased() + ":"
            if let line = lines.first(where: { $0.lowercased().hasPrefix(prefix) }) {
                return line.dropFirst(prefix.count).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }

    private func booleanDirective(_ keys: [String], in lines: [String]) -> Bool? {
        guard let value = directive(keys, in: lines)?.lowercased() else { return nil }
        if ["y", "yes", "true", "1"].contains(value) { return true }
        if ["n", "no", "false", "0"].contains(value) { return false }
        return nil
    }

    private func defaultTable(for archetype: GameManifest.Archetype) -> String {
        switch archetype {
        case .poker: return "poker-2"
        case .guessWho: return "guess-grid"
        case .promptDraw: return "green-classic"
        }
    }

    private func normalizeResource(_ value: String) -> String {
        value.lowercased()
            .replacingOccurrences(of: ".png", with: "")
            .replacingOccurrences(of: ".svg", with: "")
            .replacingOccurrences(of: "_", with: "-")
    }

    private struct Template {
        let name: String
        let summary: String
        let deckKind: GameManifest.Deck.Kind
        let cards: [GameManifest.Deck.Card]
        let cardSet: String
        let rules: GameManifest.Rules
        let accentStart: String
        let accentEnd: String
    }
}
