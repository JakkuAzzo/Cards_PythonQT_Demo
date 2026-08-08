import Foundation

@main
struct ConformanceRunner {
    @MainActor
    static func main() throws {
        let interpreter = GameDraftInterpreter()
        let poker = try interpreter.interpret("idea: four-player poker night\nmultiplayer: y\nmax_user: 4\nar: n\ntabledesign: poker_2.png")
        precondition(poker.archetype == .poker)
        precondition(poker.players.maximum == 4)
        precondition(poker.resources.tableDesign == "poker-2")
        // The creator's documented/default pack is the bundled designed
        // Classic Pack. `standard-52` remains only as a resource alias for
        // backwards-compatible manifests.
        precondition(poker.resources.cardSet == "classic-pack-52")
        precondition(poker.rules.initialHandSize == 2)
        precondition(!poker.capabilities.ar)

        let guessWho = try interpreter.interpret("idea: nearby Guess Who")
        precondition(guessWho.archetype == .guessWho)
        precondition(guessWho.players.maximum == 2)
        precondition(guessWho.deck.cards.count == 12)

        let engine = MultiplayerEngine()
        _ = try engine.handle(.join(id: "host", name: "Host"))
        _ = try engine.handle(.join(id: "guest", name: "Guest"))
        _ = try engine.handle(.start(seed: 42))
        let event = try engine.handle(.draw(playerID: "host"))
        precondition(event == .cardRevealed(cardID: "tt-04", playerID: "host"))
        print("Swift creator and multiplayer runtime checks passed.")
    }
}
