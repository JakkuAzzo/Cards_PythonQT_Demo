# Cards repository guide for coding agents

## Fast orientation

Cards is a local-first native card-game app. `ios/` and `android/` are the
shipping mobile clients; `shared/` is the cross-platform data/protocol
contract; `web/` is a static product and release-information site, not a game
client. `desktop/` is a deliberately small offline preview used for the macOS
and Windows prerelease artifacts.

## Working rules

1. Read `README.md`, this file, and the relevant local `AGENTS.md` before changing a platform subsystem.
2. Treat `shared/` schemas, conformance fixtures, and `shared/PROTOCOL.md` as the cross-platform contract; change Android and iOS implementations and their tests in the same change when a contract changes.
3. Game packs are declarative data only. Do not introduce executable scripts, arbitrary asset paths, or generated code through creator input or manifests.
4. Resource IDs must be allowlisted in `shared/resources/catalog.json`; retain legacy aliases until both clients no longer need them.
5. The host owns canonical state and the monotonically increasing `revision`. Guests submit commands and never mutate canonical state directly.
6. Increment a game revision exactly once for each accepted host command. A guest that has a revision gap must recover from a snapshot.
7. Never include another player’s hand, target, or other private state in a public snapshot. Use a recipient-addressed `private-event`.
8. Keep all nearby traffic authenticated and encrypted, and require comparison/pairing data before a peer is admitted. Do not report Bluetooth or nearby play as available when the operating system has disabled it.
9. The SplitMix64 plus descending Fisher–Yates shuffle is a compatibility contract. Changing it requires updating the shared conformance fixture and both runtimes together.
10. BLE UUIDs, packet framing, and maximum packet payload are protocol constants in `shared/conformance/game-room-wire-v1.json`; do not change one platform independently.
11. AR is presentation only: it must consume the same public state as the 2D table and must never decide rules or revisions.
12. Never transmit AR world coordinates or rotations between devices. Each device anchors locally to `cards-table-marker-v1` and may publish only the documented alignment status.
13. ARCore and ARKit are optional. Camera denial, unsupported hardware, and simulator runs must leave conventional Table, Deck, and Combined play available.
14. Preserve the product model: Home starts local/solo play, Library owns installed games, Table owns nearby controls, Create produces validated drafts, and Discover promotes packs/templates.
15. Keep nearby and Bluetooth secondary to the local/solo path. A local game must not require Wi-Fi, BLE, camera, or an account.
16. A room’s Table is public; Your deck is private; Combined is a convenience rendering of those two states. This privacy split applies to Poker, Guess Who, and Dominoes.
17. Keep game rules separate from rendering where practical. Android `core/` and iOS runtime models are the safest places for deterministic rule changes; views/activities should not become another source of rules.
18. `GameRoomActivity.java` and `CustomGameRuntimeView.swift` currently coordinate several responsibilities. Make focused changes there and prefer extracting a tested domain type rather than adding more unrelated behaviour.
19. `MainActivity.java` is the legacy Android table-control flow. New product navigation belongs in `HubActivity`; preserve the legacy activity only while its controls are still used.
20. The iOS creator interprets text into a supported manifest; it must select tested templates rather than generate Swift or gameplay code.
21. Android’s launcher is `HubActivity`; iOS’s app entry is `CardsiOSApp` and `RootView`. Keep the five product destinations semantically aligned across platforms.
22. Generated and local-only directories must not be edited or committed: `android/.gradle/`, any `build/`, `ios/DerivedData/`, `dist/`, `outputs/`, IDE settings, and Xcode user data.
23. Do not treat the static `web/` page as evidence that browser gameplay or network features exist. It only links to releases and project information.
24. Run the dependency-free shared, Swift conformance, and Java-core tests for contract or rule changes. Platform UI/permission/AR changes also need the relevant simulator or device evidence.
25. Real phones—not simulators—are required to certify BLE discovery, camera/AR tracking, printed-marker alignment, and cross-platform nearby play. Record that evidence in `docs/REAL_DEVICE_TEST_MATRIX.md`.

## Useful checks

```bash
python3 -m unittest discover -s shared/tests -v

RUNNER="$(mktemp)"
xcrun swiftc ios/CardsiOS/MultiplayerModels.swift ios/CardsiOS/MultiplayerEngine.swift \
  ios/CardsiOS/GameDraftInterpreter.swift tools/SwiftConformanceRunner.swift -o "$RUNNER"
"$RUNNER"

BUILD_DIR="$(mktemp -d)"
javac -Xlint:all -Werror -d "$BUILD_DIR" \
  android/app/src/main/java/com/jakkuazzo/cards/core/*.java android/core-test/EngineSelfTest.java
java -cp "$BUILD_DIR" EngineSelfTest
```

See `docs/ARCHITECTURE.md` for ownership, data flow, entry points, and the
known boundaries that should be improved incrementally.
