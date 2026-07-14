# Cards Android

This is the Android client in the canonical Cards repository. It is no longer the unrelated template previously stored in `JakkuAzzo/Cards`.

## Included

- The same SplitMix64/Fisher-Yates shuffle contract as iOS.
- A host-authoritative Table Talk engine with turn and revision validation.
- A conventional live-table activity that can be used without a camera.
- A Google Nearby Connections `P2P_STAR` transport adapter with verification callbacks, byte payloads, and peer lifecycle handling.
- ARCore configured as optional so unsupported devices keep the conventional table.
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

The Nearby adapter requests the platform permissions listed by Google, but the app must still add a user-facing host/join screen that presents the authentication digits before accepting a connection. `ArTableActivity` currently performs the optional ARCore installation and session lifecycle; shared marker alignment and card rendering are the next AR milestone.
