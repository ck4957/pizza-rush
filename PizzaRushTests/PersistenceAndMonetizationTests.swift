import XCTest
@testable import PizzaRush

@MainActor
final class PersistenceAndMonetizationTests: XCTestCase {
    func testCompletionUnlocksNextLevelAndRewardClaimIsIdempotent() {
        let persistence = PersistenceService(inMemory: true)
        let result = LevelResult(
            levelID: "level_01",
            levelNumber: 1,
            stars: 2,
            revenue: 300,
            customersServed: 3,
            perfectPizzas: 2,
            bestCombo: 3,
            coinsEarned: 350,
            isNewRecord: true,
            rewardClaimID: "level_01-completion-1"
        )

        persistence.complete(result)
        XCTAssertEqual(persistence.profile.highestUnlockedLevel, 2)
        XCTAssertEqual(persistence.profile.levelStars["level_01"], 2)
        XCTAssertEqual(persistence.profile.coins, 350)
        XCTAssertTrue(persistence.claimDoubleCoins(for: result))
        XCTAssertEqual(persistence.profile.coins, 700)
        XCTAssertFalse(persistence.claimDoubleCoins(for: result))
        XCTAssertEqual(persistence.profile.coins, 700)
    }

    func testResetPreservesSettingsAndRemoveAdsEntitlement() {
        let persistence = PersistenceService(inMemory: true)
        var settings = GameSettings()
        settings.assistMode = true
        persistence.setSettings(settings)
        persistence.cacheRemoveAds(true)
        persistence.resetProgress()

        XCTAssertTrue(persistence.profile.settings.assistMode)
        XCTAssertTrue(persistence.profile.removeAdsUnlocked)
        XCTAssertEqual(persistence.profile.coins, 0)
        XCTAssertEqual(persistence.profile.highestUnlockedLevel, 1)
    }

    func testInterstitialFrequencyAndTutorialExclusions() {
        XCTAssertFalse(
            AdEligibilityPolicy.canShowInterstitial(
                completionCount: 3,
                levelNumber: 3,
                secondsSinceLaunch: 300,
                secondsSinceLastInterstitial: nil,
                rewardedCurrentResult: false,
                removeAds: false
            )
        )
        XCTAssertTrue(
            AdEligibilityPolicy.canShowInterstitial(
                completionCount: 3,
                levelNumber: 4,
                secondsSinceLaunch: 300,
                secondsSinceLastInterstitial: nil,
                rewardedCurrentResult: false,
                removeAds: false
            )
        )
        XCTAssertFalse(
            AdEligibilityPolicy.canShowInterstitial(
                completionCount: 3,
                levelNumber: 4,
                secondsSinceLaunch: 300,
                secondsSinceLastInterstitial: 120,
                rewardedCurrentResult: false,
                removeAds: false
            )
        )
        XCTAssertFalse(
            AdEligibilityPolicy.canShowInterstitial(
                completionCount: 3,
                levelNumber: 4,
                secondsSinceLaunch: 300,
                secondsSinceLastInterstitial: nil,
                rewardedCurrentResult: true,
                removeAds: false
            )
        )
        XCTAssertFalse(
            AdEligibilityPolicy.canShowInterstitial(
                completionCount: 3,
                levelNumber: 4,
                secondsSinceLaunch: 300,
                secondsSinceLastInterstitial: nil,
                rewardedCurrentResult: false,
                removeAds: true
            )
        )
    }

    func testDebugConfigurationUsesOnlyOfficialDemoIds() {
        XCTAssertEqual(AdConfiguration.rewardedID, AdConfiguration.debugRewardedID)
        XCTAssertEqual(AdConfiguration.interstitialID, AdConfiguration.debugInterstitialID)
        XCTAssertTrue(AdConfiguration.productionReady)
    }

    func testSaveFailureRetainsEarnedProgressAndRetryRecovers() {
        let persistence = PersistenceService(inMemory: true)
        let result = LevelResult(
            levelID: "level_01",
            levelNumber: 1,
            stars: 1,
            revenue: 258,
            customersServed: 2,
            perfectPizzas: 1,
            bestCombo: 2,
            coinsEarned: 283,
            isNewRecord: true,
            rewardClaimID: "save-failure"
        )

        persistence.failNextSaveForTesting()
        persistence.complete(result)
        XCTAssertTrue(persistence.lastSaveFailed)
        XCTAssertEqual(persistence.profile.coins, 283)
        XCTAssertEqual(persistence.profile.highestUnlockedLevel, 2)

        persistence.retrySave()
        XCTAssertFalse(persistence.lastSaveFailed)
        XCTAssertEqual(persistence.profile.coins, 283)
    }

    func testCorruptProfileRecoversToPlayableSafeState() {
        let persistence = PersistenceService(
            inMemory: true,
            corruptPayloadForTesting: Data("not-json".utf8)
        )

        XCTAssertTrue(persistence.recoveredCorruptData)
        XCTAssertEqual(persistence.profile, PlayerProfile())

        let result = LevelResult(
            levelID: "level_01",
            levelNumber: 1,
            stars: 1,
            revenue: 258,
            customersServed: 2,
            perfectPizzas: 1,
            bestCombo: 2,
            coinsEarned: 283,
            isNewRecord: true,
            rewardClaimID: "after-recovery"
        )
        persistence.complete(result)
        XCTAssertFalse(persistence.lastSaveFailed)
        XCTAssertEqual(persistence.profile.highestUnlockedLevel, 2)
    }
}
