# Cards Android

This is the Android client in the canonical Cards repository. It is no longer the unrelated template previously stored in `JakkuAzzo/Cards`.

## Included

- The same SplitMix64/Fisher-Yates shuffle contract as iOS.
- A host-authoritative Table Talk engine with turn and revision validation.
- A conventional live-table activity plus playable Classic Pack Poker and Guess Who rooms. Each can show the shared Table, the private Your deck page, or both together, and can open an optional AR surface.
- A Google Nearby Connections `P2P_STAR` transport adapter with verification callbacks, byte payloads, peer lifecycle handling, and a host/join screen.
- ARCore configured as optional so unsupported devices keep the conventional table, with the bundled 160 mm printed marker registered for local shared-surface alignment.
- A dependency-free JVM conformance test for the core engine.

## Build

Open this directory in Android Studio with Android SDK 33 or newer installed. The project intentionally does not contain a copied wrapper binary from the legacy repository; generate a current Gradle wrapper before CI is enabled.

## Test the dependency-free core

From the repository root:

```bash
BUILD_DIR="$(mktemp -d)"
javac -d "$BUILD_DIR" \
  android/app/src/main/java/com/jakkuazzo/cards/core/*.java \
  android/core-test/EngineSelfTest.java
java -cp "$BUILD_DIR" EngineSelfTest
```

## Important

The host shares a `CARDS-####` code. Guests enter it, compare Nearby authentication digits, then exchange versioned host-authoritative envelopes. A wrong code is rejected before a player is added to the table. The Poker and Guess Who rooms are local playable templates today; binding their table commands to Nearby snapshots is the remaining multiplayer task. `ArTableActivity` performs optional ARCore installation, registers `cards-table-marker-v1`, and tells the player when the shared physical marker is recognised. Print it at 100% scale from [`docs/ar-marker`](../docs/ar-marker/README.md).
