# Pizza Rush Repository Instructions

- Preserve the product identity: on-device name Pizza Rush, owner-approved App Store name Pizza Rush: Cooking Game, bundle ID `COM.chiragkular.pizza-rush`, SKU `PIZZARUSH-IOS`, iOS 17+, iPhone portrait.
- Preserve the exact production order and rules in `product/source/principal-development-plan.md`, `product/pre-build.json`, and `product/acceptance.json`.
- Use Xcode Cloud with Apple-managed signing for every distributable archive and upload. Local builds are for simulator validation and screenshots only.
- Debug advertising must use Google's official demo identifiers. Release must fail closed until Pizza Rush production identifiers are injected; never reuse another app's IDs.
- Do not grant a rewarded result before Google's verified reward callback, and persist the claim idempotently.
- Do not request ATT or enable personalized/cross-app tracking in version 1.
- Keep App Review release mode manual after approval.
- Do not claim App Store accessibility support until the human VoiceOver and Voice Control gate in `Config/release-accessibility-localization.json` is confirmed on the hosted build.
