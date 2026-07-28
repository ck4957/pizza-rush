# Pizza Rush — Principal iOS Game Development Plan

## 1. Product Definition

**Working title:** Pizza Rush  
**Genre:** Hyper-casual time-management / arcade cooking  
**Platform:** iPhone first  
**Orientation:** Portrait  
**Target OS:** iOS 17+  
**Session length:** 30–90 seconds  
**Input:** One-thumb tap and drag  
**Business model:** Free with rewarded ads, limited interstitials, and an optional ad-removal purchase  
**Primary differentiator:** A compact, toy-like isometric kitchen where the player physically moves ingredients through a visible pizza-production line.

### Product promise

> Build, bake, slice, and dispatch pizzas before impatient customers leave.

The player should understand the game within five seconds:

1. An order appears.
2. The player assembles the requested pizza.
3. The pizza enters the oven.
4. The player removes it at the right moment.
5. The pizza is sliced, boxed, and dispatched.
6. The player earns coins and serves the next order.

---

# 2. Scope and Feasibility

The illustrated concept is not realistically a polished 3D production game in three to five days, even with AI coding tools. A credible schedule is:

| Build | Scope | Estimate |
|---|---:|---:|
| Playable prototype | One kitchen, three recipes, basic timers, no ads | 3–5 days |
| App Store MVP | 20–30 levels, progression, audio, ads, persistence, polish | 10–14 days |
| Strong commercial V1 | 50+ levels, upgrades, balancing, analytics, onboarding, QA | 3–5 weeks |
| Live-game foundation | Events, content packs, remote tuning, retention systems | 6–10 weeks |

The fastest native implementation is **2D SpriteKit with pre-rendered isometric assets**, not real-time 3D.

SpriteKit provides a Metal-backed 2D renderer, animation, particles, physics, and scene management. SwiftUI can present a SpriteKit scene directly through `SpriteView`. 

## Recommended visual strategy

Create the appearance of a toy-like 3D kitchen through:

- Isometric 2D illustrations
- Layered PNG or WebP-style source assets exported as PNG
- Soft contact shadows
- Normal-looking lighting baked into sprites
- Scale, squash, bounce, rotation, and particle animations
- Slight depth sorting based on each object's vertical position
- Optional short sprite sheets for cheese stretch and oven bubbling

This produces the desired aesthetic while keeping implementation, performance, and asset production manageable.

---

# 3. Core Design Pillars

## 3.1 Instant readability

Every object must communicate its purpose without text:

- Dough station
- Sauce dispenser
- Cheese hopper
- Ingredient trays
- Oven
- Cutting board
- Delivery counter

Orders use ingredient icons rather than written recipe names.

## 3.2 Productive pressure

The game creates tension through overlapping work rather than complicated controls:

- One pizza is being assembled.
- Another pizza is baking.
- A finished pizza is waiting to be sliced.
- Customers are losing patience.

The player improves by managing this pipeline efficiently.

## 3.3 Satisfying completion

Each production stage needs a distinct reward:

- Dough expands with a soft bounce.
- Sauce spirals over the base.
- Cheese scatters physically.
- Ingredients snap into arrangement.
- Oven glows and bubbles.
- Pizza receives a clean radial slice.
- Box closes with a stamp.
- Delivery produces a coin burst.

## 3.4 Short, recoverable failure

Mistakes should reduce score or customer patience without immediately ending the session.

Examples:

- Slightly undercooked: lower tip
- Burned pizza: discard and remake
- Wrong topping: remove before baking
- Slow service: customer patience declines
- Missed order: streak resets, but the level continues

---

# 4. Core Gameplay Loop

```text
Enter Level
    ↓
Receive Orders
    ↓
Select Dough
    ↓
Add Sauce and Cheese
    ↓
Add Requested Toppings
    ↓
Move Pizza into Oven
    ↓
Remove During Perfect Bake Window
    ↓
Slice and Box
    ↓
Send to Correct Customer
    ↓
Earn Coins, Tips, Combo and Stars
    ↓
Repeat Until Shift Timer Ends
    ↓
Level Results
    ↓
Upgrade Kitchen / Continue
```

## 4.1 Level objective types

Use a small number of reusable objective templates:

### Revenue target

Earn a required amount before time expires.

```text
Earn 450 coins in 75 seconds.
```

### Customer target

Successfully serve a required number of customers.

```text
Serve 12 customers.
```

### Quality target

Maintain a minimum average quality score.

```text
Finish with 85% average quality.
```

### Combo target

Reach a continuous perfect-service streak.

```text
Complete a 6-order combo.
```

### Ingredient challenge

Operate with a restricted recipe set or limited inventory.

```text
Serve 8 mushroom pizzas with only two ovens.
```

For the MVP, implement revenue, customer count, and combo objectives. The remaining types can reuse the same level engine later.

---

# 5. Distinctive Gameplay Mechanic

The main mechanic should not be a generic sequence of disconnected mini-games.

## The Kitchen Conveyor

Every pizza occupies a physical production slot:

```text
Preparation → Oven → Cutting → Dispatch
```

The player drags pizzas between stations. Each station has limited capacity.

### Why this works

- Creates spatial planning
- Makes upgrades visually meaningful
- Supports one-thumb play
- Produces natural pressure
- Allows numerous level variations
- Separates Pizza Rush from tap-only cooking clones

### Capacity examples

| Station | Starting capacity | Upgrade range |
|---|---:|---:|
| Prep counter | 1 pizza | 1–3 |
| Oven | 1 pizza | 1–3 |
| Cutting board | 1 pizza | 1–2 |
| Dispatch counter | 1 box | 1–3 |

A player may have enough time but fail because the production line becomes blocked.

---

# 6. Controls

## Tap actions

