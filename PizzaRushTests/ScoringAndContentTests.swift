import XCTest
@testable import PizzaRush

final class ScoringAndContentTests: XCTestCase {
    func testScoreMultipliersMatchContractBoundaries() {
        XCTAssertEqual(ScoreCalculator.comboMultiplier(for: 0), 1.0)
        XCTAssertEqual(ScoreCalculator.comboMultiplier(for: 3), 1.2)
        XCTAssertEqual(ScoreCalculator.comboMultiplier(for: 5), 1.4)
        XCTAssertEqual(ScoreCalculator.comboMultiplier(for: 8), 1.6)
        XCTAssertEqual(ScoreCalculator.patienceMultiplier(remaining: 0.60), 1.20)
        XCTAssertEqual(ScoreCalculator.patienceMultiplier(remaining: 0.30), 1.00)
        XCTAssertEqual(ScoreCalculator.patienceMultiplier(remaining: 0.29), 0.60)
    }

    func testPerfectRewardAddsQualityAndPerfectBonus() {
        let perfect = ScoreCalculator.reward(
            base: 100,
            quality: .perfect,
            patienceRemaining: 1,
            combo: 3
        )
        let good = ScoreCalculator.reward(
            base: 100,
            quality: .good,
            patienceRemaining: 1,
            combo: 3
        )

        XCTAssertEqual(perfect, 200)
        XCTAssertEqual(good, 144)
    }

    func testBundledFallbackCatalogIsCompleteAndValid() {
        let catalog = ContentLoader.safeCatalog
        XCTAssertEqual(catalog.recipes.count, 6)
        XCTAssertEqual(catalog.levels.count, 20)
        XCTAssertEqual(catalog.levels.map(\.number), Array(1 ... 20))
        XCTAssertTrue(ContentValidator.validate(catalog).isEmpty)
    }

    func testValidatorRejectsMissingRecipeReference() {
        let catalog = ContentCatalog(
            recipes: ContentLoader.safeCatalog.recipes,
            levels: [
                LevelDefinition(
                    id: "broken",
                    number: 1,
                    duration: 60,
                    objective: LevelObjective(kind: .revenue, target: 100),
                    allowedRecipes: ["not_real"],
                    maxConcurrentOrders: 1,
                    spawnInterval: SpawnInterval(minimum: 3, maximum: 5),
                    patienceMultiplier: 1,
                    rushWaves: [],
                    secondaryThreshold: 120,
                    masteryThreshold: 150
                )
            ]
        )

        XCTAssertTrue(
            ContentValidator.validate(catalog).contains(
                .missingRecipe(level: "broken", recipe: "not_real")
            )
        )
    }

    func testStarThresholdEdgesAreExact() {
        XCTAssertEqual(
            StarCalculator.stars(
                achievedValue: 99,
                objectiveTarget: 100,
                secondaryThreshold: 125,
                masteryThreshold: 155
            ),
            0
        )
        XCTAssertEqual(
            StarCalculator.stars(
                achievedValue: 100,
                objectiveTarget: 100,
                secondaryThreshold: 125,
                masteryThreshold: 155
            ),
            1
        )
        XCTAssertEqual(
            StarCalculator.stars(
                achievedValue: 125,
                objectiveTarget: 100,
                secondaryThreshold: 125,
                masteryThreshold: 155
            ),
            2
        )
        XCTAssertEqual(
            StarCalculator.stars(
                achievedValue: 155,
                objectiveTarget: 100,
                secondaryThreshold: 125,
                masteryThreshold: 155
            ),
            3
        )
    }

    func testUpgradeCostsAndCapacitiesAreMonotonic() {
        XCTAssertEqual(UpgradeResolver.tierCosts, [250, 700, 1_800, 4_500, 10_000])
        XCTAssertEqual(UpgradeResolver.tierCosts, UpgradeResolver.tierCosts.sorted())

        let base = UpgradeResolver(levels: [:])
        let upgraded = UpgradeResolver(
            levels: [
                UpgradeCategory.oven.rawValue: 5,
                UpgradeCategory.preparation.rawValue: 5,
                UpgradeCategory.cutting.rawValue: 5,
                UpgradeCategory.delivery.rawValue: 5
            ]
        )
        XCTAssertEqual(base.capacity(for: .oven), 1)
        XCTAssertEqual(upgraded.capacity(for: .oven), 3)
        XCTAssertEqual(upgraded.capacity(for: .prep), 3)
        XCTAssertEqual(upgraded.capacity(for: .cutting), 2)
        XCTAssertEqual(upgraded.capacity(for: .dispatch), 3)
        XCTAssertLessThan(upgraded.bakeDurationMultiplier, base.bakeDurationMultiplier)
        XCTAssertGreaterThan(upgraded.perfectWindowIncrease, base.perfectWindowIncrease)
    }
}
