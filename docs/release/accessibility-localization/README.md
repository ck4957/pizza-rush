# Pizza Rush Accessibility and Localization Evidence

Evaluated for iPhone, English (`en`) binary content, en-US App Store metadata, and the US test region.

## Shipping-surface inventory

- One native iOS application target: `PizzaRush`.
- No widget, extension, App Intent, notification, account, camera, microphone, photo, health, location, or user-generated-content surface.
- SwiftUI surfaces: launch/main menu, level selection, pre-level objective, tutorial, gameplay HUD and controls, pause/settings, results, upgrades, About & Support, privacy, terms, and reset confirmation.
- SpriteKit surface: the visible preparation → oven → cutting → dispatch kitchen, exposed through equivalent named SwiftUI actions and state labels.
- System surfaces: Game Center authentication, StoreKit 2 Remove Ads, Google UMP consent, rewarded and interstitial advertising.
- Bundled display data: six recipe and ingredient names, twenty level objectives, upgrade categories, tutorial copy, errors, and settings.
- Store metadata surface: en-US only, with five iPhone 6.9-inch screenshots.

Stable model identifiers, ad identifiers, product identifiers, recipe IDs, accessibility identifiers, and persisted enum values are intentionally not localized. Version 1 has no translated locale, server copy, user-authored text, or package-localized resource.

## Binary localization

- Xcode project development region: `en`.
- Release build setting: `DEVELOPMENT_LANGUAGE = en`.
- Approved binary locale: `en`.
- Approved App Store metadata locale: `en-US`.
- SwiftUI literal labels use native localizable call sites. Dynamic model display text is English source content because English is the only approved binary locale.
- No String Catalog translation is claimed, and no translated `.lproj` resource is represented as shipped.
- RTL layout and non-English pseudolanguage certification are not claimed because version 1 supports English only.

## Automated and runtime evidence

- The complete suite passed 28 of 28 tests on iPhone 17 Pro Max, iOS 26.5.
- A clean, real-timer UI journey completed all first-run instruction panels, made and delivered Cheese and Pepperoni pizzas, completed the level, and continued to Level 2.
- Accessibility XXXL changed the result metrics to a one-column layout and kept Retry and Continue reachable and hittable.
- The runtime accessibility tree exposes stable names and identifiers for menu, levels, objectives, tutorial, order values, ingredients, every production action, bake state/value, pause, results, upgrades, and support.
- The perfect bake state is communicated using text, a star/check/dot/exclamation/smoke shape system, and progress in addition to color and sound.
- Reduce Motion removes SpriteKit travel, bounce/scale, particles, and perfect-window pulse plus SwiftUI pressed scaling and toast movement, while preserving completion state.
- Contrast calculations and the five final Release screenshots are recorded under `product/evidence`.

## Feature decision

- Larger Text, Sufficient Contrast, Differentiate Without Color Alone, and Reduced Motion have automated/runtime evidence and are approved in the app-local configuration.
- Dark Interface is intentionally not supported in version 1.
- Captions and Audio Descriptions are not applicable because the game contains no video, dialogue, narration, or audio-only information.
- VoiceOver and Voice Control implementation evidence exists, but human common-journey review on the production-signed hosted build remains `NEEDS_CONFIRMATION`.
- The App Store accessibility declaration is therefore empty. No accessibility support flag may be written until that human review passes.

## Release evidence

- `product/evidence/tests/full-test-suite.log`
- `product/evidence/runtime/accessibility-xxxl-ui-test.log`
- `product/evidence/runtime/full-success-ui-test.log`
- `product/evidence/runtime/simulator-run.md`
- `product/evidence/06-color-palette-contrast.md`
- `product/screenshots/en-US/iphone-6.9/`
