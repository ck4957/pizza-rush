import Foundation
import GoogleMobileAds
import Observation
import StoreKit
import UIKit
import UserMessagingPlatform

enum AdPlacement: String, Sendable {
    case doubleLevelCoins = "double_level_coins"
    case levelTransition = "level_transition"
}

enum RewardedAdResult: Equatable, Sendable {
    case earned
    case dismissed
    case unavailable
    case failed
}

enum AdConfiguration {
    static let debugAppID = "ca-app-pub-3940256099942544~1458002511"
    static let debugRewardedID = "ca-app-pub-3940256099942544/1712485313"
    static let debugInterstitialID = "ca-app-pub-3940256099942544/4411468910"

    static var rewardedID: String {
#if DEBUG
        debugRewardedID
#else
        Bundle.main.object(forInfoDictionaryKey: "PizzaRushRewardedAdUnitID") as? String ?? ""
#endif
    }

    static var interstitialID: String {
#if DEBUG
        debugInterstitialID
#else
        Bundle.main.object(forInfoDictionaryKey: "PizzaRushInterstitialAdUnitID") as? String ?? ""
#endif
    }

    static var productionReady: Bool {
#if DEBUG
        true
#else
        let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String ?? ""
        let ids = [appID, rewardedID, interstitialID]
        return ids.allSatisfy {
            $0.hasPrefix("ca-app-pub-")
                && !$0.contains("3940256099942544")
                && !$0.contains("0000000000000000")
        }
#endif
    }
}

enum AdEligibilityPolicy {
    static func canShowInterstitial(
        completionCount: Int,
        levelNumber: Int,
        secondsSinceLaunch: TimeInterval,
        secondsSinceLastInterstitial: TimeInterval?,
        rewardedCurrentResult: Bool,
        removeAds: Bool
    ) -> Bool {
        guard !removeAds, !rewardedCurrentResult else { return false }
        guard levelNumber > 3, completionCount > 0, completionCount.isMultiple(of: 3) else {
            return false
        }
        guard secondsSinceLaunch >= 180 else { return false }
        if let secondsSinceLastInterstitial, secondsSinceLastInterstitial < 180 {
            return false
        }
        return true
    }
}

@MainActor
protocol AdServing: AnyObject {
    var isRewardedReady: Bool { get }
    var isPrivacyOptionsRequired: Bool { get }
    func prepare() async
    func showRewarded() async -> RewardedAdResult
    func showInterstitial() async
    func presentPrivacyOptions() async
}

@MainActor
@Observable
final class GoogleAdService: NSObject, AdServing {
    enum Status: Equatable {
        case idle
        case requestingConsent
        case unavailable
        case loading
        case ready
    }

    private(set) var status: Status = .idle
    private(set) var lastErrorDescription: String?
    private var didStartMobileAds = false
    private var rewardedAd: RewardedAd?
    private var interstitialAd: InterstitialAd?
    private var rewardedContinuation: CheckedContinuation<RewardedAdResult, Never>?
    private var rewardEarned = false
    private var presentingRewarded = false