- Tap order card: highlight required recipe.
- Tap ingredient: add it to selected pizza.
- Tap oven: remove nearest ready pizza.
- Tap boxed order: dispatch to matching customer.
- Tap trash: discard incorrect pizza.

## Drag actions

- Drag dough onto preparation counter.
- Drag pizza from prep to oven.
- Drag cooked pizza from oven to cutting board.
- Drag boxed pizza to customer or delivery rider.

## Gesture constraints

- No pinch.
- No rotation gesture.
- No multi-touch dependency.
- No tiny targets.
- Drag paths should snap generously to valid stations.
- Invalid drops animate back to their previous position.

### Touch tolerance

Interactive targets should have invisible hit areas larger than their visible sprites. The touch system should choose the nearest valid object when two hit regions overlap.

---

# 7. Recipe System

## MVP recipes

Begin with six ingredients and six recipes.

### Ingredients

```swift
enum IngredientID: String, Codable, CaseIterable {
    case dough
    case sauce
    case cheese
    case pepperoni
    case mushroom
    case olive
}
```

### Recipes

| Recipe | Required ingredients | Difficulty |
|---|---|---:|
| Cheese | Sauce, cheese | 1 |
| Pepperoni | Sauce, cheese, pepperoni | 1 |
| Mushroom | Sauce, cheese, mushroom | 1 |
| Olive | Sauce, cheese, olive | 1 |
| Pepperoni Mushroom | Sauce, cheese, pepperoni, mushroom | 2 |
| Supreme | Sauce, cheese, pepperoni, mushroom, olive | 3 |

## Recipe data

Recipes should be data-driven rather than hard-coded into the scene.

```swift
struct RecipeDefinition: Identifiable, Codable, Hashable {
    let id: String
    let displayName: String
    let requiredIngredients: [IngredientID]
    let preparationDuration: TimeInterval
    let baseBakeDuration: TimeInterval
    let baseReward: Int
    let difficulty: Int
}
```

Store default content in bundled JSON:

```text
Resources/GameData/recipes.json
```

This allows additional foods and restaurants to be added without rewriting gameplay code.

---

# 8. Pizza State Machine

Every pizza should be an entity with an explicit state.

```swift
enum PizzaState: Equatable {
    case dough
    case preparing
    case assembled
    case baking(progress: Double)
    case undercooked
    case perfectlyCooked
    case overcooked
    case burned
    case slicing
    case boxed
    case delivered
    case discarded
}
```

## Valid transitions

```text
Dough
  → Preparing
  → Assembled
  → Baking
  → Undercooked / Perfect / Overcooked / Burned
  → Slicing
  → Boxed
  → Delivered
```

Invalid transitions must be rejected centrally.

Examples:

- A raw pizza cannot be moved to dispatch.
- A boxed pizza cannot return to the oven.
- A burned pizza cannot be delivered.
- Ingredients cannot be added after baking begins.

## Pizza entity

```swift
struct PizzaEntity: Identifiable {
    let id: UUID
    var ingredients: [IngredientID]
    var state: PizzaState
    var station: StationID
    var bakeStartedAt: TimeInterval?
    var quality: Double
    var assignedOrderID: UUID?
}
```

---

# 9. Baking Mechanic

The oven should be the central timing challenge.

## Bake phases

| Progress | State | Result |
|---:|---|---|
| 0–65% | Undercooked | Reduced quality |
| 65–85% | Good | Normal reward |
| 85–100% | Perfect | Bonus reward and combo |
| 100–125% | Overcooked | Reduced tip |
| 125%+ | Burned | Must discard |

The exact ranges must be configurable per level and upgrade state.

## Visual feedback

- Oven color shifts from amber to orange to red.
- Pizza cheese begins bubbling.
- A circular progress ring fills.
- The perfect window produces a subtle pulse.
- Burned state emits smoke and alarm feedback.

## Accessibility

Do not rely only on color:

- Undercooked: single dot indicator
- Ready: checkmark
- Perfect: star pulse
- Overcooked: exclamation mark
- Burned: smoke icon

---

# 10. Order and Customer System

## Order model

```swift
struct CustomerOrder: Identifiable {
    let id: UUID
    let recipeID: String
    let createdAt: TimeInterval
    let patienceDuration: TimeInterval
    let baseReward: Int
    var status: OrderStatus
}

enum OrderStatus: Equatable {
    case waiting
    case preparing
    case ready
    case delivered
    case expired
}
```

## Customer patience

Patience should decline continuously.

```text
100–60%: Happy
60–30%: Neutral
30–1%: Frustrated
0%: Leaves
```

Customer emotional state affects:

- Tip percentage
- Visual expression
- Audio cue
- Combo eligibility

## Order generation

The level definition controls:

- Allowed recipes
- Maximum simultaneous customers
- Minimum and maximum spawn delay
- Patience multiplier
- Recipe difficulty weighting
- Rush-wave timings

Example:

```json
{
  "id": "level_08",
  "duration": 75,
  "targetRevenue": 500,
  "allowedRecipes": [
    "cheese",
    "pepperoni",
    "mushroom"
  ],
  "maxConcurrentOrders": 3,
  "spawnInterval": {
    "minimum": 3.5,
    "maximum": 6.0
  },
  "rushWaves": [
    {
      "startsAt": 25,
      "duration": 12,
      "spawnMultiplier": 1.6
    }
  ]
}
```

---

# 11. Scoring and Economy

## Order reward

```text
Final Reward =
Base Recipe Value
× Quality Multiplier
× Patience Multiplier
× Combo Multiplier
+ Perfect Bake Bonus
```

### Suggested multipliers

| Condition | Multiplier |
|---|---:|
| Perfect quality | 1.25 |
| Good quality | 1.00 |
| Undercooked | 0.70 |
| Overcooked | 0.60 |
| Customer happy | 1.20 |
| Customer neutral | 1.00 |
| Customer frustrated | 0.60 |

## Combo system

