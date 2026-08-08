# Cards production-release gates

Cards v1 is a native, local-first release. It does not need a backend or an
account service. Do not call a build production-ready merely because it compiles
or because a GitHub prerelease exists.

## Required evidence before tagging a production version

1. CI passes shared contracts, web verification, Android build, and iOS XCTest.
2. The four shipped games complete their automated local/AI rule scenarios on
   both platforms.
3. Every row in `REAL_DEVICE_TEST_MATRIX.md` has a recorded pass on the exact
   release commit, including Bluetooth-off/permission-denied and non-AR fallbacks.
4. Android has a Play App Signing configuration, signed release AAB, store
   listing, privacy policy URL, screenshots, and internal-track smoke test.
5. iOS has an Apple Developer account, App ID/capabilities, signing profile,
   privacy manifest/listing, TestFlight build, and external-device smoke test.
6. macOS and Windows artifacts, if distributed, are explicitly marked as the
   limited offline desktop preview unless their feature set reaches native parity.
7. The static site’s download links, support form, privacy page, version notes,
   and known limitations point to the tagged release.

## Release workflow

1. Bump Android `versionCode`/`versionName` and iOS bundle version together.
2. Create release notes from the completed test matrix and list remaining
   platform limitations plainly.
3. Build signed artifacts in protected CI using repository secrets; never add
   signing keys, provisioning profiles, or FormSubmit activation mail to Git.
4. Install each artifact from the release channel on a clean device, verify the
   first-run permission flows, then publish progressively.
5. Keep the preceding production artifact available until the new release has
   passed its store/real-device smoke test.

## Explicit non-gates for v1

Cloud accounts, analytics, public matchmaking, browser gameplay, server-side
background jobs, and remote pack storage are post-v1 work. Adding any of them
requires a privacy-policy update and a separate architecture/security review.
