import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class GameSessionController {
    private var engine: GameEngine
    private let audio: AudioPlaying
    private let haptics: HapticProviding

    private(set) var snapshot: GameSnapshot

    init(
        level: LevelDefinition,
        recipes: [RecipeDefinition],
        profile: PlayerProfile,
        audio: AudioPlaying,
        haptics: HapticProviding
    ) {
        let initialEngine = GameEngine(
            level: level,
            recipes: recipes,
            upgrades: UpgradeResolver(levels: profile.upgrades),
            completionOrdinal: profile.completionCount,
            assistMode: profile.settings.assistMode
        )
        engine = initialEngine
        self.audio = audio
        self.haptics = haptics
        snapshot = initialEngine.snapshot
    }

    func start(fixture: String? = nil) {
        engine.start()
        if let fixture {
            engine.configureFixture(fixture)
        }
        snapshot = engine.snapshot
    }

    func advance(by delta: TimeInterval) {
        let before = snapshot
        engine.advance(by: delta)
        snapshot = engine.snapshot
        emitFeedback(from: before, to: snapshot)
    }

    func handle(_ command: PlayerCommand) {
        let before = snapshot
        engine.handle(command)
        snapshot = engine.snapshot
        emitFeedback(from: before, to: snapshot)
    }

    func pause() {
        engine.pause()
        snapshot = engine.snapshot
    }

    func freezeFixture() {
        engine.pause(preserveMessage: true)
        snapshot = engine.snapshot
    }

    func resume() {
        engine.resume()
        snapshot = engine.snapshot
    }

    func selectedRecipe() -> RecipeDefinition? {
        guard let order = snapshot.orders.first else { return nil }
        return engine.recipe(for: order)
    }

    func recipe(for order: CustomerOrder) -> RecipeDefinition? {
        engine.recipe(for: order)
    }

    func bakeQuality(for progress: Double) -> BakeQuality {
        engine.bakeQuality(for: progress)
    }

    func forceComplete() {
        engine.forceCompleteForFixture()
        snapshot = engine.snapshot
    }

    private func emitFeedback(from before: GameSnapshot, to after: GameSnapshot) {
        if after.pizzas.count > before.pizzas.count {
            audio.play(.ingredientDrop)
            haptics.play(.light)
        }
        if after.perfectPizzas > before.perfectPizzas {
            audio.play(.perfectBake)
            haptics.play(.success)
        }
        if after.customersServed > before.customersServed {
            audio.play(.delivery)
            haptics.play(.success)
        }
        if after.combo > before.combo, after.combo >= 3 {
            audio.play(.comboIncrease)
        }
        if after.status == .completed, before.status != .completed {
            audio.play(.levelComplete)
            haptics.play(.success)
        }
        if after.pizzas.contains(where: { $0.state == .burned })
            && !before.pizzas.contains(where: { $0.state == .burned })
        {
            audio.play(.burnAlarm)
            haptics.play(.error)
        }
    }
}

@MainActor
@Observable
final class AppModel {
    enum Route: Equatable {
        case mainMenu
        case levels
        case preLevel(Int)
        case gameplay(Int)
        case results
        case upgrades
        case settings
        case aboutSupport
    }

    let catalog: ContentCatalog
    let persistence: PersistenceService
    let audio: AudioManager
    let haptics: HapticManager
    let gameCenter: GameCenterService
    let analytics: AnalyticsTracking
    let adService: any AdServing

    private(set) var purchaseService: PurchaseService!
    private(set) var route: Route = .mainMenu
    private(set) var session: GameSessionController?
    private(set) var currentResult: LevelResult?
    private(set) var userMessage: String?
    private(set) var rewardedCurrentResult = false
    private(set) var lastInterstitialAt: Date?
    private let launchedAt = Date()
    private var lastTickDate: Date?
    private let processArguments: [String]

    var profile: PlayerProfile { persistence.profile }

    init(processArguments: [String] = ProcessInfo.processInfo.arguments) {
        self.processArguments = processArguments
        catalog = ContentLoader.load()
        let persistentUITest = processArguments.contains("-UITestPersistent")
        let inMemory = !persistentUITest
            && (processArguments.contains("-UITestReset")
                || processArguments.contains("-ScreenshotScenario"))
        persistence = PersistenceService(inMemory: inMemory)
        if processArguments.contains("-UITestResetProfile") {
            persistence.resetProgress()
        }
        audio = AudioManager()
        haptics = HapticManager()
        gameCenter = GameCenterService()
        analytics = NoOpAnalytics()
        adService = processArguments.contains("-AdsUnavailable")
            ? UnavailableAdService()
            : GoogleAdService()

        purchaseService = PurchaseService { [weak self] active in
            self?.persistence.cacheRemoveAds(active)
        }
        applySettings()
    }

