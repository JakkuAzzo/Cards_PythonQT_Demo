# Cards mobile wireframe

`cards-mobile-wireframe.svg` is the editable source for the shared visual target
for the native iOS and Android shells. `cards-mobile-wireframe.png` is the
Adobe XD import board used for review. XD treats the SVG as an image format
rather than a native document, so the SVG remains the source of truth and the
PNG is the practical XD canvas asset.

The board was assessed against the current simulator and repository captures:

- [`ios-home.png`](../screenshots/ios-home.png) — current iOS home hierarchy,
  solo-first entry, deck card and persistent navigation.
- [`ios-live-table.png`](../screenshots/ios-live-table.png) — table/AR status,
  local preview and turn controls.
- [`web-mobile.png`](../screenshots/web-mobile.png) — responsive web shell and
  download/discovery content.

The wireframe deliberately keeps the strongest patterns from those screens,
removes dense setup copy, and makes the five destinations explicit before
platform-specific implementation begins.

The navigation is a floating dock inset from the screen edges. Inactive tabs
show only an icon; the active tab gets a quiet capsule and a short label. This
keeps all five destinations available without the cramped icon-plus-label row
that made the earlier shell feel utilitarian.

The five destinations are intentionally identical across platforms:

- Home: solo play is the first action.
- Library: bundled and locally-created games.
- Table: nearby/Bluetooth is secondary and never claims a connection early.
- Create: validated templates and bundled resources only.
- Discover: starter games and future pack discovery.

Native code should keep platform controls but follow the same order, spacing,
labels, colors, corner radii, and interaction hierarchy. The machine-readable
tokens live in [`shared/design-tokens.json`](../../shared/design-tokens.json).

## Reused production assets

The board uses assets that already ship with Cards rather than placeholder
artwork:

- [`web/assets/icon.svg`](../../web/assets/icon.svg) for the home mark and app
  identity.
- [`web/assets/logo-mark.svg`](../../web/assets/logo-mark.svg) for the full
  layered card logo when a larger lockup is needed.
- [`SPADES ACE.svg`](../../Packs/Demo/ClassicPack/SPADES%20ACE.svg) as the
  Classic Pack preview card.
- [`cards-table-marker-v1.svg`](../ar-marker/cards-table-marker-v1.svg) as the
  AR placement marker reference.

Game templates are represented by the existing bundled Classic Pack Poker,
Guess Who, and Double-Six Dominoes manifests. New templates should be added to
the allowlist and then reflected in this board before either native shell adds
new controls.
