# Apple Release State

Read back 2026-07-28 through `asc` 3.0.0 using the validated `hourside-release` App Store Connect API-key profile from the system Keychain.

## Created

- Bundle ID resource: `7MFAHM59SK`
- Identifier: `COM.chiragkular.pizza-rush`
- Team/seed ID: `64FN52KV6J`
- Platform returned by Apple: `UNIVERSAL`
- In-App Purchase capability: `7MFAHM59SK_IN_APP_PURCHASE`
- Game Center capability: `7MFAHM59SK_GAME_CENTER`

## App record and version

- App Store Connect app ID: `6795540557`
- App Store name: `Pizza Rush: Cooking Game`
- On-device name: `Pizza Rush`
- Bundle ID: `COM.chiragkular.pizza-rush`
- SKU: `PIZZARUSH-IOS`
- Primary locale: en-US
- App Info ID: `40cf4b03-81ea-429a-91eb-1c0049944925`
- Version 1.0 ID: `50fcf9c4-47a2-4172-b7d0-725fe647e0bf`
- Version state: `PREPARE_FOR_SUBMISSION`
- Release type: `MANUAL`
- Copyright: `2026 Chirag Kular`

`asc apps list --bundle-id COM.chiragkular.pizza-rush` returned exactly this
record. `asc versions list --app 6795540557` returned exactly version 1.0.

## Store configuration

- Primary category: Games
- Primary game subcategories: Casual, Simulation
- Secondary category: Entertainment
- App price: Free, base territory United States
- Availability: all 175 countries or regions, including future territories
- Distribution: Public
- Content rights: `USES_THIRD_PARTY_CONTENT` because Google may serve authorized third-party ad creative
- Age-rating declaration: advertising present; every objectionable-content field NONE/false
- App Privacy: published 2026-07-28
- Privacy data types: Coarse Location, Device ID, Product Interaction, Advertising Data, Crash Data, Performance Data, Other Diagnostic Data
- Privacy linkage/tracking: every disclosed type not linked to identity and not used for tracking
- Product-page screenshots: five `APP_IPHONE_67` assets, each `COMPLETE`

The public API failed to initialize the app-availability record with an internal
server error, so authenticated App Store Connect completed that web-only gap.
Current browser read-back shows `Availability (175 Countries or Regions)` and
each storefront `Available on App Release`.

## Remove Ads in-app purchase

- App Store Connect IAP ID: `6795541865`
- Product ID: `com.chiragkular.pizzarush.removeads`
- Type: Non-Consumable
- Name: Remove Ads
- en-US localization: Remove Ads / Permanently removes interstitial ads.
- Base price: USD 4.99
- Availability: all 175 territories, including future territories
- Review screenshot ID: `d48de0a2-fa15-4371-b3ff-7ee53d997035`
- Review screenshot state: `COMPLETE`
- IAP state: `READY_TO_SUBMIT`

## Remaining Apple gates

- Review contact phone: `NEEDS_CONFIRMATION`; Apple rejects review-detail creation without it
- Xcode Cloud product/workflow: not configured
- Hosted build: none
- Build-specific export-compliance answer: pending the hosted build
- Version build attachment: none
- Review submission: `NOT_SUBMITTED`
- App accessibility declarations: intentionally empty pending human VoiceOver and Voice Control review
