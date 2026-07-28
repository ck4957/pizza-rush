import SwiftUI

struct ResultsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if let result = model.currentResult {
            ScrollView {
                VStack(spacing: 18) {
                    Text(result.stars > 0 ? "Shift Complete!" : "Rush Missed")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    HStack(spacing: 14) {
                        ForEach(1 ... 3, id: \.self) { star in
                            Image(systemName: star <= result.stars ? "star.fill" : "star")
                                .font(.system(size: 42))
                                .foregroundStyle(Color.pizzaGold)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityLabel("\(result.stars) of 3 stars")
                    .accessibilityIdentifier("results.stars")

                    if result.isNewRecord {
                        Label("New Record", systemImage: "sparkles")
                            .font(.headline)
                            .foregroundStyle(Color.pizzaTomato)
                    }

                    LazyVGrid(columns: resultColumns, spacing: 12) {
                        ResultMetric(title: "Revenue", value: "\(result.revenue)", symbol: "dollarsign.circle.fill")
                        ResultMetric(title: "Perfect Pizzas", value: "\(result.perfectPizzas)", symbol: "star.circle.fill")
                        ResultMetric(title: "Best Combo", value: "\(result.bestCombo)", symbol: "flame.fill")
                        ResultMetric(title: "Coins Earned", value: "\(result.coinsEarned)", symbol: "banknote.fill")
                    }

                    if !model.profile.rewardedClaims.contains(result.rewardClaimID) {
                        Button {
                            Task { await model.doubleCoins() }
                        } label: {
                            Label(
                                model.adService.isRewardedReady ? "Double Coins" : "Reward unavailable.",
                                systemImage: "play.rectangle.fill"
                            )
                        }
                        .buttonStyle(PrimaryGameButton(color: .pizzaGold))
                        .foregroundStyle(Color.pizzaCharcoal)
                        .disabled(!model.adService.isRewardedReady)
                        .accessibilityHint("Optional rewarded advertisement, once for this completed level")
                        .accessibilityIdentifier("results.doubleCoins")
                    } else {
                        Label("Double Coins claimed", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Color.pizzaOlive)
                    }

                    actionLayout {
                        Button("Retry") { model.retryLevel() }
                            .buttonStyle(PrimaryGameButton(color: .pizzaBlue))
                            .accessibilityIdentifier("results.retry")
                        Button("Continue") {
                            Task { await model.continueToNextLevel() }
                        }
                        .buttonStyle(PrimaryGameButton())
                        .accessibilityIdentifier("results.continue")
                    }

                    Button("Upgrade Kitchen") { model.showUpgrades() }
                        .buttonStyle(PrimaryGameButton(color: .pizzaOlive))
                        .accessibilityIdentifier("results.upgrade")

                    Button("Main Menu") { model.showMainMenu() }
                        .frame(minHeight: 44)
                }
                .padding(20)
            }
            .background {
                LinearGradient(
                    colors: [Color.pizzaCream, Color.pizzaCrust.opacity(0.32)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        } else {
            ProgressView()
        }
    }

    private var resultColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible()),
            count: dynamicTypeSize.isAccessibilitySize ? 1 : 2
        )
    }

    private var actionLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
    }
}

private struct ResultMetric: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(Color.pizzaTomato)
            Text(value).font(.title.bold()).monospacedDigit()
            Text(title).font(.caption.bold()).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 112)
        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value)")
    }
}
