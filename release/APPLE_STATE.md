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

The canonical `asc web apps create` attempt preserved the exact name and used `--auto-rename=false`, but stopped before mutation because the cached Apple web session had expired and the command required an Apple Account login. The official API-key profile remains valid for supported API operations.

The app record must be created from an authenticated App Store Connect web session with:

- Name: Pizza Rush
- Bundle ID: `COM.chiragkular.pizza-rush`
- SKU: `PIZZARUSH-IOS`
- Primary locale: en-US
- Platform: iOS
- Initial version: 1.0

No alternative name is authorized if Apple rejects the exact name.
