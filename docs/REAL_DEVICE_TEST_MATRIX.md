# Preview.9 real-device test matrix

This is the release-evidence checklist for the first nearby Cards preview. Record the device model, OS, app commit, and result for every row before tagging the release.

| Area | Devices | Pass condition |
| --- | --- | --- |
| Poker room | iPhone + Android | Host accepts guest actions; both devices display the same street, pot, folds, and revision; private cards never appear on the other device. |
| Guess Who room | iPhone + Android | Host accepts elimination/question/guess commands; the board and winner stay equal; each target remains recipient-only. |
| BLE pairing | iPhone + Android, Bluetooth only | Guest needs both room code and high-entropy pairing secret; valid secret exchanges encrypted frames; incorrect secret shows no state. |
| BLE reconnect | iPhone + Android | A guest disconnects/rejoins and receives the latest host snapshot and private state. |
| AR marker | iPhone + Android | Both recognise the 160 mm `cards-table-marker-v1` print and place their local table on it; losing the marker shows a recoverable status. |
| Non-AR fallback | iPhone + Android | Table, Your deck, and Combined views remain playable with camera denied or AR unsupported. |

Do not claim a cross-platform real-device release until every required row is recorded as passed. Simulator tests validate protocol and UI compilation but cannot validate Bluetooth radio discovery, camera tracking, or ARCore device support.
