# Cards iOS

This folder contains the SwiftUI rebuild for iPhone.

## Generate the Xcode project

```bash
cd ios
xcodegen generate
open CardsiOS.xcodeproj
```

## What is included

- A native SwiftUI shell with Home, Library, and Shop tabs.
- A bundled pack catalog derived from the demo pack configuration.
- A session screen that previews pack metadata on iPhone.

## What is not ported yet

- The Python pack runtime and dynamic `create_game_widget` entry points.
- Arbitrary local folder scanning from the desktop app.

Those desktop-only features need a separate native implementation or a backend service.