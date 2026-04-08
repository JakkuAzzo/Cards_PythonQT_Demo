import Foundation

@MainActor
final class PackStore: ObservableObject {
    @Published var packs: [PackRecord] = []
    @Published var selectedPack: PackRecord?
    @Published var activeSessionPack: PackRecord?

    init() {
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

        if selectedPack == nil || !packs.contains(where: { $0.id == selectedPack?.id }) {
            selectedPack = packs.first
        }
    }

    func select(_ pack: PackRecord) {
        selectedPack = pack
    }

    func startSession() {
        activeSessionPack = selectedPack ?? packs.first
    }

    func restartSession() {
        activeSessionPack = selectedPack ?? activeSessionPack ?? packs.first
    }

    func closeSession() {
        activeSessionPack = nil
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
                ]
            )
        ]
    }
}