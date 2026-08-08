# iOS client guide

1. `CardsiOSApp` and `RootView` own top-level SwiftUI navigation; retain the five product destinations and their meanings.
2. `GameRuntimes.swift` owns local Poker, Guess Who, and Dominoes rules/state. Keep renderer changes in views and rule changes in these models where possible.
3. `CustomGameRuntimeView.swift` is a large rendering coordinator for all three games. Avoid adding protocol or persistence logic to it; extract focused views/models when making substantial changes.
4. `GameRoomSyncController` binds a runtime to `GameRoomNetworkSession`; the latter owns role, revision, public snapshots, and private delivery.
5. Every `NearbyTransport` implementation must retain host authority, encrypted/authenticated transport, recipient-only private state, and snapshot recovery.
6. `BluetoothLETransport` is a cross-platform fallback. Do not change UUIDs, frame size, or envelope format without updating Android and the shared conformance fixture.
7. ARKit is optional and presentation-only. `ARTableModeView` must not mutate game rules or exchange AR world transforms.
8. Creator input selects validated data and bundled resources; it must never execute generated Swift or accept arbitrary filesystem assets.
9. Use XCTest files in `CardsiOSTests/` for runtime, creator, wire, and transport changes. Simulator success does not prove BLE or AR hardware behaviour.
10. Do not edit generated Xcode user data, `DerivedData`, or build products. `project.yml` is the source for XcodeGen project configuration.

See `../docs/ARCHITECTURE.md` and `../shared/PROTOCOL.md` before changing a cross-platform contract.