A combo increments when the player:

- Delivers the correct recipe
- Delivers before patience reaches 30%
- Does not burn or discard a pizza between successful orders

Suggested combo values:

```text
Orders 1–2: 1.0×
Orders 3–4: 1.2×
Orders 5–7: 1.4×
Orders 8+: 1.6×
```

The combo should be capped to prevent economy inflation.

## Level stars

| Stars | Requirement |
|---|---|
| 1 | Reach minimum objective |
| 2 | Reach secondary score threshold |
| 3 | Reach mastery threshold |

The player always unlocks the next level with one star.

---

# 12. Progression Structure

## World 1: Corner Pizzeria

- 15 levels
- Cheese, pepperoni, mushroom
- One prep station
- One oven
- Basic customers
- Tutorial integrated into first three levels

## World 2: Downtown Rush

- 15 levels
- Olive and combination recipes
- Two concurrent orders
- Rush waves
- Impatient office customers

## World 3: Night Market

- 20 levels
- Supreme pizzas
- Faster ovens
- Larger order queue
- Delivery riders
- Limited counter capacity

For V1, ship the first world plus five challenge levels. Worlds 2 and 3 can be represented as locked “coming soon” locations only when additional content is genuinely planned.

---

# 13. Upgrade System

Upgrades should improve throughput rather than merely increase arbitrary numbers.

## Upgrade categories

### Oven

- Faster baking
- Wider perfect timing window
- Additional oven slot

### Preparation counter

- Additional preparation slot
- Faster ingredient placement
- Mistake-protection indicator

### Cutting station

- Faster slicing
- Additional cutting board
- Automatic slice at highest tier

### Delivery counter

- Additional box capacity
- Larger patience recovery
- Higher tips

### Ingredient equipment

- Faster sauce animation
- Larger ingredient hit regions
- Higher perfect-assembly tolerance

## Upgrade model

```swift
struct UpgradeDefinition: Identifiable, Codable {
    let id: String
    let category: UpgradeCategory
    let level: Int
    let coinCost: Int
    let effects: [UpgradeEffect]
}

enum UpgradeEffect: Codable {
    case durationMultiplier(Double)
    case capacityIncrease(Int)
    case qualityBonus(Double)
    case rewardMultiplier(Double)
    case perfectWindowIncrease(Double)
}
```

All upgrade effects should be calculated through a single `UpgradeResolver` rather than read from UI state.

---

# 14. Screen Flow

```text
Launch
  ↓
Studio Logo
  ↓
Main Menu
  ├── Play
  ├── Upgrades
  ├── Restaurant Map
  ├── Daily Reward
  ├── Settings
  └── Game Center
       ↓
Level Select
       ↓
Pre-Level Goals
       ↓
Gameplay
       ├── Pause
       ├── Rewarded Boost
       └── Resume
       ↓
Results
       ├── Next Level
       ├── Retry
       ├── Double Coins
       └── Upgrade
```

## Main menu

Display:

- Kitchen diorama
- Current restaurant
- Coin balance
- Play button
- Upgrade button
- Daily reward badge
- Settings
- Game Center

Avoid a grid of generic rectangular buttons. Use the kitchen itself as navigation where practical.

## Pre-level screen

Display:

- Level number
- Objective
- Allowed recipes
- New mechanic, when applicable
- Best score
- Play button
- Optional booster selection

## Gameplay HUD

Top region:

```text
[Pause]       [Shift Timer]       [Coins]
```

Below:

```text
Customer order cards
```

Center:

```text
Isometric kitchen
```

Bottom:

```text
Ingredient tray / context actions
```

## Results

Display:

- Stars earned
- Revenue
- Perfect pizzas
- Best combo
- Coins earned
- New record
- Retry
- Continue
- Double-coins rewarded-ad option

---

# 15. Visual Direction

## Palette

Do not use the common teal-purple hyper-casual palette.

### Proposed palette

| Role | Color |
|---|---|
| Tomato red | `#D94A32` |
| Baked crust | `#D99B52` |
| Warm cream | `#FFF2D9` |
| Olive green | `#66733D` |
| Oven charcoal | `#332C29` |
| Ceramic blue | `#4D7594` |
| Mozzarella | `#F6E6B4` |
| Success gold | `#F1B942` |

## Materials

- Matte painted wood
- Warm terracotta tiles
- Soft ceramic dishes
- Slightly glossy cheese
- Dark iron oven
- Paper pizza boxes
- Avoid excessive gradients and neon glows

## Character design

Characters are secondary to the kitchen.

- Small stylized busts or order portraits
- Distinct silhouettes
- No dialogue bubbles
- Four facial states
- Limited skeletal animation
- Reusable head/body combinations

## App icon

The icon should feature:

- One pizza
- One action
- One strong silhouette

Recommended composition:

> A pizza sliding out of a compact brick oven with one cheese strand and a small speed streak.

Do not include:

- Text
- Multiple characters
- Coin icons
- Full kitchen scene
- Tiny ingredients
- Generic smiling mascot

---

# 16. Animation Specification

## Ingredient placement

- Ingredient launches from tray.
- Follows a short curved path.
- Rotates 15–30 degrees.
- Lands with a 95% → 110% → 100% scale bounce.
- Produces two or three subtle crumbs or spark particles.

## Dough

- Starts slightly oval.
- Expands to pizza shape.
- Applies a short elastic scale effect.
- Emits a soft flour puff.

## Sauce

Use a spiral mask or animated crop rather than manually placing sauce dots.

## Cheese

Use several reusable cheese particle sprites with deterministic seeded positions. The final visual should be based on recipe data so replay and screenshot tests remain stable.

## Oven

- Door opens over 0.15 seconds.
- Pizza slides in.
- Door closes with slight overshoot.
- Interior glow fades up.
- Ready state pulses every 0.7 seconds.

