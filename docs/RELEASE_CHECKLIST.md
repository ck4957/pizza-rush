# Pizza Rush 1.0 Release Checklist

## Passed locally

- [x] Fixed identity, bundle ID, version, build, iPhone-only target, and iOS 17 minimum
- [x] Product pre-build schema
- [x] Product acceptance contract
- [x] 34 of 34 product-acceptance criteria passed
- [x] 27 of 27 unit, integration, and UI tests passed
- [x] Debug and Release simulator builds passed
- [x] Full clean first-run tutorial-to-Level-2 journey passed
- [x] Save failure, corrupt save, and termination/relaunch persistence passed
- [x] Five current 1320×2868 Release screenshots inspected
- [x] Physical memory footprint 34.5 MB, peak 50.4 MB
- [x] Shared release check passed with the explicit accessibility-declaration skip warning
- [x] Apple bundle ID `7MFAHM59SK` created with In-App Purchase and Game Center capabilities

## External release gates

- [x] Public GitHub repository created and exact commit read back
- [x] GitHub Pages marketing, support, privacy, terms, contact, and app-ads.txt URLs live
- [x] AdMob app and production rewarded/interstitial units created and read back
- [x] Production AdMob identifiers injected into Release
- [x] Exact production-identifier commit pushed and read back
- [ ] App Store Connect app record created with the exact fixed name — blocked: Apple reports the name is already in use; no alternative is authorized
- [ ] Version 1.0, categories, price, availability, age rating, rights, encryption, metadata, and App Privacy complete
- [ ] Remove Ads IAP created, localized, priced at USD 4.99, and supplied with review evidence
- [ ] Screenshots delivered in App Store Connect with every asset state COMPLETE
- [ ] Review contact phone confirmed by owner
- [ ] Human VoiceOver and Voice Control journey reviewed before any accessibility declaration
- [ ] Xcode Cloud workflow configured against the exact GitHub commit
- [ ] Hosted build processed as VALID and APP_STORE_ELIGIBLE
- [ ] Exact hosted build attached to version 1.0
- [ ] App Store validation has no unresolved errors
- [ ] Review submission state read back after authorized submission

Release after approval remains manual.
