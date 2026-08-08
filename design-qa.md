**Findings**

- [P1] The live table still opens a separate legacy activity.
  Location: Android `HubActivity` Table destination.
  Evidence: the verified Hub Table screen exposes an "Open table controls" action; the reference keeps Table inside the persistent five-tab experience.
  Impact: navigation continuity is still broken while playing or connecting.
  Fix: migrate the legacy table controls into the Table destination and retain the bottom navigation in active-table states.

- [P2] Android does not yet have the supplied card-preview and tab-icon assets.
  Location: Android Home and bottom navigation.
  Evidence: the reference uses a physical Ace preview and distinct iconography; the new Android screen uses text-only controls.
  Impact: it is structurally aligned but not yet at iOS visual parity.
  Fix: reuse the bundled card artwork and add an Android icon resource set before release.

**Open Questions**

- The attached reference includes an iOS device frame and desktop surroundings, so comparison is restricted to app-owned content.

**Implementation Checklist**

1. Keep Home, Library, Table, Create, and Discover as persistent Android destinations.
2. Embed the nearby/Bluetooth table flow in the Table destination.
3. Add the existing card artwork and proper Android navigation icons.
4. Re-capture Home and Table at the same app-content scale.

**Comparison Evidence**

- Source visual truth: `/tmp/codex-remote-attachments/019f612c-8c24-7dd0-a111-351287627080/857E82D0-6C20-41ED-B3F1-51B58827ECFF/1-Photo-1.jpg`
- Android Home capture: `/tmp/cards-android-hub-home.png` (1080 × 1794; emulator app content)
- Android Table capture: `/tmp/cards-android-hub-table.png` (1080 × 1794; emulator app content)
- State tested: Home, Table tab navigation, build/install.
- Focused comparison: Home hierarchy and bottom navigation were inspected. The iOS frame and desktop surroundings were excluded from the judgement.

**Comparison History**

- Initial state: Android opened into a raw connection form with game buttons above the status and no product navigation.
- Fix applied: added a launcher `HubActivity` with Home, Library, Table, Create, and Discover destinations; moved the legacy controls behind Table.
- Post-fix evidence: the Home capture now follows the iOS hierarchy—ready state, selected Classic Pack, primary solo action, progress card, persistent destination bar.

final result: blocked