## Delivery

- Box folds closed.
- Restaurant stamp scales onto lid.
- Box moves toward customer.
- Coins arc toward the HUD balance.
- Combo label briefly expands.

---

# 17. Audio and Haptics

## Sound categories

- Interface
- Ingredient
- Appliance
- Customer
- Success
- Failure
- Music
- Ambient kitchen

## Required effects

- Button tap
- Ingredient drop
- Sauce spread
- Cheese sprinkle
- Oven open
- Oven ready
- Perfect bake
- Burn alarm
- Slice
- Box close
- Delivery
- Coin collection
- Combo increase
- Customer leaves

## Haptic events

Use haptics sparingly:

- Light: ingredient placement
- Medium: oven ready
- Success: perfect pizza
- Warning: overcooked state
- Error: burned pizza
- Success: level completion

The gameplay engine should request semantic haptic events through a protocol rather than directly invoking platform APIs.

```swift
protocol HapticProviding {
    func play(_ event: GameHaptic)
}
```

---

# 18. Native iOS Technology Stack

## Recommended stack

| Area | Technology |
|---|---|
| App shell | SwiftUI |
| Gameplay rendering | SpriteKit |
| Gameplay host | `SpriteView` |
| Game state | Observation framework |
| Persistence | SwiftData |
| Audio | AVAudioEngine or AVAudioPlayer |
| Haptics | SwiftUI sensory feedback / Core Haptics where justified |
| Purchases | StoreKit 2 |
| Leaderboards | GameKit / Game Center |
| Ads | Google Mobile Ads SDK behind an adapter |
| Analytics | TelemetryDeck, Firebase Analytics, or custom abstraction |
| Crash reporting | Xcode Organizer plus optional Firebase Crashlytics |
| Configuration | Bundled JSON initially |
| Tests | Swift Testing / XCTest |

StoreKit provides Swift-native APIs for product discovery, purchasing, entitlement status, transaction handling, and testing through Xcode and the App Store sandbox. 

Game Center supports score leaderboards and achievements, including system-provided and custom interfaces. 

---

# 19. Architecture

Use a **SwiftUI application shell with a deterministic SpriteKit gameplay domain**.

```text
SwiftUI Screens
      ↓
AppStore / Navigation State
      ↓
GameSessionController
      ↓
Gameplay Domain
      ↓
SpriteKit Scene Renderer
```

The SpriteKit scene must not own progression, purchases, economy persistence, or navigation.

## Layers

### Presentation layer

- SwiftUI screens
- SpriteKit nodes
- HUD
- Animations
- User input mapping

### Application layer

- Start level
- Pause level
- Complete order
- Complete level
- Apply reward
- Purchase upgrade
- Claim ad reward

### Domain layer

- Pizza state machine
- Orders
- Level rules
- Scoring
- Economy
- Progression
- Upgrades

### Infrastructure layer

- SwiftData repository
- StoreKit
- Ads
- Game Center
- Analytics
- Audio
- Haptics

---

# 20. Core Runtime Types

## Application state

```swift
@MainActor
@Observable
final class AppStore {
    enum Route: Equatable {
        case launch
        case mainMenu
        case levelSelect
        case preLevel(levelID: String)
        case gameplay(levelID: String)
        case results(LevelResult)
        case upgrades
        case settings
    }

    var route: Route = .launch
    var playerProfile: PlayerProfile
    var settings: GameSettings
}
```

## Game session controller

```swift
@MainActor
@Observable
final class GameSessionController {
    private(set) var snapshot: GameSnapshot
    private(set) var status: SessionStatus = .idle

    private let engine: GameEngine
    private let clock: GameClock
    private let eventSink: GameEventSink

    func start(level: LevelDefinition)
    func pause()
    func resume()
    func update(deltaTime: TimeInterval)
    func handle(_ command: PlayerCommand)
}
```

## Player commands

```swift
enum PlayerCommand {
    case selectPizza(UUID)
    case addIngredient(IngredientID, to: UUID)
    case movePizza(UUID, to: StationID)
    case removePizzaFromOven(UUID)
    case slicePizza(UUID)
    case deliverPizza(UUID, to: UUID)
    case discardPizza(UUID)
    case activateBooster(BoosterID)
}
```

## Game events

```swift
enum GameEvent {
    case orderSpawned(CustomerOrder)
    case ingredientAdded(pizzaID: UUID, ingredient: IngredientID)
    case pizzaEnteredOven(UUID)
    case pizzaReachedPerfectBake(UUID)
    case pizzaBurned(UUID)
    case orderDelivered(OrderDeliveryResult)
    case orderExpired(UUID)
    case comboChanged(Int)
    case currencyEarned(Int)
    case levelCompleted(LevelResult)
}
```

The engine emits semantic events. The scene converts them into visual animation, audio, haptics, and HUD updates.

---

# 21. Deterministic Game Engine

Gameplay logic should use a fixed simulation step.

```swift
let fixedStep: TimeInterval = 1.0 / 60.0
```

The renderer may vary between frame rates, but simulation results should remain stable.

## Benefits

- Repeatable tests
- Easier balancing
- Reliable timers
- Reduced device-specific behavior
- Easier playback and debugging
- Possible future replay system

## Clock abstraction

```swift
protocol GameClock {
    var currentTime: TimeInterval { get }
}
```

Tests use a manually advanced clock rather than waiting in real time.

---

# 22. SpriteKit Scene Structure

```text
PizzaRushScene
├── backgroundLayer
├── floorLayer
├── stationLayer
│   ├── prepStationNode
│   ├── ovenNode
│   ├── cuttingNode
│   └── dispatchNode
├── entityLayer
│   ├── pizzaNodes
│   ├── ingredientNodes
│   └── customerNodes
├── effectLayer
│   ├── particles
│   ├── scorePopups
│   └── dragIndicators
├── worldHUDLayer
└── debugLayer
```

