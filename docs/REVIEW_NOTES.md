# App Review Notes — Pizza Rush 1.0

Pizza Rush is a native iPhone arcade cooking game. No account or demo credentials are required.

## Primary review path

1. Launch and select Play.
2. Select Level 1 and Start Shift.
3. Complete or skip the five short tutorial panels.
4. Use Start with Dough, then Sauce and Cheese.
5. Move the pizza to the oven and use Remove from Oven when the state reads Perfect.
6. Slice, then Deliver.
7. Complete the shift and inspect stars, revenue, coins, Retry, Continue, and Upgrade Kitchen.

## Monetization

- Optional rewarded placement: Double Coins, offered once for an eligible completed level. Coins are granted only after Google's verified reward callback and the claim is persistent/idempotent.
- Interstitial placement: only after every third eligible completed non-tutorial level, with at least 180 seconds between presentations; never at launch, during gameplay, in levels 1–3, or immediately after a rewarded presentation.
- Remove Ads: one non-consumable StoreKit 2 product, `com.chiragkular.pizzarush.removeads`, planned US price USD 4.99. It removes interstitials while leaving rewarded Double Coins optional.
- Restore path: Main Menu → Settings → About & Support → Restore Purchases.
- Advertising privacy path, when required: Main Menu → Settings → About & Support → Advertising Privacy Choices.
- The app does not request ATT and requests non-personalized/contextual advertising only.

## Privacy and permissions

- No account, custom backend, analytics SDK, crash-reporting SDK, camera, microphone, photos, contacts, health, fitness, or location permission.
- Google Mobile Ads and UMP are disclosed in the App Privacy matrix.
- Export compliance: standard HTTPS only; no non-exempt encryption.

## Accessibility

Assist Mode increases target size, extends customer patience, widens the perfect-bake window, and slows order pressure without reducing rewards. Bake state uses text and symbols in addition to color. Reduce Motion removes nonessential travel, scale, pulse, and particles.

Automated accessibility evidence exists, but no App Store VoiceOver or Voice Control support declaration is requested until human review passes on the production-signed hosted build.

## Review contact

- First name: Chirag
- Last name: Kular
- Email: kular_chirag@yahoo.com
- Phone: `NEEDS_CONFIRMATION`