    func prepare() async {
        gameCenter.authenticate()
        await adService.prepare()
        await purchaseService.prepare()

        if let scenario = screenshotScenario {
            if !processArguments.contains("-UITestPersistent") {
                persistence.prepareScreenshotProfile()
            }
            if scenario == "upgrade" {
                route = .upgrades
            } else if scenario == "results" {
                startLevel(number: 10, fixture: "results")
                finalizeCompletedSessionIfNeeded()
            } else {
                startLevel(number: scenario == "rush" ? 20 : 1, fixture: scenario)
            }
        }
    }

    func showMainMenu() {
        session = nil
        currentResult = nil
        route = .mainMenu
        audio.play(.buttonTap)
    }

    func showLevels() {
        route = .levels
        audio.play(.buttonTap)
    }

    func showPreLevel(_ number: Int) {
        guard level(number) != nil else { return }
        route = .preLevel(number)
        audio.play(.buttonTap)
    }

    func startLevel(number: Int, fixture: String? = nil) {
        guard let level = level(number), number <= profile.highestUnlockedLevel || fixture != nil else {
            userMessage = "Earn one star on the previous level to unlock this shift."
            return
        }
        let controller = GameSessionController(
            level: level,
            recipes: catalog.recipes,
            profile: profile,
            audio: audio,
            haptics: haptics
        )
        session = controller
        currentResult = nil
        rewardedCurrentResult = false
        lastTickDate = nil
        route = .gameplay(number)
        controller.start(fixture: fixture)
        if fixture != nil {
            controller.freezeFixture()
        }
        analytics.track("level_started", properties: ["level_id": level.id])
    }

    func tick(at date: Date) {
        guard case .gameplay = route, let session else { return }
        defer { lastTickDate = date }
        guard let lastTickDate else { return }
        session.advance(by: min(0.25, max(0, date.timeIntervalSince(lastTickDate))))
        finalizeCompletedSessionIfNeeded()
    }

    func pauseGame() {
        session?.pause()
    }

    func resumeGame() {
        session?.resume()
    }

    func handle(_ command: PlayerCommand) {
        guard tutorialAllows(command) else {
            userMessage = "Follow the highlighted tutorial step."
            haptics.play(.warning)
            return
        }
        let before = session?.snapshot
        session?.handle(command)
        recordTutorialProgress(command: command, before: before, after: session?.snapshot)
        finalizeCompletedSessionIfNeeded()
    }

    func retryLevel() {
        guard let result = currentResult else { return }
        startLevel(number: result.levelNumber)
    }

    func continueToNextLevel() async {
        guard let result = currentResult else { return }
        let elapsedSinceLaunch = Date().timeIntervalSince(launchedAt)
        let elapsedSinceInterstitial = lastInterstitialAt.map { Date().timeIntervalSince($0) }
        if AdEligibilityPolicy.canShowInterstitial(
            completionCount: profile.completionCount,
            levelNumber: result.levelNumber,
            secondsSinceLaunch: elapsedSinceLaunch,
            secondsSinceLastInterstitial: elapsedSinceInterstitial,
            rewardedCurrentResult: rewardedCurrentResult,
            removeAds: profile.removeAdsUnlocked
        ) {
            await adService.showInterstitial()
            lastInterstitialAt = .now
        }
        let next = min(20, result.levelNumber + 1)
        showPreLevel(next)
    }

    func doubleCoins() async {
        guard let result = currentResult else { return }
        guard !profile.rewardedClaims.contains(result.rewardClaimID) else {
            userMessage = "Double Coins already claimed."
            return
        }
        let adResult = await adService.showRewarded()
        if adResult == .earned, persistence.claimDoubleCoins(for: result) {
            rewardedCurrentResult = true
            userMessage = "+\(result.coinsEarned) coins saved."
            audio.play(.coinCollection)
            haptics.play(.success)
        } else {
            userMessage = "Reward unavailable."
        }
    }

