# AdMob Release State

Read back 2026-07-28 from the authenticated Google AdMob dashboard.

## Account

- Account state: Open
- Publisher ID: `pub-3911596373332918`
- App-ads.txt line supplied by AdMob: `google.com, pub-3911596373332918, DIRECT, f08c47fec0942fa0`

## Pizza Rush app

- App name: Pizza Rush
- Platform: iOS
- Listed in a supported app store: No
- AdMob internal app record: `1697904631`
- AdMob application ID: `ca-app-pub-3911596373332918~1697904631`
- Approval status: Requires review
- Ad-serving state: Limited ad serving; add the App Store listing later to lift the limit
- Active ad units: 2

## Ad units

### Double Coins

- Format: Rewarded
- Ad unit ID: `ca-app-pub-3911596373332918/3661843134`
- Reward amount: 1
- Reward item: Double Coins
- Product behavior: the app ignores an unverified load/dismiss/failure and grants the durable once-per-level double only after Google's earned-reward callback

### Level Transition

- Format: Interstitial
- Ad unit ID: `ca-app-pub-3911596373332918/1573781552`
- Product policy: every third eligible non-tutorial level, at least 180 seconds apart, never during gameplay, at launch, in levels 1–3, immediately after a rewarded presentation, or while Remove Ads is active

## Build configuration

- Debug retains only Google's official iOS demo app and unit IDs.
- Release uses the Pizza Rush application and ad-unit IDs above.
- No production ad was clicked during testing.
- The exact app-ads.txt seller line is published at `https://ck4957.github.io/pizza-rush/app-ads.txt`.
