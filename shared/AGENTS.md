# Shared contract guide

1. This directory is the versioned data contract between native clients, tests, creator tooling, and future services.
2. Keep schemas closed (`additionalProperties: false`) unless a reviewed compatibility change needs an extension.
3. Add a resource through `resources/catalog.json`, package it in both clients, and validate it before exposing it to creator input.
4. Do not add executable behaviour or arbitrary asset paths to a game manifest.
5. A host owns state and revisions; public snapshots must exclude every other player’s private data.
6. Any shuffle, wire-format, BLE frame, or AR marker change requires matching Swift, Java, fixture, and test updates.
7. Do not transmit AR world poses. The marker contract contains only marker identity, physical width, readiness, and revision.
8. Run `python3 -m unittest discover -s shared/tests -v` after every contract/catalog/fixture change.

`PROTOCOL.md` explains the behavioural contract; schemas and conformance fixtures are the machine-readable authority.
