# Cards iOS

The iPhone client is a native SwiftUI app with conventional and optional AR play modes.

## Generate the project

```bash
cd ios
xcodegen generate
open CardsiOS.xcodeproj
```

## Included

- Offline Classic Pack and prompt deck play, with the original designed Classic Pack selected by default.
- A host-authoritative multiplayer engine with deterministic shuffling and turn validation.
- A live Table Talk preview with local one-device play plus real nearby host/join controls.
- A shareable table code, host-authoritative commands, revisioned snapshots, loopback transport tests, and encrypted Apple Multipeer Connectivity for nearby Apple devices.
- ARKit/RealityKit horizontal-surface table placement.
- A lightweight template creator for poker, Guess Who, and custom prompt games.
- Playable Poker and Guess Who rooms: choose the shared Table, private Your deck, or Combined view; AR renders the same shared state on a surface when available.
- Manifest, creator, engine, transport, and deck XCTest sources.

The custom `Info.plist` declares camera, local-network, and `_cards-table._tcp` Bonjour access. AR remains optional; unsupported or camera-disabled devices can always use the conventional table.

## Creator boundary

The creator produces data, not Swift code. It selects from `ResourceCatalog`, applies template defaults, validates the result, and opens the matching supported runtime. Poker and Guess Who are playable local engines; unrecognised templates are rejected rather than executed.

## Production nearby work

`AppleNearbyTransport` supports encrypted Apple-to-Apple sessions. The live-table screen now creates and joins code-filtered nearby sessions, with the host admitting players and broadcasting state snapshots. Wiring Poker and Guess Who room commands to those snapshots, then sharing the same JSON envelopes with Android, remains outstanding.
