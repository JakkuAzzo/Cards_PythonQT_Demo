import Foundation

@MainActor
final class PackStore: ObservableObject {
    @Published var packs: [PackRecord] = []
    @Published var selectedPack: PackRecord?
    @Published var activeSessionPack: PackRecord?
    @Published private(set) var favoritePackIDs: Set<String> = []
    @Published private(set) var statsByPackID: [String: PackStats] = [:]

    private let defaults: UserDefaults
    private static let selectedPackKey = "selectedPackID"
    private static let favoritesKey = "favoritePackIDs"
    private static let statsKey = "packStats"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        favoritePackIDs = Set(defaults.stringArray(forKey: Self.favoritesKey) ?? [])
        if let data = defaults.data(forKey: Self.statsKey),
           let decoded = try? JSONDecoder().decode([String: PackStats].self, from: data) {
            statsByPackID = decoded
        }
        loadPacks()
    }

    func loadPacks() {
        if let url = Bundle.main.url(forResource: "packs", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([PackRecord].self, from: data) {
            packs = decoded
        } else {
            packs = Self.fallbackPacks
        }

        let savedID = defaults.string(forKey: Self.selectedPackKey)
        if selectedPack == nil || !packs.contains(where: { $0.id == selectedPack?.id }) {
            selectedPack = packs.first(where: { $0.id == savedID }) ?? packs.first
        }
    }

    func select(_ pack: PackRecord) {
        selectedPack = pack
        defaults.set(pack.id, forKey: Self.selectedPackKey)
    }

    func toggleFavorite(_ pack: PackRecord) {
        if favoritePackIDs.contains(pack.id) {
            favoritePackIDs.remove(pack.id)
        } else {
            favoritePackIDs.insert(pack.id)
        }
        defaults.set(Array(favoritePackIDs).sorted(), forKey: Self.favoritesKey)
    }

    func isFavorite(_ pack: PackRecord) -> Bool {
        favoritePackIDs.contains(pack.id)
    }

    func stats(for pack: PackRecord) -> PackStats {
        statsByPackID[pack.id] ?? PackStats()
    }

    func startSession() {
        activeSessionPack = selectedPack ?? packs.first
        if let pack = activeSessionPack {
            recordSessionStarted(for: pack)
        }
    }

    func restartSession() {
        activeSessionPack = selectedPack ?? activeSessionPack ?? packs.first
        if let pack = activeSessionPack {
            recordSessionStarted(for: pack)
        }
    }

    func closeSession() {
        activeSessionPack = nil
    }

    func recordCardDrawn(for pack: PackRecord) {
        var stats = stats(for: pack)
        stats.cardsDrawn += 1
        stats.lastPlayed = Date()
        statsByPackID[pack.id] = stats
        persistStats()
    }

    private func recordSessionStarted(for pack: PackRecord) {
        var stats = stats(for: pack)
        stats.sessionsStarted += 1
        stats.cardsDrawn += 1
        stats.lastPlayed = Date()
        statsByPackID[pack.id] = stats
        persistStats()
    }

    private func persistStats() {
        if let data = try? JSONEncoder().encode(statsByPackID) {
            defaults.set(data, forKey: Self.statsKey)
        }
    }

    private static var fallbackPacks: [PackRecord] {
        [
            PackRecord(
                id: "demo",
                name: "Demo Pack",
                summary: "Built-in pack that showcases multiplayer, a shared card table, and the greyscale theme.",
                status: "Bundled",
                badge: "Starter",
                accentStartHex: "F59E0B",
                accentEndHex: "EF4444",
                featured: true,
                config: [
                    "multiplayer": "y",
                    "shared_card_table": "y",
                    "theme": "greyscale"
                ],
                playMode: .classic,
                prompts: nil
            )
        ]
    }
}
