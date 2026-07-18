# Cards iOS

The iPhone client is a native SwiftUI app with conventional and optional AR play modes.

## Generate the project

```bash
cd ios
xcodegen generate
open CardsiOS.xcodeproj
```

## Included

- Offline classic and prompt deck play.
- A host-authoritative multiplayer engine with deterministic shuffling and turn validation.
- A live Table Talk preview with local one-device play plus real nearby host/join controls.
- A shareable table code, host-authoritative commands, revisioned snapshots, loopback transport tests, and encrypted Apple Multipeer Connectivity for nearby Apple devices.
- ARKit/RealityKit horizontal-surface table placement.
- A lightweight template creator for poker, Guess Who, and custom prompt games.
- Manifest, creator, engine, transport, and deck XCTest sources.

The custom `Info.plist` declares camera, local-network, and `_cards-table._tcp` Bonjour access. AR remains optional; unsupported or camera-disabled devices can always use the conventional table.

## Creator boundary

The creator produces data, not Swift code. It selects from `ResourceCatalog`, applies template defaults, validates the result, and enables a preview only when that runtime is implemented. Poker and Guess Who currently produce correct manifests but do not yet claim to be playable engines.

## Production nearby work

`AppleNearbyTransport` supports encrypted Apple-to-Apple sessions. The live-table screen now creates and joins code-filtered nearby sessions, with the host admitting players and broadcasting state snapshots. Cross-platform sessions should use the same JSON envelopes through Google Nearby Connections on both platforms; that Android UI integration remains outstanding.
