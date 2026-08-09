# Cards mobile design specification

The implementation target is [`docs/design/cards-mobile-wireframe.png`](docs/design/cards-mobile-wireframe.png), with the editable source in
[`docs/design/cards-mobile-wireframe.svg`](docs/design/cards-mobile-wireframe.svg).
The values below are mirrored in [`shared/design-tokens.json`](shared/design-tokens.json);
update the token file first when a cross-platform value changes.

## Product structure

The permanent navigation is Home, Library, Table, Create, and Discover. Home starts solo play; Library selects installed games and packs; Table owns nearby play; Create makes validated templates; Discover promotes included and future packs.

Navigation uses one floating dock inset from the screen edges. Inactive
destinations are icon-only; the selected destination gets a single capsule,
accent color, and short label. Do not render five equal-width text buttons.

## Visual tokens

| Token | Value | Use |
| --- | --- | --- |
| Background | `#080A10` | App canvas |
| Surface | `#1F242D` | Cards, panels, empty states |
| Secondary control | `#334363` | Secondary actions and tabs |
| Teal | `#1A9686` | Pack surfaces and game emphasis |
| Mint | `#46DCAA` | Primary actions and positive state |
| Gold | `#F5B72B` | Selected navigation, rewards, winner state |
| Primary text | `#FFFFFF` | Headings and controls |
| Secondary text | `#BEC6D5` | Supporting copy |

Use 20–24dp continuous corners for surfaces, 16–18dp for controls, 48dp minimum touch targets, and 8dp spacing increments.

These rules were checked against the iOS home/live-table captures and the web
mobile capture in [`docs/design/README.md`](docs/design/README.md). The native
shells may use platform-native controls, but their hierarchy, labels, spacing,
and semantic colors must remain equivalent.

## Game surfaces

- Poker: show community cards as a dedicated horizontal rail, player status as compact rows, and one primary next action.
- Guess Who: show a 3-column character board, an explicit current turn, a question result, and one action footer.
- Dominoes: use ivory pip tiles, a visible shared train, a compact boneyard/score strip, and a private hand grid.

## Mode hierarchy

Solo play is primary. `Play together` is a collapsed secondary section. AR is available after a local or nearby game has loaded and must explain its camera/surface state before placement.