SwiftUI should render primary menus and results screens. The active gameplay HUD may be:

- Entirely SpriteKit for simple synchronization, or
- A SwiftUI overlay for accessibility and scalable text

Recommended split:

- Kitchen, entities, particles: SpriteKit
- Timer, score, pause, order cards: SwiftUI overlay
- Contextual station labels: SpriteKit

---

# 23. Depth Sorting

For isometric scenes:

```swift
node.zPosition = baseLayer - node.position.y
```

Use separate broad z-ranges:

```text
Floor: 0–999
Stations: 1,000–1,999
Entities: 2,000–9,999
Effects: 10,000–19,999
HUD: 20,000+
```

Do not continuously reorder the entire node graph. Recalculate movable entity depth only when position changes.

---

# 24. Asset Pipeline

## Asset structure

```text
Assets.xcassets
├── Branding
├── Environment
│   ├── Kitchen
│   ├── Oven
│   ├── PrepCounter
│   └── Decorations
├── Food
│   ├── Dough
│   ├── Sauce
│   ├── Cheese
│   └── Toppings
├── Customers
├── UI
├── Particles
└── AppIcon
```

## Source assets outside the Xcode catalog

```text
Design/
├── Figma/
├── Blender/
├── Procreate/
├── SourceTextures/
└── ExportScripts/
```

## Export rules

- Use consistent isometric camera angle.
- Keep one logical point scale.
- Export `1x`, `2x`, and `3x` where appropriate.
- Trim transparent padding.
- Preserve predictable anchor points.
- Maintain a manifest containing logical size and anchor.
- Build texture atlases by functional group.

Do not package every ingredient into one enormous atlas. Separate frequently used gameplay textures from menu and world-map assets.

---

# 25. Content Configuration

```text
GameData/
├── recipes.json
├── ingredients.json
├── levels_world_1.json
├── upgrades.json
├── economy.json
├── achievements.json
└── localization.json
```

## Validation

Create a development-only content validator that checks:

- Unique IDs
- Referenced recipes exist
- Ingredient assets exist
- Level targets are positive
- Upgrade tiers are sequential
- Prices do not decrease accidentally
- Every level has at least one permitted recipe
- Every recipe has at least one topping combination

Fail builds in debug or CI when configuration is invalid.

---

# 26. Persistence

Use SwiftData for:

- Player progress
- Level records
- Upgrades
- Currency balance
- Settings
- Daily reward state
- Purchase entitlements cache
- Tutorial completion
- Analytics consent state

## Suggested models

```swift
@Model
final class PlayerProfileRecord {
    @Attribute(.unique) var id: String
    var coins: Int
    var highestUnlockedLevel: Int
    var totalOrdersCompleted: Int
    var totalPerfectPizzas: Int
    var bestCombo: Int
    var createdAt: Date
    var lastPlayedAt: Date
}
```

```swift
@Model
final class LevelProgressRecord {
    @Attribute(.unique) var levelID: String
    var stars: Int
    var bestScore: Int
    var bestRevenue: Int
    var bestCombo: Int
    var completionCount: Int
}
```

## Save policy

Save after:

- Level completion
- Purchase
- Upgrade
- Daily reward claim
- Settings change

Do not write to persistent storage every frame or after every coin animation.

---

# 27. Monetization Design

## Rewarded ads

Rewarded ads are user-initiated ads that provide an in-game reward after completion. 

Recommended placements:

### Double level coins

- Offered on results screen
- Once per completed level
- Reward granted only after verified completion callback

### Instant oven

- Immediately completes one active oven slot
- Maximum once per level
- Not offered during the tutorial

### Continue shift

- Adds 20 seconds
- Only after a near-success failure
- Maximum once per level

### Rush-hour booster

- Temporarily improves customer patience
- Optional pre-level reward

## Interstitial ads

Use only after natural transitions:

- Never during active gameplay
- Never after every level
- Never after a rewarded ad
- Never during the first several levels
- Never immediately after an app launch

Suggested rule:

```text
Eligible after every 3 completed levels,
subject to a minimum 180-second cooldown.
```

## Banner ads

Do not place banners over gameplay. They reduce usable portrait space and make the product feel low quality.

A banner may be tested on:

- Upgrade screen
- Level-selection map

The initial release can omit banners entirely.

## In-app purchases

### Remove Ads

One-time non-consumable.

Effects:

- Removes interstitials
- Removes banners
- Rewarded ads remain optional
- Grants a small coin bonus

### Starter Pack

One-time purchase:

- Ad removal
- Coin package
- Cosmetic oven skin

Avoid subscriptions for this product.

## Ad abstraction

```swift
protocol AdServing {
    func preloadRewarded(_ placement: RewardedPlacement) async
    func showRewarded(_ placement: RewardedPlacement) async -> RewardedAdResult
    func preloadInterstitial() async
    func showInterstitialIfEligible(context: InterstitialContext) async
}
```

The game engine must never import the advertising SDK.

Use test ad identifiers during development and remove test-device configuration before release. 

---

# 28. Economy Balancing

## Currency sources

- Level completion
- Star bonus
- Perfect pizza
- Daily reward
- Achievement
- Rewarded ad
- Optional purchase

## Currency sinks

- Equipment upgrades
- Restaurant cosmetics
- Box skins
- Oven skins
- Ingredient tray themes
- Optional booster purchase

## Initial economy target

- First upgrade after 2–3 levels
- Major capacity upgrade after 8–10 levels
- Player can buy something meaningful every 5–8 minutes
- No mandatory ad viewing
- No progression wall during World 1

Example costs:

| Upgrade tier | Cost |
|---|---:|
| Tier 1 | 250 coins |
| Tier 2 | 700 coins |
| Tier 3 | 1,800 coins |
| Tier 4 | 4,500 coins |
| Tier 5 | 10,000 coins |

