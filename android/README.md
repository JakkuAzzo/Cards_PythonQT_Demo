# Cards Android

This is the Android client in the canonical Cards repository. It is no longer the unrelated template previously stored in `JakkuAzzo/Cards`.

## Included

- The same SplitMix64/Fisher-Yates shuffle contract as iOS.
- A host-authoritative Table Talk engine with turn and revision validation.
- A Home/Library/Table/Create/Discover shell, local-first game entry, and saved validated creator drafts. The creator chooses only bundled Poker, Guess Who, Dominoes, or prompt-table templates; it does not generate code.
- Playable Classic Pack Poker, Guess Who, and Double-Six Dominoes. Poker and Guess Who can show the shared Table, the private Your deck page, or both together; Dominoes renders its shared train and private tile hand.
- A Google Nearby Connections `P2P_STAR` transport adapter with verification callbacks, byte payloads, peer lifecycle handling, and a host/join screen.
- ARCore configured as optional so unsupported devices keep the conventional table, with the bundled 160 mm printed marker registered for local shared-surface alignment.
- A dependency-free JVM conformance test for the core engine.

## Build

Open this directory in Android Studio with Android SDK 33 or newer installed. The
project currently uses Android Gradle Plugin 9.3.1 and the checked-in Gradle
9.5 wrapper. It is configured for Java 17: select JDK 17 as the **Gradle JDK**
in Android Studio, or set `JAVA_HOME` to a JDK 17 installation when building
from the terminal. Treat `build.gradle`, `gradle/wrapper/gradle-wrapper.properties`,
and CI as one build-toolchain decision.

To build from the command line:

```bash
JAVA_HOME=/path/to/jdk-17 ./gradlew :app:assembleDebug
```

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

The host shares a `CARDS-####` code and a pairing secret. Poker and Guess Who use encrypted host-authoritative Bluetooth room envelopes; host/join correctly refuse to claim success while Bluetooth is disabled or Nearby-device permission is missing. Dominoes is fully playable locally (including the deterministic Cards AI), but is not yet bound to the room transport. `ArTableActivity` performs optional ARCore installation, registers `cards-table-marker-v1`, and tells the player when the shared physical marker is recognised. Print it at 100% scale from [`docs/ar-marker`](../docs/ar-marker/README.md).

For ownership boundaries, known coordinator files, and safe extension points, see
[the architecture guide](../docs/ARCHITECTURE.md) and [Android agent guide](AGENTS.md).
