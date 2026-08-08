# Cards architecture

## Product boundary

Cards is a local-first game platform. The native mobile apps provide the
playable product: a player can start a local game, share a public table with
nearby peers, keep a private hand/target, and optionally render that same
public table in AR. The static site and desktop preview do not implement those
mobile capabilities.

## Repository map

| Area | Owns | Main entry points |
| --- | --- | --- |
| `shared/` | Versioned manifest, resource, wire, AR-alignment, and conformance contracts | `PROTOCOL.md`, JSON schemas, `tests/test_contracts.py` |
| `ios/CardsiOS/` | SwiftUI product navigation, game rendering/rules, Apple nearby and BLE transports, ARKit | `CardsiOSApp.swift` → `RootView.swift` |
| `ios/CardsiOSTests/` | XCTest coverage for creator, runtime rules, protocol and transport behaviour | `*Tests.swift` |
| `android/app/` | Android navigation, rooms, nearby/BLE transports, optional ARCore rendering | `HubActivity.java` launcher |
| `android/app/.../core/` | Java deterministic engine, shuffle, frame and alignment primitives | `MultiplayerEngine.java`, `DominoesGame.java` |
| `android/core-test/` | Dependency-free Java conformance executable | `EngineSelfTest.java` |
| `Packs/` | Bundled Classic Pack artwork | `Packs/Demo/ClassicPack/` |
| `web/` | Static product, updates, feedback, and release links | `index.html` |
| `desktop/` | Minimal offline Tk preview packaged for desktop prereleases | `cards_desktop.py` |
| `.github/workflows/` | Contract, iOS, Android, web verification and tagged prerelease artifacts | `ci.yml`, `release.yml` |

## State and data flow

1. A creator input is classified into a supported game archetype and resolved
   against the resource allowlist. It produces configuration data, never code.
2. A local game runtime owns rules and state. Its renderer presents the public
   table, its player’s private deck/target, or the combined view.
3. For a room, the host validates commands, updates canonical state, increments
   `revision`, emits a public snapshot, then sends recipient-only state as a
   private event.
4. The transport carries envelopes; it does not decide game rules. It may be
   loopback (tests), Apple nearby, Google Nearby Connections, or the BLE
   fallback.
5. A 2D table and AR table render the same public state. The AR marker only
   aligns visual placement locally and cannot affect a game revision.

## Canonical contracts and invariants

- `shared/game-manifest.schema.json` describes accepted game manifests.
- `shared/resources/catalog.json` is the resource identifier allowlist.
- `shared/game-room-wire.schema.json` and `shared/PROTOCOL.md` define room
  privacy and host-authority behaviour.
- `shared/conformance/game-room-wire-v1.json` fixes BLE packet compatibility.
- `shared/ar-alignment.schema.json` defines the printed-marker payload; raw AR
  world transforms are prohibited.
- Swift and Java use the same seeded SplitMix64/Fisher–Yates shuffle.

## Platform implementation notes

### iOS

`RootView` owns the five top-level product destinations. `GameRuntimes.swift`
contains the local Poker, Guess Who, and Dominoes models. `CustomGameRuntimeView.swift`
renders their room-specific SwiftUI views. `GameRoomSyncController` joins a
runtime to `GameRoomNetworkSession`, which owns revisioned public/private
delivery through a `NearbyTransport`. `ARTableModeView` is optional and reads
rendering data only.

### Android

`HubActivity` is the launcher and owns the five-tab product shell.
`MainActivity` is the existing nearby/table-control activity reached from the
Table tab. `GameRoomActivity` currently combines Poker/Guess Who room UI,
local state, optional Cards AI, and BLE room binding; it is the main future
extraction candidate. `DominoesActivity` renders the local Dominoes experience
over the isolated `core/DominoesGame` rules model. `nearby/` adapts Google
Nearby or GATT/BLE to envelopes; `core/` should remain Android-framework-free.

## Build and validation

- Shared contracts: `python3 -m unittest discover -s shared/tests -v`.
- Swift conformance runner: command in the root `AGENTS.md` and `README.md`.
- Android core: compile `android/app/.../core/*.java` with
  `android/core-test/EngineSelfTest.java`.
- Full Android build uses `android/gradlew` with the configured JDK and Android
  SDK. Full iOS tests use `xcodebuild` against a simulator. CI runs both plus a
  small static-site check.
- Tag-triggered release workflow produces an unsigned debug APK, macOS DMG,
  and Windows executable. iOS distribution is intentionally separate because
  it needs Apple signing credentials.

## Safe extension points

- Add a bundled game by extending the manifest schema/catalog only when both
  native runtimes and tests understand it.
- Add game rules in platform runtime/core models first, then render them in
  platform UI. Keep public and private state explicit.
- Add a transport behind the existing envelope/transport abstractions; it must
  retain host authority, encryption, privacy, ordering, and recovery rules.
- Add assets through the catalog and package resources, never through user file
  paths in a runtime manifest.

## Known structural debt

- `GameRoomActivity.java` and `CustomGameRuntimeView.swift` are large
  multi-game coordinators. Split them incrementally by game and by transport
  adapter only after preserving existing UI flows with tests.
- The shared JSON contract is not yet generated into Swift and Java models.
  Resource IDs and parts of the manifest knowledge are duplicated by hand.
- Android UI is currently programmatic and repeats small visual helpers across
  activities. A shared Android design component layer would reduce repetition.
- The legacy Android `MainActivity` breaks the five-tab shell while table
  controls are open. Folding it into the Table destination is a product/UI
  refactor, not a documentation-only change.