Do not finalize economy values until automated simulation has evaluated level rewards and progression pacing.

---

# 29. Tutorial

Tutorial instructions should be contextual and interactive.

## Level 1

- Tap dough
- Tap sauce
- Tap cheese
- Drag pizza to oven
- Wait for ready state
- Drag to cutting board
- Drag to customer

## Level 2

- Introduce pepperoni
- Introduce customer patience
- Allow one non-fatal mistake

## Level 3

- Introduce simultaneous orders
- Introduce combo
- Introduce oven timing quality

## Tutorial rules

- Pause timers while instructional overlay is visible.
- Spotlight only the valid target.
- Ignore unrelated touches.
- Store each tutorial step independently.
- Provide “Skip Tutorial” in pause settings.
- Never show monetization during tutorial levels.

---

# 30. Difficulty Progression

Difficulty should increase along separate axes:

- More recipes
- More simultaneous customers
- Faster spawn rate
- Shorter patience
- Smaller perfect-bake window
- Limited station capacity
- Higher target score
- Rush waves
- VIP orders
- Temporary station malfunction

Do not increase all axes simultaneously.

Example progression:

| Levels | Main learning |
|---|---|
| 1–3 | Basic production |
| 4–6 | Multiple recipes |
| 7–9 | Two simultaneous orders |
| 10–12 | Oven timing |
| 13–15 | Rush waves |
| 16–20 | Capacity planning |

---

# 31. Game Center

## Leaderboards

Recommended leaderboards:

- Highest single-level revenue
- Best endless-shift score
- Longest perfect combo
- Weekly revenue challenge

## Achievements

Examples:

| Achievement | Requirement |
|---|---|
| First Slice | Deliver first pizza |
| Perfect Crust | Complete first perfect bake |
| Rush Rookie | Complete 25 orders |
| Oven Master | Complete 100 perfect bakes |
| No Waste | Finish a level without discarding |
| Full House | Manage four active orders |
| Pizza Empire | Earn 100 total stars |

Authenticate silently at launch and avoid blocking the main menu when Game Center is unavailable.

---

# 32. Analytics

Define a provider-neutral API.

```swift
protocol AnalyticsTracking {
    func track(_ event: AnalyticsEvent)
    func setUserProperty(_ value: String?, for key: String)
}
```

## Essential events

```text
app_opened
tutorial_started
tutorial_step_completed
tutorial_completed
level_started
level_completed
level_failed
order_created
order_delivered
order_expired
pizza_burned
upgrade_purchased
rewarded_ad_offered
rewarded_ad_started
rewarded_ad_completed
rewarded_ad_failed
interstitial_presented
iap_started
iap_completed
iap_failed
settings_changed
```

## Required event properties

```text
level_id
session_id
recipe_id
order_count
score
revenue
stars
duration_seconds
failure_reason
upgrade_state
ad_placement
player_progression
```

Do not log names, email addresses, precise location, ingredient drag paths, or raw device identifiers.

## Product metrics

### Acquisition

- Install to tutorial start
- Tutorial completion
- First level completion

### Retention

- Day 1
- Day 3
- Day 7
- Sessions per player
- Levels per session

### Engagement

- Median session duration
- Retry rate
- Orders per session
- Upgrade purchase rate
- Level drop-off

### Monetization

- Rewarded ad opt-in rate
- Rewarded ad completion rate
- Interstitial impressions per daily active user
- Ad revenue per daily active user
- Ad-removal conversion

---

# 33. Performance Requirements

## Targets

- 60 FPS on supported devices
- Gameplay memory under approximately 250 MB
- Main-menu launch under 2 seconds on recent devices
- Gameplay scene ready within 1 second after asset warm-up
- No synchronous disk access during gameplay
- No repeated texture decoding
- No more than a small number of live particle emitters
- No dropped inputs during coin or completion effects

`SpriteView` supports configurable frame rate, culling options, and development debug overlays such as FPS, node count, and draw count. 

## Optimization rules

- Preload gameplay texture atlases.
- Reuse pizza and particle nodes through object pools.
- Reuse audio players.
- Avoid creating formatters in update loops.
- Batch HUD changes.
- Use sprite sheets for repeated frame animation.
- Remove off-screen effect nodes.
- Pause scene updates when app is inactive.
- Profile real devices, not only Simulator.

---

# 34. Accessibility

## Required support

- Dynamic Type for SwiftUI screens
- VoiceOver labels for menu and HUD controls
- Reduced-motion mode
- Color-independent oven timing indicators
- Haptic toggle
- Music and effects volume controls
- High-contrast order cards
- Left-handed layout option if testing supports the need
- Pause available at all times
- No essential information communicated exclusively by sound

## Gameplay accessibility mode

Optional assist mode:

- Larger ingredient targets
- Longer customer patience
- Wider perfect bake window
- Slower order generation

Assist mode should not disable progression or punish the player.

---

# 35. Privacy and ATT

The initial design should avoid unnecessary tracking.

## Preferred approach

- Contextual or non-personalized ads by default where practical
- No account creation
- No contacts
- No camera
- No microphone
- No precise location
- No custom user profile
- No cross-device identity

Whether App Tracking Transparency authorization is required depends on the final advertising and analytics SDK configuration. The privacy manifest and App Store privacy declarations must be based on actual SDK behavior at submission time, not assumptions.

---

# 36. Testing Strategy

## Domain unit tests

Test:

- Recipe matching
- Invalid ingredients
- State transitions
- Bake timing boundaries
- Order expiration
- Combo increments and reset
- Reward calculation
- Level star thresholds
- Upgrade effects
- Currency transactions
- Continue-shift rules
- Daily reward date handling

Example:

