import XCTest
@testable import PizzaRush

final class GameEngineTests: XCTestCase {
    private func makeEngine(levelNumber: Int = 1) -> GameEngine {
        let catalog = ContentLoader.safeCatalog
        return GameEngine(
            level: catalog.levels[levelNumber - 1],
            recipes: catalog.recipes,
            upgrades: UpgradeResolver(levels: [:]),
            completionOrdinal: 0,
            assistMode: false
        )
    }

    func testCompleteCheeseOrderFollowsProductionOrderAndScores() {
        var engine = makeEngine()
        engine.start()

        let order = try! XCTUnwrap(engine.snapshot.orders.first)
        engine.handle(.startPizza)
        let pizzaID = try! XCTUnwrap(engine.snapshot.selectedPizzaID)
        engine.handle(.addIngredient(.sauce, to: pizzaID))
        engine.handle(.addIngredient(.cheese, to: pizzaID))

        XCTAssertEqual(engine.snapshot.pizzas.first?.state, .assembled)
        engine.handle(.movePizza(pizzaID, to: .oven))
        XCTAssertEqual(engine.snapshot.pizzas.first?.state, .baking)

        for _ in 0 ..< 29 {
            engine.advance(by: 0.25)
        }
        XCTAssertEqual(engine.bakeQuality(for: engine.snapshot.pizzas[0].bakeProgress), .perfect)

        engine.handle(.removePizzaFromOven(pizzaID))
        engine.handle(.slicePizza(pizzaID))
        engine.handle(.deliverPizza(pizzaID, to: order.id))

        XCTAssertEqual(engine.snapshot.customersServed, 1)
        XCTAssertEqual(engine.snapshot.perfectPizzas, 1)
        XCTAssertGreaterThan(engine.snapshot.revenue, 0)
        XCTAssertTrue(engine.snapshot.pizzas.isEmpty)
    }

    func testWrongIngredientCanBeRemovedBeforeBaking() {
        var engine = makeEngine()
        engine.start()
        engine.handle(.startPizza)
        let pizzaID = try! XCTUnwrap(engine.snapshot.selectedPizzaID)

        engine.handle(.addIngredient(.olive, to: pizzaID))
        XCTAssertTrue(engine.snapshot.lastMessage.contains("Wrong topping"))
        engine.handle(.removeIngredient(.olive, from: pizzaID))

        XCTAssertFalse(engine.snapshot.pizzas[0].ingredients.contains(.olive))
        XCTAssertEqual(engine.snapshot.pizzas[0].state, .preparing)
    }

    func testBurnedPizzaCannotAdvanceAndDiscardRestoresOrder() {
        var engine = makeEngine()
        engine.start()
        engine.handle(.startPizza)
        let pizzaID = try! XCTUnwrap(engine.snapshot.selectedPizzaID)
        engine.handle(.addIngredient(.sauce, to: pizzaID))
        engine.handle(.addIngredient(.cheese, to: pizzaID))
        engine.handle(.movePizza(pizzaID, to: .oven))

        for _ in 0 ..< 43 {
            engine.advance(by: 0.25)
        }
        XCTAssertEqual(engine.snapshot.pizzas[0].state, .burned)

        engine.handle(.movePizza(pizzaID, to: .cutting))
        XCTAssertEqual(engine.snapshot.pizzas[0].station, .oven)
        engine.handle(.discardPizza(pizzaID))

        XCTAssertTrue(engine.snapshot.pizzas.isEmpty)
        XCTAssertEqual(engine.snapshot.orders.first?.status, .waiting)
        XCTAssertEqual(engine.snapshot.combo, 0)
    }

    func testPauseStopsWallClockSimulationUntilResume() {
        var engine = makeEngine()
        engine.start()
        engine.advance(by: 0.25)
        let beforePause = engine.snapshot.remainingTime

        engine.pause()
        engine.advance(by: 10)
        XCTAssertEqual(engine.snapshot.remainingTime, beforePause, accuracy: 0.0001)

        engine.resume()
        engine.advance(by: 0.25)
        XCTAssertLessThan(engine.snapshot.remainingTime, beforePause)
    }

    func testCompletionCreatesUniqueDurableRewardClaim() {
        var engine = makeEngine()
        engine.start()
        engine.forceCompleteForFixture(stars: 3)

        let result = try! XCTUnwrap(engine.snapshot.result)
        XCTAssertEqual(result.stars, 3)
        XCTAssertEqual(result.levelID, "level_01")
        XCTAssertEqual(result.rewardClaimID, "level_01-completion-1")
        XCTAssertGreaterThanOrEqual(result.coinsEarned, result.revenue + 75)
    }

    func testAssistModeWidensPerfectWindowAndSlowsPressure() {
        let catalog = ContentLoader.safeCatalog
        var standard = GameEngine(
            level: catalog.levels[6],
            recipes: catalog.recipes,
            upgrades: UpgradeResolver(levels: [:]),
            completionOrdinal: 0,
            assistMode: false
        )
        var assisted = GameEngine(
            level: catalog.levels[6],
            recipes: catalog.recipes,
            upgrades: UpgradeResolver(levels: [:]),
            completionOrdinal: 0,
            assistMode: true
        )

        standard.start()
        assisted.start()
        XCTAssertEqual(standard.bakeQuality(for: 0.82), .good)
        XCTAssertEqual(assisted.bakeQuality(for: 0.82), .perfect)

        for _ in 0 ..< 40 {
            standard.advance(by: 0.25)
            assisted.advance(by: 0.25)
        }
        XCTAssertGreaterThan(
            assisted.snapshot.orders.first?.patienceRemaining ?? 0,
            standard.snapshot.orders.first?.patienceRemaining ?? 0
        )
    }

    func testBakeBoundariesAreExact() {
        let engine = makeEngine()
        XCTAssertEqual(engine.bakeQuality(for: 0), .undercooked)
        XCTAssertEqual(engine.bakeQuality(for: 0.649_999), .undercooked)
        XCTAssertEqual(engine.bakeQuality(for: 0.65), .good)
        XCTAssertEqual(engine.bakeQuality(for: 0.849_999), .good)
        XCTAssertEqual(engine.bakeQuality(for: 0.85), .perfect)
        XCTAssertEqual(engine.bakeQuality(for: 0.999_999), .perfect)
        XCTAssertEqual(engine.bakeQuality(for: 1.0), .overcooked)
        XCTAssertEqual(engine.bakeQuality(for: 1.249_999), .overcooked)
        XCTAssertEqual(engine.bakeQuality(for: 1.25), .burned)
    }

    func testIdenticalCommandsProduceIdenticalSnapshots() {
        var first = makeEngine()
        var second = makeEngine()
        first.start()
        second.start()

        first.handle(.startPizza)
        second.handle(.startPizza)
        let firstID = try! XCTUnwrap(first.snapshot.selectedPizzaID)
        let secondID = try! XCTUnwrap(second.snapshot.selectedPizzaID)
        first.handle(.addIngredient(.sauce, to: firstID))
        second.handle(.addIngredient(.sauce, to: secondID))
        for _ in 0 ..< 12 {
            first.advance(by: 0.25)
            second.advance(by: 0.25)
        }

        XCTAssertEqual(first.snapshot, second.snapshot)
    }
}
