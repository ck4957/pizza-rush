# Apple Release State

Read back 2026-07-28 through `asc` 3.0.0 using the validated `hourside-release` App Store Connect API-key profile from the system Keychain.

## Created

- Bundle ID resource: `7MFAHM59SK`
- Identifier: `COM.chiragkular.pizza-rush`
- Team/seed ID: `64FN52KV6J`
- Platform returned by Apple: `UNIVERSAL`
- In-App Purchase capability: `7MFAHM59SK_IN_APP_PURCHASE`
- Game Center capability: `7MFAHM59SK_GAME_CENTER`

## App record

`asc apps list --bundle-id COM.chiragkular.pizza-rush` returned zero app records.

An authenticated App Store Connect web attempt used the owner-fixed values:

- Name: Pizza Rush
- Bundle ID: `COM.chiragkular.pizza-rush`
- SKU: `PIZZARUSH-IOS`
- Primary locale: en-US
- Platform: iOS
- Initial version: 1.0

Apple rejected the creation request before mutation with:

> The app name you entered is already being used. If you have trademark rights to this name and would like it released for your use, submit a claim.

No alternative name is authorized. Until the owner obtains the name through
Apple's claim process or explicitly approves a different name, there is no App
Store Connect app ID against which metadata, In-App Purchase, App Privacy,
screenshots, Xcode Cloud, hosted build attachment, or App Review submission can
be created.
