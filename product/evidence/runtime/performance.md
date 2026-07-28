# Runtime Performance Evidence

Measured on the iPhone 17 Pro Max simulator while the Release build was running the deterministic rush fixture.

- App identifier: `COM.chiragkular.pizza-rush`
- Version/build: `1.0 (1)`
- Simulator runtime: iOS 26.5
- Physical footprint: 34.5 MB
- Peak physical footprint: 50.4 MB
- `footprint` rounded result: 35 MB
- App-specific dirty memory: 45.2 MB in the accompanying `vmmap -summary` sample
- Launch command completed in approximately 1.2 seconds

The process RSS reported by `ps` includes resident pages from the iOS simulator's shared frameworks and is not the app's physical footprint. The acceptance limit is evaluated against the app-specific physical footprint reported by Apple's `footprint` tool.

## Acceptance

The observed 50.4 MB peak is below the product acceptance target of approximately 250 MB.
