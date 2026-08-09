# Cards v1 completion roadmap

Cards v1 is a native local-first release. The web site is a static release and
support surface; browser gameplay, accounts, cloud packs, internet matchmaking,
and background services are explicitly post-v1 work.

## 1. Cross-platform product parity

- Use one visual token set for colour, type scale, spacing, cards, buttons, navigation, empty states, and disabled states.
- Make Home, Library, Table, Create, and Discover communicate the same purpose on iOS and Android.
- Use the bundled card faces and pack artwork in Android instead of text-only approximations.
- Keep solo play as the primary path; keep Nearby, Bluetooth, and AR as deliberate secondary modes.

## 2. Complete game rules and AI

- Finish Poker hand evaluation, winner payouts, folding, and a meaningful pot.
- Give Guess Who a turn model, question outcomes, elimination validation, and an explicit round result.
- Keep Dominoes rules host-authoritative, including blocked rounds, scoring, and restart state.
- Replace the current deterministic move picker with game-specific, explainable heuristic choices.

## 3. Multiplayer and AR validation

- Bind each runtime to the existing host-authoritative room protocol on Android and iOS.
- Validate encrypted BLE discovery, pairing, reconnection, leave, and state recovery on two real phones.
- Validate shared AR marker alignment and surface placement on supported real devices.

## 4. Creator, packs, and accessibility

- Add validated game templates, custom pack import rules, asset previews, and table themes.
- Add scalable text, touch-target checks, TalkBack/VoiceOver labels, reduced motion, and offline/error states.

## 5. Release readiness

- Run a platform matrix: unit rules, simulator flows, two-device nearby/BLE, AR fallback, and release builds.
- Produce signed Android, desktop, and later iOS release artifacts with release notes and screenshots.
- Complete every gate in [`docs/PRODUCTION_RELEASE.md`](docs/PRODUCTION_RELEASE.md), including Apple/Google signing, store metadata, privacy information, and real-device evidence.
