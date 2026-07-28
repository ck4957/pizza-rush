# Pizza Rush Product Design Brief

## Target

Create a portrait iPhone game screen at a 390 × 844 design viewport for a native
SwiftUI and SpriteKit time-management game. The central visual must make the
physical production order obvious within five seconds:

1. Preparation
2. Oven
3. Cutting
4. Dispatch

The player must be able to read the current order, selected pizza, station
capacity, bake state, shift timer, coins, and next valid action without opening
another screen. The ingredient tray and primary drag path must remain reachable
with one thumb.

## Audience and outcome

Pizza Rush serves a general audience of casual arcade and time-management
players. A new player should understand how to assemble and deliver a pizza
without outside instructions, while returning players should see enough
pipeline pressure to optimize overlapping orders.

## Visual language

- Toy-like 2D isometric kitchen with baked-in depth, not real-time 3D.
- Matte painted wood, terracotta tile, ceramic dishes, glossy cheese, dark iron,
  and paper boxes.
- Tomato red, baked crust, warm cream, olive, charcoal, ceramic blue,
  mozzarella, and success gold.
- Strong silhouettes, large hit regions, native iOS hierarchy, and minimal
  text during gameplay.
- No common teal-purple hyper-casual palette, neon glows, generic mascots, or
  grids of rectangular buttons.

## Accessibility constraints

Every meaningful timing state uses shape or icon feedback in addition to color:
dot for undercooked, checkmark for ready, star for perfect, exclamation for
overcooked, and smoke for burned. Interactive targets are at least 44 × 44
points in SwiftUI and use enlarged hit regions in SpriteKit. Reduced Motion
replaces travel, bounce, pulse, and particle-heavy feedback with short fades
and stable state changes.

## Implementation boundary

SwiftUI owns navigation, menus, results, scalable HUD text, and accessibility
actions. SpriteKit owns the kitchen, stations, pizzas, drag feedback, and
particles. The deterministic domain engine owns all scoring, timing,
progression, persistence commands, ad rewards, and valid transitions.

