# Cards shared protocol

The shared files in this directory are the contract between iOS, Android, future web services, creator tooling, and AI-assisted drafting.

## Template selection

The creator classifies an idea as `prompt-draw`, `poker`, or `guess-who`, then loads tested defaults. Configuration keys override those defaults. Every asset is referenced by an identifier from `resources/catalog.json`; arbitrary file paths and generated code are not accepted.

## Security boundary

Game packs are data, never executable code. An AI or human creator may produce a manifest, but the app accepts it only after schema and semantic validation. Unknown actions, invalid player limits, duplicate card identifiers, impossible hand sizes, and unsupported schema versions are rejected before a lobby can open.

## Session authority

One device is the host and owns the canonical `revision` and game state. Guests send commands; the host validates them and emits ordered events. Every accepted command increments the revision exactly once. A guest that detects a revision gap requests a complete snapshot.

Private information is sent in a `private-event` envelope with `recipientID`. Public snapshots must never contain another player's private hand. Nearby transports must use authenticated, encrypted connections and show a short verification code before a guest joins.

## Determinism

The host includes a 64-bit shuffle seed when starting a game. Implementations use SplitMix64 and a descending Fisher-Yates shuffle. For each index from `count - 1` through `1`, swap it with `nextUInt64() % (index + 1)`. This gives Swift, Java/Kotlin, and server implementations identical deck order for conformance tests.

## Rendering

The 2D table and AR table consume the same public state. AR coordinates are presentation data and never decide game rules. Offline mixed-platform AR aligns devices to a shared visual marker; optional Cloud Anchors may provide markerless alignment when internet access is available.

## Game rooms

`game-room-wire.schema.json` defines Poker and Guess Who payloads inside ordinary nearby envelopes. The host broadcasts only `publicState` in a `snapshot`; a private hand or target is sent separately in a recipient-addressed `private-event`. Guests only send `command` payloads, while the host validates, increments the revision, and republishes public plus relevant private state.

Poker supports `advance-street`, `bet`, and `fold`. Guess Who supports `toggle-elimination`, `ask-question`, `guess`, and `restart`. For board-oriented games, the shared Table is the board, leaderboard, or score tracker—not a fictitious physical card table.

## Bluetooth LE and AR alignment

The cross-platform BLE service UUID, stream characteristic UUID, and 160-byte packet payload are fixed in `conformance/game-room-wire-v1.json`. Envelopes are length-prefixed before being split across BLE writes so iPhone and Android can reconstruct the same stream without Wi-Fi.

`ar-alignment.schema.json` defines the `cards-table-marker-v1` contract. Once a phone recognizes the printed 160 mm marker, it may publish only its marker identifier, physical width, readiness status, and the current game revision in an `alignment` envelope. It must not send an AR world position or quaternion: each phone has a separate AR world coordinate system and independently anchors its board to the same physical marker. Alignment is presentation-only: it never changes a game revision or game rules.

## Transport

The preferred nearby topology is host-and-guests. The transport interface carries encoded envelopes and reports peers joining, leaving, and reconnecting. Android uses Google Nearby Connections with Bluetooth/Wi-Fi-assisted transport. Apple devices currently use encrypted Multipeer Connectivity for Apple-to-Apple sessions. The current Google Swift package supports iOS over Wi-Fi LAN only, so it must not be presented as a Bluetooth-capable mixed-platform transport; a dedicated cross-platform BLE transport is required before claiming no-Wi-Fi iPhone/Android play. Loopback transports remain available for deterministic automated tests.
