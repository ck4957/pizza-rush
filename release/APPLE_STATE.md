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

On 2026-07-28 the owner authorized adding descriptive secondary text. The
selected App Store-only name is `Pizza Rush: Cooking Game`; the on-device name
remains `Pizza Rush`. A live U.S. App Store catalog search returned no exact
match, but App Store Connect creation remains the authoritative availability
check.

The authenticated App Store Connect form accepted the new name without an
inline collision error and enabled Create. Submitting the form redirected to
Apple's login page because the Chrome session expired. A subsequent authenticated
API-key read-back still returned zero app records, so creation did not complete.