```swift
@Test
func perfectPizzaReceivesQualityBonus() {
    let result = ScoreCalculator.calculate(
        baseReward: 100,
        quality: .perfect,
        patienceRemaining: 0.80,
        combo: 4
    )

    #expect(result.total > 100)
}
```

## Simulation tests

Simulate thousands of sessions using scripted players:

- Perfect player
- Average player
- Slow player
- Random player
- Player that ignores oven
- Player that prioritizes cheapest recipes

Use the results to detect:

- Impossible levels
- Economy inflation
- Difficulty spikes
- Excessive idle time
- Unreachable three-star thresholds

## Scene tests

- Node layout at common iPhone aspect ratios
- Valid drag target resolution
- Entity depth ordering
- Touch target size
- Animation completion callbacks
- Pause and resume
- Background and foreground transitions

## UI tests

- New player onboarding
- Level completion
- Upgrade purchase
- Rewarded-ad failure fallback
- Restore purchases
- Offline launch
- Game Center unavailable
- Corrupted local save recovery

## StoreKit tests

Use an Xcode StoreKit configuration for:

- Successful purchase
- Cancelled purchase
- Pending transaction
- Interrupted purchase
- Restore purchase
- Revoked entitlement

---

# 37. Repository Structure

```text
PizzaRush/
├── PizzaRush.xcodeproj
├── App/
│   ├── PizzaRushApp.swift
│   ├── AppStore.swift
│   ├── AppRouter.swift
│   └── DependencyContainer.swift
├── Features/
│   ├── Launch/
│   ├── MainMenu/
│   ├── LevelSelect/
│   ├── PreLevel/
│   ├── Gameplay/
│   ├── Results/
│   ├── Upgrades/
│   ├── Settings/
│   └── Store/
├── Game/
│   ├── Domain/
│   │   ├── Entities/
│   │   ├── ValueTypes/
│   │   ├── StateMachines/
│   │   ├── Scoring/
│   │   ├── Economy/
│   │   └── Rules/
│   ├── Application/
│   │   ├── GameEngine.swift
│   │   ├── GameSessionController.swift
│   │   ├── PlayerCommand.swift
│   │   └── GameEvent.swift
│   ├── Rendering/
│   │   ├── PizzaRushScene.swift
│   │   ├── SceneCoordinator.swift
│   │   ├── Nodes/
│   │   ├── Effects/
│   │   ├── Input/
│   │   └── NodePools/
│   └── Content/
│       ├── ContentLoader.swift
│       ├── ContentValidator.swift
│       └── Definitions/
├── Services/
│   ├── Ads/
│   ├── Analytics/
│   ├── Audio/
│   ├── GameCenter/
│   ├── Haptics/
│   ├── Persistence/
│   ├── Purchases/
│   └── RemoteConfig/
├── Resources/
│   ├── Assets.xcassets
│   ├── Audio/
│   ├── Particles/
│   ├── GameData/
│   └── Localization/
├── Tests/
│   ├── DomainTests/
│   ├── SimulationTests/
│   ├── ServiceTests/
│   └── SnapshotTests/
├── UITests/
├── Scripts/
├── Documentation/
│   ├── GAME_DESIGN.md
│   ├── ARCHITECTURE.md
│   ├── ECONOMY.md
│   ├── CONTENT_GUIDE.md
│   ├── ANALYTICS.md
│   ├── PRIVACY.md
│   ├── QA_PLAN.md
│   └── LIVE_OPS.md
├── APP_STORE_METADATA.md
├── PRIVACY_POLICY.md
├── README.md
└── CHANGELOG.md
```

---

# 38. Dependency Container

Use explicit dependency injection.

```swift
@MainActor
struct DependencyContainer {
    let playerRepository: PlayerRepository
    let levelRepository: LevelRepository
    let purchaseService: PurchaseServing
    let adService: AdServing
    let analytics: AnalyticsTracking
    let audio: AudioPlaying
    let haptics: HapticProviding
    let gameCenter: GameCenterServing
}
```

Avoid:

- Global singleton game state
- Direct SDK calls from SpriteKit nodes
- Static mutable currency values
- NotificationCenter as the primary architecture
- Persistence queries inside the render loop

---

# 39. Error Handling

## Recoverable conditions

### Content loading failure

- Fall back to bundled safe content.
- Record diagnostic event.
- Show no technical error to the player.

### Save failure

- Retain changes in memory.
- Retry after level completion.
- Avoid taking earned currency away.

### Ad unavailable

- Disable ad button or show “Reward unavailable.”
- Never leave the player in a loading state.
- Never grant the reward before confirmed completion.

### Purchase pending

- Display pending status.
- Do not unlock until entitlement is verified.

### Game Center unavailable

- Hide or disable leaderboard surfaces.
- Continue normal gameplay.

---

# 40. Build Phases

## Phase 0 — Product lock

**Duration:** 0.5–1 day

Deliver:

- Final core mechanic
- Screen map
- Six recipes
- Level schema
- Visual references
- Asset list
- Monetization limits
- MVP acceptance criteria

## Phase 1 — Vertical slice

**Duration:** 3–5 days

Deliver:

- Main menu
- One playable level
- One prep station
- One oven
- One cutting board
- Three recipes
- Order queue
- Customer patience
- Score
- Win and loss
- Basic audio and haptics
- Local persistence

Exit criteria:

- Full session playable repeatedly
- No developer controls required
- Stable 60 FPS on target device
- A new player understands the flow

## Phase 2 — App Store MVP

**Duration:** 5–8 additional days

Deliver:

- 20–30 levels
- Six recipes
- Upgrade system
- Results and progression
- Tutorial
- Rewarded ads
- Interstitial eligibility
- Remove Ads purchase
- Game Center
- Analytics
- Settings
- App lifecycle handling
- App icon and screenshots
- Store metadata
- QA pass

## Phase 3 — Commercial polish

**Duration:** 2–3 additional weeks

Deliver:

