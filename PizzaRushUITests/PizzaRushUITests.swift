import XCTest

@MainActor
final class PizzaRushUITests: XCTestCase {
    private func launch(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestReset", "-AdsUnavailable"] + arguments
        app.launch()
        return app
    }

    func testCleanLaunchNavigatesToFirstLevel() {
        let app = launch()

        XCTAssertTrue(app.buttons["menu.play"].waitForExistence(timeout: 5))
        app.buttons["menu.play"].tap()
        XCTAssertTrue(app.buttons["level.1"].waitForExistence(timeout: 3))
        app.buttons["level.1"].tap()

        XCTAssertTrue(app.staticTexts["Earn 258 coins"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["prelevel.start"].exists)
    }

    func testDeterministicRushFixtureExposesGameplayControls() {
        let app = launch(["-ScreenshotScenario", "rush"])

        XCTAssertTrue(app.buttons["game.pause"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Pepperoni"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Mushroom"].exists)
        XCTAssertTrue(app.buttons["game.startDough"].exists)
        XCTAssertTrue(
            app.staticTexts
                .matching(NSPredicate(format: "label CONTAINS[c] %@", "Production order"))
                .firstMatch
                .waitForExistence(timeout: 3)
        )
    }

    func testDeterministicResultsFixtureShowsUnavailableRewardFallback() {
        let app = launch(["-ScreenshotScenario", "results"])

        XCTAssertTrue(app.staticTexts["Shift Complete!"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["results.continue"].exists)
        XCTAssertTrue(app.buttons["results.retry"].exists)
        XCTAssertTrue(app.buttons["results.doubleCoins"].exists)
        XCTAssertFalse(app.buttons["results.doubleCoins"].isEnabled)
        XCTAssertEqual(app.buttons["results.doubleCoins"].label, "Reward unavailable.")
    }

    func testSettingsAndSupportAreReachable() {
        let app = launch()

        XCTAssertTrue(app.buttons["menu.settings"].waitForExistence(timeout: 5))
        app.buttons["menu.settings"].tap()
        XCTAssertTrue(app.switches["Assist Mode"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["settings.aboutSupport"].exists)
        app.buttons["settings.aboutSupport"].tap()

        XCTAssertTrue(app.staticTexts["Pizza Rush"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Privacy Policy"].exists)
        XCTAssertTrue(app.buttons["Terms of Use"].exists)
    }

    func testCaptureRemoveAdsReviewScreenshot() {
        let app = launch(["-ScreenshotScenario", "removeAds"])

        let removeAds = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Remove Ads")
        ).firstMatch
        XCTAssertTrue(removeAds.waitForExistence(timeout: 5))
        XCTAssertEqual(removeAds.label, "Remove Ads — $4.99")

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "remove-ads-review"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testCompletedResultPersistsAcrossTerminationAndRelaunch() {
        let first = XCUIApplication()
        first.launchArguments = [
            "-UITestPersistent",
            "-UITestResetProfile",
            "-AdsUnavailable",
            "-ScreenshotScenario",
            "results"
        ]
        first.launch()
        XCTAssertTrue(first.staticTexts["Shift Complete!"].waitForExistence(timeout: 5))
        first.terminate()

        let relaunched = XCUIApplication()
        relaunched.launchArguments = ["-UITestPersistent", "-AdsUnavailable"]
        relaunched.launch()

        XCTAssertTrue(relaunched.buttons["menu.play"].waitForExistence(timeout: 5))
        XCTAssertTrue(relaunched.staticTexts["Level 11"].exists)
        XCTAssertTrue(relaunched.staticTexts["726"].exists)
    }

    func testFullSuccessfulLevelWithoutGameplayFixture() {
        let app = launch()
        XCTAssertTrue(app.buttons["menu.play"].waitForExistence(timeout: 5))
        app.buttons["menu.play"].tap()
        app.buttons["level.1"].tap()
        app.buttons["prelevel.start"].tap()
        for _ in 0 ..< 5 {
            let tutorial = app.buttons["tutorial.next"]
            XCTAssertTrue(tutorial.waitForExistence(timeout: 3))
            tutorial.tap()
        }

        completePizza(in: app, toppingIdentifiers: [])
        completePizza(in: app, toppingIdentifiers: ["ingredient.pepperoni"])

        XCTAssertTrue(app.staticTexts["Shift Complete!"].waitForExistence(timeout: 55))
        XCTAssertTrue(app.buttons["results.continue"].exists)
        app.buttons["results.continue"].tap()
        XCTAssertTrue(app.staticTexts["Level 2"].waitForExistence(timeout: 3))
    }

    func testAccessibilityXXXLResultsKeepEveryActionOperable() {
        let app = launch([
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL",
            "-ScreenshotScenario",
            "results"
        ])

        XCTAssertTrue(app.staticTexts["Shift Complete!"].waitForExistence(timeout: 5))
        let continueButton = app.buttons["results.continue"]
        let retryButton = app.buttons["results.retry"]
        let upgradeButton = app.buttons["results.upgrade"]
        XCTAssertTrue(continueButton.exists)
        XCTAssertTrue(retryButton.exists)
        XCTAssertTrue(upgradeButton.exists)

        for _ in 0 ..< 6 where !continueButton.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(continueButton.isHittable)
        XCTAssertTrue(retryButton.isHittable)
    }

    private func completePizza(
        in app: XCUIApplication,
        toppingIdentifiers: [String]
    ) {
        let start = app.buttons["game.startDough"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()

        app.buttons["ingredient.sauce"].tap()
        app.buttons["ingredient.cheese"].tap()
        for identifier in toppingIdentifiers {
            app.buttons[identifier].tap()
        }

        let oven = app.buttons["game.toOven"]
        XCTAssertTrue(oven.waitForExistence(timeout: 3))
        XCTAssertTrue(oven.isEnabled)
        oven.tap()

        XCTAssertTrue(app.staticTexts["Perfect"].waitForExistence(timeout: 10))
        app.buttons["game.removeOven"].tap()
        XCTAssertTrue(app.buttons["game.slice"].waitForExistence(timeout: 3))
        app.buttons["game.slice"].tap()
        XCTAssertTrue(app.buttons["game.deliver"].waitForExistence(timeout: 3))
        app.buttons["game.deliver"].tap()
    }
}