    func purchaseUpgrade(_ category: UpgradeCategory) {
        if persistence.purchaseUpgrade(category) {
            userMessage = "\(category.displayName) upgraded."
            audio.play(.coinCollection)
            haptics.play(.success)
        } else {
            userMessage = "Not enough coins or upgrade is complete."
            haptics.play(.warning)
        }
    }

    func updateSettings(_ settings: GameSettings) {
        persistence.setSettings(settings)
        applySettings()
    }

    func resetProgress() {
        persistence.resetProgress()
        userMessage = "Progress reset. Purchases are preserved."
        showMainMenu()
    }

    func clearMessage() {
        userMessage = nil
    }

    func showUpgrades() { route = .upgrades }
    func showSettings() { route = .settings }
    func showAboutSupport() { route = .aboutSupport }

    func level(_ number: Int) -> LevelDefinition? {
        catalog.levels.first { $0.number == number }
    }

    private var screenshotScenario: String? {
        guard
            let index = processArguments.firstIndex(of: "-ScreenshotScenario"),
            processArguments.indices.contains(index + 1)
        else { return nil }
        return processArguments[index + 1]
    }

    private func finalizeCompletedSessionIfNeeded() {
        guard
            currentResult == nil,
            let result = session?.snapshot.result
        else { return }
        persistence.complete(result)
        currentResult = result
        route = .results
        analytics.track(
            result.stars > 0 ? "level_completed" : "level_failed",
            properties: [
                "level_id": result.levelID,
                "score": "\(result.revenue)",
                "stars": "\(result.stars)"
            ]
        )
    }

    private func applySettings() {
        let settings = persistence.profile.settings
        audio.setEnabled(effects: settings.effectsEnabled, music: settings.musicEnabled)
        haptics.setEnabled(settings.hapticsEnabled)
    }

    private func tutorialAllows(_ command: PlayerCommand) -> Bool {
        guard
            !profile.settings.tutorialSkipped,
            profile.tutorialSteps.contains("level_1_intro"),
            !profile.tutorialSteps.contains("level_1_complete"),
            let snapshot = session?.snapshot,
            snapshot.level.number == 1
        else { return true }

        guard let pizza = snapshot.selectedPizzaID.flatMap({ id in
            snapshot.pizzas.first { $0.id == id }
        }) else {
            if case .startPizza = command { return true }
            return false
        }

        switch pizza.state {
        case .preparing:
            if !pizza.ingredients.contains(.sauce) {
                if case let .addIngredient(.sauce, to: id) = command { return id == pizza.id }
            } else if !pizza.ingredients.contains(.cheese) {
                if case let .addIngredient(.cheese, to: id) = command { return id == pizza.id }
            }
            return false
        case .assembled:
            if case let .movePizza(id, to: .oven) = command { return id == pizza.id }
            return false
        case .baking:
            if case let .removePizzaFromOven(id) = command {
                return id == pizza.id
                    && session?.bakeQuality(for: pizza.bakeProgress) == .perfect
            }
            return false
        case .slicing, .undercooked, .perfectlyCooked, .overcooked:
            if case let .slicePizza(id) = command { return id == pizza.id }
            return false
        case .boxed:
            if case let .deliverPizza(id, to: _) = command { return id == pizza.id }
            return false
        case .burned:
            if case let .discardPizza(id) = command { return id == pizza.id }
            return false
        default:
            return false
        }
    }

    private func recordTutorialProgress(
        command: PlayerCommand,
        before: GameSnapshot?,
        after: GameSnapshot?
    ) {
        guard
            !profile.settings.tutorialSkipped,
            before?.level.number == 1,
            !profile.tutorialSteps.contains("level_1_complete")
        else { return }

        let step: String? = switch command {
        case .startPizza: "dough"
        case .addIngredient(.sauce, to: _): "sauce"
        case .addIngredient(.cheese, to: _): "cheese"
        case .movePizza(_, to: .oven): "oven"
        case .removePizzaFromOven: "bake"
        case .slicePizza: "slice"
        case .deliverPizza: "deliver"
        default: nil
        }
        if let step {
            persistence.markTutorialStep("level_1_\(step)")
        }
        if
            case .deliverPizza = command,
            (after?.customersServed ?? 0) > (before?.customersServed ?? 0)
        {
            persistence.markTutorialStep("level_1_complete")
            userMessage = "Tutorial complete — keep the kitchen moving!"
        }
    }
}
