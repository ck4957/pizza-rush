# Monetization Acceptance Evidence

Product acceptance was evaluated independently from production AdMob and App Store record creation.

- Debug configuration contains only Google's official iOS demo application, rewarded, and interstitial identifiers.
- Release configuration has no copied or fallback production identifier. It fails closed until Pizza Rush identifiers are injected through build settings.
- UMP consent completes before Mobile Ads initialization or an ad request. Requests use non-personalized treatment, and the app does not request ATT.
- `AppModel` grants Double Coins only from the ad service's `.earned` result. Load, dismissal, presentation failure, timeout, and unavailable results do not enter the reward-claim transaction.
- `PersistenceService` stores a unique completed-session claim, and the engine rejects a repeated claim.
- Interstitial eligibility is centralized in `InterstitialPolicy`: every third eligible completed level, at least 180 seconds apart, excluding levels 1–3, tutorial completion, launch, gameplay, the session after a rewarded presentation, and every session with Remove Ads active.
- The results UI exposes the exact disabled fallback `Reward unavailable.` while Continue, Retry, Upgrade Kitchen, and Main Menu remain usable.
- The StoreKit 2 purchase service reads localized product display data, accepts only verified transactions, refreshes current entitlements on launch, observes transaction updates including revocation, and restores through `AppStore.sync()`.
- Remove Ads suppresses interstitials and leaves the optional rewarded Double Coins placement available.

Deterministic coverage is included in `product/evidence/tests/full-test-suite.log`. The unavailable-ad user journey and Release fallback are recorded in `product/evidence/runtime/simulator-run.md` and `product/screenshots/en-US/iphone-6.9/05-fastest-pizzeria.png`.

Production AdMob identifiers, dashboard read-back, and a hosted StoreKit/AdMob binary remain separate release gates and are not inferred from this product-acceptance result.