- 50+ balanced levels
- More customer types
- Daily reward
- Challenges
- Improved art and audio
- Automated economy simulation
- Remote configuration
- Localization
- Retention analysis
- Performance profiling
- Accessibility pass
- App Store optimization variants

---

# 41. Five-Day Prototype Schedule

## Day 1 — Engine and scene

- Create project
- Establish app architecture
- Create level and recipe models
- Build kitchen scene
- Add stations
- Add pizza entity
- Implement drag system
- Implement fixed-step game loop

## Day 2 — Production pipeline

- Ingredient placement
- Recipe validation
- Pizza state machine
- Oven timing
- Cutting and boxing
- Delivery
- Basic scoring

## Day 3 — Orders and level lifecycle

- Customer queue
- Patience
- Order generation
- Session timer
- Win and fail conditions
- Results screen
- Save best score

## Day 4 — Presentation

- Replace placeholders with initial art
- Add animation
- Add particles
- Add sounds
- Add haptics
- Implement tutorial
- Improve HUD

## Day 5 — Stability

- Device testing
- Timer and lifecycle fixes
- Performance profiling
- Unit tests
- Touch tolerance refinement
- Balance first five levels
- Produce TestFlight build

This five-day version is a prototype, not the full illustrated product.

---

# 42. MVP Acceptance Criteria

The MVP is ready for TestFlight when:

- Player can complete the tutorial without written explanation.
- At least 20 levels are playable.
- Six recipes function correctly.
- All pizza state transitions are validated.
- Gameplay survives pause, background, and resume.
- Progress persists after termination.
- Failed ads do not block progression.
- Purchases can be tested and restored.
- No monetization appears during the tutorial.
- Level completion always saves before navigation.
- No known currency duplication exists.
- No gameplay-blocking crash remains.
- Performance stays stable on the oldest supported test device.
- All third-party SDK privacy declarations are documented.
- App Store metadata and review notes are complete.

---

# 43. App Store Metadata File

Create `APP_STORE_METADATA.md` with at least the following structure.

```markdown
# Pizza Rush — App Store Metadata

## App Information

App Name: Pizza Rush
Subtitle: Bake Fast. Deliver Faster.
Primary Category: Games
Secondary Category: Casual
Content Rights: Developer owns or licenses all content
Pricing: Free
Availability: Initial target markets to be defined

## Promotional Text

Build pizzas, master the oven, and serve every customer before the rush takes over.

## Description

Pizza Rush is a fast one-thumb cooking game where every second counts.

Prepare dough, add toppings, bake pizzas at the perfect temperature, slice each order, and send it to hungry customers. Keep your kitchen moving, upgrade your equipment, and build the fastest pizzeria in town.

Features:
- Fast 30–90 second cooking levels
- Simple drag-and-tap controls
- Multiple recipes and customer types
- Oven timing and perfect-bake bonuses
- Kitchen equipment upgrades
- Score challenges and combos
- Game Center achievements and leaderboards
- Optional rewarded ads

## Keywords

pizza,cooking,restaurant,arcade,casual,time management,food,chef,baking,kitchen

## Categories

Primary: Games
Subcategory: Casual
Secondary recommendation: Simulation

## Age Rating

Expected: 4+
Final questionnaire must be completed from actual game content and advertising behavior.

## In-App Purchases

- Remove Ads
- Starter Pack, if included

## Privacy Policy URL

Required before submission.

## Support URL

Required before submission.

## Marketing URL

Recommended.

## App Privacy

Document actual data collected by:
- Advertising provider
- Analytics provider
- Crash-reporting provider
- StoreKit
- Game Center

## Screenshots

Required scenes:
1. Build Your Pizza
2. Master the Oven
3. Beat the Lunch Rush
4. Upgrade Your Kitchen
5. Become the Fastest Pizzeria

All screenshots must represent real in-game UI.

## App Preview

15–25 seconds:
- Order appears
- Pizza assembled
- Oven perfect timing
- Delivery and combo
- Kitchen upgrade
- Final title frame

## TestFlight Notes

Describe:
- Current content
- Known issues
- Test purchase configuration
- Ad test configuration
- Requested testing scenarios

## App Review Notes

Explain:
- Rewarded-ad placements
- Interstitial frequency rules
- Remove Ads behavior
- How to access upgrades
- How to test Game Center
- Any test purchase details
- No account is required

## Version

Version: 1.0
Build: Managed through CI
Copyright: Current studio entity
```

---

# 44. Recommended V1 Cut Line

## Include

- One restaurant
- 20–30 levels
- Six recipes
- Four station types
- Five equipment upgrades
- One customer queue
- Three customer patience states
- Three objective types
- Rewarded ads
- Limited interstitials
- Remove Ads purchase
- Game Center
- Local persistence
- Basic analytics
- Tutorial
- Full App Store metadata

## Exclude

- Real-time 3D
- Multiplayer
- Accounts
- Cloud save
- User-generated restaurants
- Multiple currencies
- Subscription
- Battle pass
- Complex daily quests
- Seasonal event engine
- More than one restaurant environment
- Character dialogue
- Online backend
- AI-generated recipes at runtime

This cut line preserves the core product while avoiding systems that do not materially improve the first release.

# Final Technical Recommendation

Build Pizza Rush as a **native SwiftUI and SpriteKit game using pre-rendered isometric artwork**. The distinctive production-line mechanic—preparation, oven, cutting, and dispatch capacity—should be the central system. Keep gameplay logic deterministic and independent from SpriteKit, configure levels and recipes through JSON, and isolate advertising, purchases, analytics, persistence, and Game Center behind protocols.

The appropriate delivery target is:

- **Five days:** credible playable prototype
- **Two weeks:** functional App Store MVP
- **Three to five weeks:** commercially presentable V1

The three-to-five-day estimate should not be used for a polished, monetized, content-complete release.