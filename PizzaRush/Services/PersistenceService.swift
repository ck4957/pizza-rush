import Foundation
import Observation
import SwiftData

@Model
final class PlayerProfileRecord {
    @Attribute(.unique) var id: String
    var payload: Data
    var updatedAt: Date

    init(id: String = "primary", payload: Data, updatedAt: Date = .now) {
        self.id = id
        self.payload = payload
        self.updatedAt = updatedAt
    }
}

@MainActor
@Observable
final class PersistenceService {
    enum StorageError: Error {
        case encodingFailed
    }

    @ObservationIgnored private let container: ModelContainer
    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let encoder = JSONEncoder()
    @ObservationIgnored private let decoder = JSONDecoder()

    private(set) var profile: PlayerProfile
    private(set) var lastSaveFailed = false
    private(set) var recoveredCorruptData = false
#if DEBUG
    @ObservationIgnored private var testingSaveFailuresRemaining = 0
#endif

    init(inMemory: Bool = false, corruptPayloadForTesting: Data? = nil) {
        let schema = Schema([PlayerProfileRecord.self])
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: schema, configurations: [fallback])
            lastSaveFailed = true
        }
        context = ModelContext(container)
        if let corruptPayloadForTesting {
            context.insert(PlayerProfileRecord(payload: corruptPayloadForTesting))
            try? context.save()
        }

        let descriptor = FetchDescriptor<PlayerProfileRecord>(
            predicate: #Predicate { $0.id == "primary" }
        )
        if
            let record = try? context.fetch(descriptor).first,
            let decoded = try? decoder.decode(PlayerProfile.self, from: record.payload)
        {
            profile = decoded
        } else {
            let hadRecord = (try? context.fetch(descriptor).first) != nil
            profile = PlayerProfile()
            recoveredCorruptData = hadRecord
            save()
        }
    }

    func complete(_ result: LevelResult) {
        profile.completionCount += 1
        profile.coins += result.coinsEarned
        profile.totalOrdersCompleted += result.customersServed
        profile.totalPerfectPizzas += result.perfectPizzas
        profile.bestCombo = max(profile.bestCombo, result.bestCombo)
        profile.levelStars[result.levelID] = max(profile.levelStars[result.levelID, default: 0], result.stars)
        profile.bestScores[result.levelID] = max(profile.bestScores[result.levelID, default: 0], result.revenue)
        if result.stars > 0 {
            profile.highestUnlockedLevel = max(profile.highestUnlockedLevel, min(20, result.levelNumber + 1))
        }
        save()
    }

    @discardableResult
    func claimDoubleCoins(for result: LevelResult) -> Bool {
        guard !profile.rewardedClaims.contains(result.rewardClaimID) else { return false }
        profile.rewardedClaims.insert(result.rewardClaimID)
        profile.coins += result.coinsEarned
        save()
        return true
    }

    @discardableResult
    func purchaseUpgrade(_ category: UpgradeCategory) -> Bool {
        let current = profile.upgrades[category.rawValue, default: 0]
        guard UpgradeResolver.tierCosts.indices.contains(current) else { return false }
        let cost = UpgradeResolver.tierCosts[current]
        guard profile.coins >= cost else { return false }
        profile.coins -= cost
        profile.upgrades[category.rawValue] = current + 1
        save()
        return true
    }

    func setSettings(_ settings: GameSettings) {
        profile.settings = settings
        save()
    }

    func markTutorialStep(_ id: String) {
        profile.tutorialSteps.insert(id)
        save()
    }

    func cacheRemoveAds(_ active: Bool) {
        profile.removeAdsUnlocked = active
        save()
    }

    func resetProgress() {
        let retainedSettings = profile.settings
        let retainedEntitlement = profile.removeAdsUnlocked
        profile = PlayerProfile(settings: retainedSettings)
        profile.removeAdsUnlocked = retainedEntitlement
        save()
    }

    func prepareScreenshotProfile() {
        profile = PlayerProfile(
            coins: 3_250,
            highestUnlockedLevel: 20,
            totalOrdersCompleted: 48,
            totalPerfectPizzas: 24,
            bestCombo: 8,
            levelStars: Dictionary(
                uniqueKeysWithValues: (1 ... 9).map {
                    (String(format: "level_%02d", $0), min(3, 1 + $0 / 4))
                }
            ),
            bestScores: [:],
            upgrades: [
                UpgradeCategory.oven.rawValue: 1,
                UpgradeCategory.preparation.rawValue: 1
            ],
            tutorialSteps: ["level_1_intro", "level_1_complete"],
            rewardedClaims: [],
            removeAdsUnlocked: false,
            settings: GameSettings(tutorialSkipped: true),
            completionCount: 9
        )
        save()
    }

    func retrySave() {
        save()
    }

#if DEBUG
    func failNextSaveForTesting() {
        testingSaveFailuresRemaining += 1
    }
#endif

    private func save() {
#if DEBUG
        if testingSaveFailuresRemaining > 0 {
            testingSaveFailuresRemaining -= 1
            lastSaveFailed = true
            return
        }
#endif
        do {
            let data = try encoder.encode(profile)
            let descriptor = FetchDescriptor<PlayerProfileRecord>(
                predicate: #Predicate { $0.id == "primary" }
            )
            if let record = try context.fetch(descriptor).first {
                record.payload = data
                record.updatedAt = .now
            } else {
                context.insert(PlayerProfileRecord(payload: data))
            }
            try context.save()
            lastSaveFailed = false
        } catch {
            lastSaveFailed = true
        }
    }
}
