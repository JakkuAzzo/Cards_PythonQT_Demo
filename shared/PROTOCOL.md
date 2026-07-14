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

## Transport

The preferred mixed-platform nearby topology is host-and-guests. The transport interface carries encoded envelopes and reports peers joining, leaving, and reconnecting. The first production adapter should use Google Nearby Connections on both iOS and Android; loopback transports remain available for deterministic automated tests.
