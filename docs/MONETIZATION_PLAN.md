# Pizza Rush Monetization Plan

## Current mode

`hybrid`

- App target: `PizzaRush`
- Bundle ID: `COM.chiragkular.pizza-rush`
- Free App Store download
- No subscription, consumable currency, starter pack, paywall, RevenueCat,
  Firebase, mediation, or banner advertising

## Ad placements

### `double_level_coins`

- Format: Rewarded
- Entry point: Optional **Double Coins** action on a completed level's results
  screen
- Trigger: User taps the action after the result has been saved
- Frequency: Once per completed level
- Reward: Add exactly the level's eligible base coin award a second time
- Authority: A unique level-result reward claim written by the domain store
  only after Google invokes the verified user-earned-reward callback
- Durability: The claim and new balance are persisted atomically and survive
  relaunch; duplicate callbacks are idempotent
- Unavailable/failure/dismissal/timeout: Show **Reward unavailable.**, grant
  nothing, and keep Continue, Retry, and Upgrade available

### `level_transition`

- Format: Interstitial
- Entry point: Natural transition after leaving Results
- Trigger: Every third completed eligible level
- Frequency: Minimum 180-second wall-clock cooldown
- Exclusions: Never during gameplay, after a rewarded ad, in tutorial levels,
  within levels 1–3, immediately after launch, while consent is unresolved, or
  when Remove Ads is active
- Unavailable/failure: Continue navigation immediately

## Debug and Release identifiers

Debug uses Google's official iOS demo identifiers:

- App ID: `ca-app-pub-3940256099942544~1458002511`
- Rewarded: `ca-app-pub-3940256099942544/1712485313`
- Interstitial: `ca-app-pub-3940256099942544/4411468910`

Release values must be injected through `Config/Release.xcconfig` or Xcode Cloud
environment-backed build settings after the Pizza Rush AdMob records are read
back. Release must fail closed when the app ID, rewarded ID, or interstitial ID
is missing, malformed, a Google demo ID, or associated with another app. No
test-device override ships in Release, and production ads are never clicked
during validation.

## Consent and tracking

- Google UMP is consulted before Mobile Ads initialization or ad requests.
- Non-personalized/contextual advertising is the intended request mode.
- Intended audience is general, ages 13 and older.
- Child-directed/COPPA treatment: no.
- Made for Kids treatment: no.
- Under-age-of-consent tag: false for the declared audience.
- Cross-app tracking: no.
- ATT prompt: no.
- The app does not access IDFA when authorization has not been granted and does
  not add `NSUserTrackingUsageDescription`.
- The app remains playable when consent, network, or ads are unavailable.

## Remove Ads purchase

- Product ID: `com.chiragkular.pizzarush.removeads`
- Type: non-consumable
- Planned US price: $4.99
- Customer-visible entry: Settings → About & Support → Remove Ads
- Authority: Verified StoreKit 2 `Transaction.currentEntitlements`
- Effects: Disable interstitials. Optional rewarded ads remain available.
- Refresh: App launch, foreground, purchase completion, restore, and StoreKit
  transaction updates
- Failure/cancel/pending: Do not unlock. Show a clear state and preserve normal
  gameplay.
- Restore: Explicit Restore Purchases action in About & Support
- Revocation: Refresh removes the cached entitlement and restores capped
  interstitial eligibility

## Existing-customer and rollback behavior

This is the first release, so no migration is required. If App Store product
loading fails, purchase and restore show an unavailable state without blocking
play. If Google Mobile Ads or UMP is removed before release, all ad entry points,
SDK configuration, privacy disclosures, and review notes must be removed
together; rewarded value must not be granted locally as a substitute.

## Evidence boundaries

A source integration does not prove the AdMob records, App Store product,
hosted build, sandbox transaction, TestFlight ad behavior, or review state.
Those layers must be read back separately before submission.

