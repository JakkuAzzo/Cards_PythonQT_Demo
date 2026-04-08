# Cards App

Cards App is a lightweight Python launcher environment for running card games and other small Python apps inside a single desktop shell.

An iPhone rebuild now lives in [ios/README.md](ios/README.md) with a generated Xcode project under [ios/CardsiOS.xcodeproj](ios/CardsiOS.xcodeproj).

## What it does

- Manages local packs from the Library view.
- Lets you pick a pack, launch a session, and inspect basic game state.
- Provides a reusable UI shell for Python-based games or app previews.

## Setup

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run

```bash
python main.py
```

## iPhone build

```bash
cd ios
xcodegen generate
open CardsiOS.xcodeproj
```

The iPhone target is a native SwiftUI rebuild. It renders bundled pack metadata and a session shell, but it does not execute the old PyQt pack widgets.

## Pack format

A pack is a folder under `Packs/` with a readable `game_config.txt` and optionally a Python entry script.

Example:

- `Packs/Demo/game_config.txt`
- `Packs/Demo/generate_game_gui.py`

If a pack includes a Python script, the app detects it and previews the pack metadata in the session window.

## Demo pack

The built-in Demo pack is meant to show how pack metadata is surfaced in the app. It is not a full game engine yet, but it now loads visible content instead of acting like a dead selection.

## Notes

- `requirements.txt` currently pins PyQt6.
- The Library uses `Packs/card_packs.txt` as the canonical pack registry.
- The app is structured so it can be extended to run additional Python games or app-style packs.
