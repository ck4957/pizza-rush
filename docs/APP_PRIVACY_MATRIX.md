# Pizza Rush App Privacy Matrix

Version 1.0 has no account, login, custom server, analytics SDK, crash-reporting SDK, user-generated content, or sensitive-device permission. The only third-party SDKs are Google Mobile Ads and Google UMP.

## App Store privacy answers

| Data type | Collected | Linked to user | Used for tracking | Purpose | Source |
| --- | --- | --- | --- | --- | --- |
| Coarse Location | Yes, potentially from IP address | No | No | Third-Party Advertising, Analytics | Google Mobile Ads |
| Device ID | Yes | No | No | Third-Party Advertising, Analytics, Fraud Prevention/Security | Google Mobile Ads |
| Product Interaction | Yes | No | No | Third-Party Advertising, Analytics | Google Mobile Ads |
| Advertising Data | Yes | No | No | Third-Party Advertising, Analytics | Google Mobile Ads |
| Crash Data | Yes, potentially | No | No | App Functionality, Analytics | Google Mobile Ads |
| Performance Data | Yes, potentially | No | No | App Functionality, Analytics | Google Mobile Ads |
| Other Diagnostic Data | Yes, potentially | No | No | App Functionality, Analytics | Google Mobile Ads |

No name, email, phone number, address, precise location, contacts, photos, camera, microphone, health, fitness, financial information, payment card data, browsing history, search history, user content, gameplay contents, or sensitive information is collected by Pizza Rush.

## Advertising configuration

- Personalized advertising: No
- Cross-app tracking: No
- ATT prompt: No
- UMP consent: Required before Mobile Ads initialization or requests
- Request treatment: Non-personalized/contextual
- Maximum ad content rating: G
- Child-directed/COPPA treatment: No
- Made for Kids: No
- Intended audience: General, age 13+
- Debug: Official Google demo identifiers only
- Release: Pizza Rush production identifiers only, injected at build time; fail closed otherwise

The final App Store selections must be reconciled against the privacy manifests and SDK versions compiled into the exact hosted build. “Data Not Collected” is not an authorized answer.

## Product and owner data

- Local SwiftData profile: coins, levels, scores, stars, upgrades, settings, tutorial steps, ad-reward claims, and cached Remove Ads state remain on device.
- StoreKit: Apple processes the non-consumable Remove Ads transaction. Pizza Rush receives verified entitlement state, not payment-card information.
- Game Center: Apple provides authentication and score/achievement services. Pizza Rush does not operate its own Game Center server.
- Own server storage: None
- Analytics SDK: None
- Crash-reporting SDK: None
- RevenueCat: None