    var isRewardedReady: Bool { rewardedAd != nil }
    var isPrivacyOptionsRequired: Bool {
        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    func prepare() async {
        guard status == .idle, AdConfiguration.productionReady else {
            status = .unavailable
            return
        }
        let requestConfiguration = MobileAds.shared.requestConfiguration
        requestConfiguration.maxAdContentRating = .general
        requestConfiguration.publisherPrivacyPersonalizationState = .disabled

        status = .requestingConsent
        do {
            let parameters = RequestParameters()
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            lastErrorDescription = error.localizedDescription
        }

        guard ConsentInformation.shared.canRequestAds else {
            status = .unavailable
            return
        }
        startMobileAdsOnce()
        await preload()
    }

    func showRewarded() async -> RewardedAdResult {
        guard let rewardedAd else {
            await loadRewarded()
            return .unavailable
        }
        self.rewardedAd = nil
        presentingRewarded = true
        rewardEarned = false

        return await withCheckedContinuation { continuation in
            rewardedContinuation = continuation
            rewardedAd.present(from: topViewController()) { [weak self] in
                self?.rewardEarned = true
            }
        }
    }

    func showInterstitial() async {
        guard let interstitialAd else {
            await loadInterstitial()
            return
        }
        self.interstitialAd = nil
        presentingRewarded = false
        interstitialAd.present(from: topViewController())
    }

    func presentPrivacyOptions() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: topViewController())
        } catch {
            lastErrorDescription = error.localizedDescription
        }
    }

    private func startMobileAdsOnce() {
        guard !didStartMobileAds else { return }
        didStartMobileAds = true
        MobileAds.shared.start()
    }

    private func preload() async {
        status = .loading
        async let rewarded: Void = loadRewarded()
        async let interstitial: Void = loadInterstitial()
        _ = await (rewarded, interstitial)
        status = rewardedAd != nil ? .ready : .unavailable
    }

    private func loadRewarded() async {
        guard ConsentInformation.shared.canRequestAds else { return }
        do {
            let ad = try await RewardedAd.load(with: AdConfiguration.rewardedID, request: Request())
            ad.fullScreenContentDelegate = self
            rewardedAd = ad
        } catch {
            rewardedAd = nil
            lastErrorDescription = error.localizedDescription
        }
    }

    private func loadInterstitial() async {
        guard ConsentInformation.shared.canRequestAds else { return }
        do {
            let ad = try await InterstitialAd.load(
                with: AdConfiguration.interstitialID,
                request: Request()
            )
            ad.fullScreenContentDelegate = self
            interstitialAd = ad
        } catch {
            interstitialAd = nil
            lastErrorDescription = error.localizedDescription
        }
    }

    private func finishRewarded(_ result: RewardedAdResult) {
        rewardedContinuation?.resume(returning: result)
        rewardedContinuation = nil
        presentingRewarded = false
        Task { await loadRewarded() }
    }

    private func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        var controller = scenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}

extension GoogleAdService: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        if presentingRewarded {
            finishRewarded(rewardEarned ? .earned : .dismissed)
        } else {
            Task { await loadInterstitial() }
        }
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        lastErrorDescription = error.localizedDescription
        if presentingRewarded {
            finishRewarded(.failed)
        } else {
            Task { await loadInterstitial() }
        }
    }
}

@MainActor
final class UnavailableAdService: AdServing {
    var isRewardedReady: Bool { false }
    var isPrivacyOptionsRequired: Bool { false }
    func prepare() async {}
    func showRewarded() async -> RewardedAdResult { .unavailable }
    func showInterstitial() async {}
    func presentPrivacyOptions() async {}
}

@MainActor
@Observable
final class PurchaseService {
    static let removeAdsProductID = "com.chiragkular.pizzarush.removeads"

    enum PurchaseState: Equatable {
        case idle
        case loading
        case ready
        case purchasing
        case pending
        case unavailable
        case failed(String)
    }

    private(set) var state: PurchaseState = .idle
    private(set) var removeAdsProduct: Product?
    private(set) var hasRemoveAds = false
    private var updatesTask: Task<Void, Never>?
    private let onEntitlementChanged: (Bool) -> Void

    init(onEntitlementChanged: @escaping (Bool) -> Void) {
        self.onEntitlementChanged = onEntitlementChanged
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard case let .verified(transaction) = update else { continue }
                await transaction.finish()
                await self?.refreshEntitlement()
            }
        }
    }

    func prepare() async {
        state = .loading
        do {
            removeAdsProduct = try await Product.products(for: [Self.removeAdsProductID]).first
            await refreshEntitlement()
            state = removeAdsProduct == nil ? .unavailable : .ready
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func purchaseRemoveAds() async {
        guard let product = removeAdsProduct else {
            state = .unavailable
            return
        }
        state = .purchasing
        do {
            switch try await product.purchase() {
            case let .success(verification):
                guard case let .verified(transaction) = verification else {
                    state = .failed("Purchase could not be verified.")
                    return
                }
                await transaction.finish()
                await refreshEntitlement()
                state = .ready
            case .pending:
                state = .pending
            case .userCancelled:
                state = .ready
            @unknown default:
                state = .failed("Purchase response was not recognized.")
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func restore() async {
        state = .loading
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            state = removeAdsProduct == nil ? .unavailable : .ready
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func refreshEntitlement() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }
            if transaction.productID == Self.removeAdsProductID,
               transaction.revocationDate == nil
            {
                active = true
            }
        }
        hasRemoveAds = active
        onEntitlementChanged(active)
    }
}
