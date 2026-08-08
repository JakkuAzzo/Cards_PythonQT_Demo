# Android client guide

1. `HubActivity` is the launcher and owns Home, Library, Table, Create, and Discover; new product navigation belongs there.
2. `MainActivity` is the legacy nearby-table control flow. Do not add new primary product flows there; plan its migration into Hub’s Table destination separately.
3. Keep `core/` free of Android framework dependencies so `android/core-test/EngineSelfTest.java` can compile it with `javac`.
4. Put Bluetooth/Nearby implementation details in `nearby/`; transports carry envelopes and must not become a second game-rules engine.
5. Host authority, revision ordering, public/private-state separation, BLE framing, and marker-alignment rules are defined in `../shared/PROTOCOL.md`.
6. Check actual Bluetooth state and runtime permissions before advertising a nearby or BLE feature as ready. The emulator cannot certify radio discovery.
7. ARCore is optional. Camera failure, installation refusal, or unsupported hardware must return users to a usable digital table.
8. `GameRoomActivity` currently owns both Poker and Guess Who UI, local state, AI turns, and BLE binding. Keep fixes narrow; extract a tested domain type rather than adding a third unrelated responsibility.
9. `DominoesActivity` renders `core/DominoesGame`; preserve that rules/rendering boundary.
10. Do not edit `android/.gradle/`, `android/**/build/`, or `local.properties`. Build with `./gradlew` and the configured JDK/SDK.

See `../docs/ARCHITECTURE.md` for the repository-wide state flow.
