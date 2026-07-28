# Pizza Rush simulator acceptance evidence

Evaluated 2026-07-28 on:

- iPhone 17 simulator, iOS 26.1, Debug, bundle
  `COM.chiragkular.pizza-rush`
- iPhone 17 Pro Max simulator, iOS 26.5, Debug and Release, bundle
  `COM.chiragkular.pizza-rush`
- Xcode 26.6, iPhoneSimulator 26.5 SDK, Swift 6 strict concurrency

## Clean first-run and recoverable failure

XcodeBuildMCP launched a clean in-memory profile with ads unavailable. The
runtime accessibility tree exposed Play, all 20 level cells, the Level 1
objective and recipes, all five onboarding panels, the production-order legend,
order patience, ingredient controls, oven, slice, delivery, pause, and results
actions.

The observed no-fixture journey was:

1. Main Menu → Play → Level 1 → Start Shift.
2. Read and dismissed all five timer-paused tutorial panels.
3. Started dough, added sauce and cheese, moved the assembled pizza to the
   oven, removed it in a deliverable phase, sliced, boxed, and delivered it.
4. The live HUD changed from 0 to 58 revenue and combo 0 to combo 1.
5. The timer expired below the 258 target and produced `Rush Missed` with
   revenue 58, best combo 1, a disabled `Reward unavailable.` action, Retry,
   Continue, Upgrade Kitchen, and Main Menu.

The failure did not block navigation or corrupt the saved result.

## Complete successful journey without gameplay fixture

`PizzaRushUITests.testFullSuccessfulLevelWithoutGameplayFixture` launched a
clean profile, completed the real onboarding, produced and delivered one Cheese
and one Pepperoni pizza through the live 1/60-second engine and perfect timing
window, reached the configured target, waited for the real level timer, observed
`Shift Complete!`, and continued to unlocked Level 2. Duration: 74.831 seconds.

Evidence: `product/evidence/runtime/full-success-ui-test.log`.

## Persistence

`testCompletedResultPersistsAcrossTerminationAndRelaunch` saved a completed
level result to the non-memory SwiftData store, terminated the process,
relaunched without the result fixture, and read back Level 11 and 726 coins on
the main menu.

Evidence: `product/evidence/runtime/persistence-relaunch-ui-test.log`.

## Release and screenshot states

The Release simulator app built, installed, and launched with zero diagnostics.
Because production AdMob identifiers were not yet injected, the authorized
`-AdsUnavailable` seam was used; Mobile Ads was not initialized and normal game
navigation remained available. Five real-app Release captures were inspected at
1320×2868:

- `product/screenshots/en-US/iphone-6.9/01-build-your-pizza.png`
- `product/screenshots/en-US/iphone-6.9/02-master-the-oven.png`
- `product/screenshots/en-US/iphone-6.9/03-beat-the-lunch-rush.png`
- `product/screenshots/en-US/iphone-6.9/04-upgrade-your-kitchen.png`
- `product/screenshots/en-US/iphone-6.9/05-fastest-pizzeria.png`

Evidence: `product/evidence/runtime/release-build-run.log` and
`product/evidence/runtime/rush-fixture.mp4`.

## Accessibility and layout

At accessibility XXXL, results changed to a single-column metric layout and
stacked actions. Retry and Continue remained discoverable and hittable after
scrolling. Bake timing displays a text state and dot/check/star/exclamation/
smoke cue in addition to color. Reduce Motion disables SpriteKit travel, scale,
particle, and perfect-pulse effects plus pressed-button scaling and toast
transitions.

Evidence: `product/evidence/runtime/accessibility-xxxl-ui-test.log` and
`product/screenshots/en-US/iphone-6.9/02-master-the-oven.png`.
