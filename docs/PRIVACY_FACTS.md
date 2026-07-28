# Pizza Rush Privacy, Audience, and Legal Facts

These facts are the selected implementation contract for version 1.0. App Store
privacy answers will be reconciled against the compiled privacy report and the
current Google Mobile Ads and UMP disclosures before submission.

## Audience

- Intended audience: General audience, ages 13 and older
- Child-directed/COPPA treatment: No
- Made for Kids treatment: No
- Advertising restriction: Contextual/non-personalized inventory suitable for
  a general 13+ casual game; no sensitive-category targeting configured

## Product data

- Accounts or login: No
- User-generated content: No
- Data stored on our own server: None
- Analytics SDK: None; provider-neutral gameplay events are handled by a local
  no-op implementation in version 1
- Crash-reporting SDK: None; Apple Xcode Organizer may provide Apple-managed
  diagnostics outside the app's own server
- Purchases: One StoreKit 2 non-consumable Remove Ads product; no RevenueCat
- Location: No app permission or precise location collection. Google may use IP
  address to estimate general location as disclosed by its SDK documentation.
- Contact information: None collected in the app
- User content: None
- Health, fitness, camera, microphone, contacts, or photos: None
- Third-party content: Google-served advertising creatives only

## Advertising SDK behavior

- SDKs: Google Mobile Ads and Google UMP
- Personalized advertising: No
- Cross-app tracking: No
- ATT prompt: No
- Device identifiers: Google Mobile Ads may collect advertising or
  app/developer-bounded device identifiers for third-party advertising and
  analytics; declare Device ID, not linked to identity, for those purposes
- Usage data: Google Mobile Ads may collect advertising data and product
  interactions for third-party advertising and analytics; declare not linked
  to identity
- Diagnostics: Google Mobile Ads may collect crash logs and performance data
  for advertising, analytics, and SDK improvement; declare not linked to
  identity
- General location: IP-derived coarse location may be processed by Google;
  declare when required by the final privacy report and App Store definition
- No app-owned analytics profile, raw device identifier log, name, email,
  precise location, or ingredient drag-path log

## Rights and legal

- Content and asset rights: Owned. Code, gameplay data, text, procedural audio,
  and ImageGen-created assets are original to Pizza Rush; reference projects
  provide architecture only and no source assets are copied.
- Encryption: Standard Apple/Google HTTPS only; no custom or non-exempt
  cryptography
- Export compliance: Exempt, subject to App Store Connect confirmation from the
  compiled binary
- Review demo account: Not required
- Release after approval: Manual. App Review submission is authorized, but
  customer release is not.

