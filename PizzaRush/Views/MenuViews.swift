import StoreKit
import SwiftUI

struct MainMenuView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Image("kitchen-background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .accessibilityHidden(true)

                LinearGradient(
                    colors: [.clear, Color.pizzaCharcoal.opacity(0.86)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(spacing: 14) {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("PIZZA RUSH")
                            .font(.system(.largeTitle, design: .rounded, weight: .black))
                            .foregroundStyle(Color.pizzaCream)
                        Text("Build fast. Deliver faster.")
                            .font(.headline)
                            .foregroundStyle(Color.pizzaCream.opacity(0.90))
                    }
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
                    .accessibilityElement(children: .combine)

                    HStack(spacing: 12) {
                        Label("\(model.profile.coins)", systemImage: "dollarsign.circle.fill")
                        Label("Level \(model.profile.highestUnlockedLevel)", systemImage: "map.fill")
                    }
                    .font(.headline)
                    .foregroundStyle(Color.pizzaCharcoal)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.pizzaCream.opacity(0.94), in: Capsule())

                    Button("Play") { model.showLevels() }
                        .buttonStyle(PrimaryGameButton())
                        .accessibilityIdentifier("menu.play")

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                        spacing: 12
                    ) {
                        MenuTile(title: "Upgrades", icon: "wrench.adjustable.fill", color: .pizzaOlive) {
                            model.showUpgrades()
                        }
                        MenuTile(title: "Map", icon: "map.fill", color: .pizzaBlue) {
                            model.showLevels()
                        }
                        MenuTile(title: "Settings", icon: "gearshape.fill", color: .pizzaCrust) {
                            model.showSettings()
                        }
                    }
                }
                .frame(width: max(0, proxy.size.width - 40))
                .padding(.vertical, 20)
            }
        }
        .ignoresSafeArea()
    }
}

private struct MenuTile: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.subheadline.bold())
            }
            .foregroundStyle(Color.pizzaCream)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(color, in: RoundedRectangle(cornerRadius: 16))
        }
        .accessibilityIdentifier("menu.\(title.lowercased())")
    }
}

struct LevelSelectView: View {
    @Environment(AppModel.self) private var model
    private let columns = [GridItem(.adaptive(minimum: 68), spacing: 12)]

    var body: some View {
        VStack(spacing: 10) {
            AppHeader(title: "Corner Pizzeria") { model.showMainMenu() }

            HStack {
                Text("World 1")
                    .font(.title.bold())
                Spacer()
                Label("\(model.profile.coins)", systemImage: "dollarsign.circle.fill")
                    .font(.headline)
            }
            .padding(.horizontal)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(model.catalog.levels) { level in
                        let unlocked = level.number <= model.profile.highestUnlockedLevel
                        Button {
                            model.showPreLevel(level.number)
                        } label: {
                            VStack(spacing: 5) {
                                Image(systemName: unlocked ? "flame.fill" : "lock.fill")
                                    .foregroundStyle(unlocked ? Color.pizzaTomato : .secondary)
                                Text("\(level.number)")
                                    .font(.title3.bold())
                                HStack(spacing: 1) {
                                    ForEach(1 ... 3, id: \.self) { star in
                                        Image(systemName: star <= model.profile.levelStars[level.id, default: 0] ? "star.fill" : "star")
                                    }
                                }
                                .font(.caption2)
                                .foregroundStyle(Color.pizzaGold)
                            }
                            .frame(maxWidth: .infinity, minHeight: 84)
                            .background(
                                unlocked ? Color.white.opacity(0.82) : Color.gray.opacity(0.16),
                                in: RoundedRectangle(cornerRadius: 18)
                            )
                        }
                        .disabled(!unlocked)
                        .accessibilityLabel(
                            unlocked
                                ? "Level \(level.number), \(model.profile.levelStars[level.id, default: 0]) stars"
                                : "Level \(level.number), locked"
                        )
                        .accessibilityIdentifier("level.\(level.number)")
                    }
                }
                .padding()

                VStack(alignment: .leading, spacing: 6) {
                    Label("Downtown Rush", systemImage: "lock.fill")
                    Text("Coming soon after the Corner Pizzeria.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.pizzaCharcoal.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                .padding()
            }
        }
    }
}

struct PreLevelView: View {
    @Environment(AppModel.self) private var model
    let levelNumber: Int

    var body: some View {
        let level = model.level(levelNumber)!
        VStack(spacing: 18) {
            AppHeader(title: "Level \(level.number)") { model.showLevels() }
            Spacer()

            Image(systemName: objectiveSymbol(level.objective.kind))
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(Color.pizzaTomato)
                .accessibilityHidden(true)

            Text(level.objective.description)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("\(Int(level.duration))-second shift")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Text("Recipes").font(.headline)
                ForEach(level.allowedRecipes, id: \.self) { id in
                    if let recipe = model.catalog.recipes.first(where: { $0.id == id }) {
                        HStack {
                            Text(recipe.displayName)
                            Spacer()
                            ForEach(recipe.requiredIngredients) { ingredient in
                                Image(systemName: ingredient.symbolName)
                                    .accessibilityLabel(ingredient.displayName)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 20))

            if level.number <= 3 {
                Label("Tutorial shift — no ads", systemImage: "hand.tap.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.pizzaOlive)
            }

            Spacer()
            Button("Start Shift") { model.startLevel(number: level.number) }
                .buttonStyle(PrimaryGameButton())
                .accessibilityIdentifier("prelevel.start")
        }
        .padding()
    }

    private func objectiveSymbol(_ kind: ObjectiveKind) -> String {
        switch kind {
        case .revenue: "dollarsign.circle.fill"
        case .customers: "person.2.fill"
        case .combo: "flame.fill"
        }
    }
}

struct UpgradesView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 10) {
            AppHeader(title: "Kitchen Upgrades") {
                model.currentResult == nil ? model.showMainMenu() : model.showMainMenu()
            }
            HStack {
                Text("Improve throughput")
                    .font(.title3.bold())
                Spacer()
                Label("\(model.profile.coins)", systemImage: "dollarsign.circle.fill")
                    .font(.headline)
            }
            .padding(.horizontal)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(UpgradeCategory.allCases) { category in
                        let level = model.profile.upgrades[category.rawValue, default: 0]
                        let canUpgrade = UpgradeResolver.tierCosts.indices.contains(level)
                        HStack(spacing: 14) {
                            Image(systemName: upgradeSymbol(category))
                                .font(.title)
                                .frame(width: 48, height: 48)
                                .background(Color.pizzaGold.opacity(0.28), in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(category.displayName).font(.headline)
                                Text("Tier \(level) of 5")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(canUpgrade ? "\(UpgradeResolver.tierCosts[level])" : "Max") {
                                model.purchaseUpgrade(category)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!canUpgrade)
                            .accessibilityLabel(
                                canUpgrade
                                    ? "Upgrade \(category.displayName) for \(UpgradeResolver.tierCosts[level]) coins"
                                    : "\(category.displayName) maximum tier"
                            )
                            .accessibilityIdentifier("upgrade.\(category.rawValue)")
                        }
                        .padding()
                        .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 18))
                    }
                }
                .padding()
            }
        }
    }

    private func upgradeSymbol(_ category: UpgradeCategory) -> String {
        switch category {
        case .oven: "flame.fill"
        case .preparation: "circle.grid.2x2.fill"
        case .cutting: "circle.grid.cross.fill"
        case .delivery: "takeoutbag.and.cup.and.straw.fill"
        case .ingredients: "leaf.fill"
        }
    }
}

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var settings = GameSettings()
    @State private var confirmReset = false

    var body: some View {
        VStack(spacing: 6) {
            AppHeader(title: "Settings") { model.showMainMenu() }
            Form {
                Section("Sound & Feel") {
                    Toggle("Music", isOn: binding(\.musicEnabled))
                    Toggle("Sound Effects", isOn: binding(\.effectsEnabled))
                    Toggle("Haptics", isOn: binding(\.hapticsEnabled))
                }
                Section("Gameplay Accessibility") {
                    Toggle("Assist Mode", isOn: binding(\.assistMode))
                    Text("Larger targets, longer patience, a wider perfect window, and slower orders. Progress and rewards stay unchanged.")
                        .font(.footnote)
                    Toggle("Left-Handed Layout", isOn: binding(\.leftHanded))
                    Toggle("Skip Tutorial", isOn: binding(\.tutorialSkipped))
                }
                Section {
                    Button("About & Support") { model.showAboutSupport() }
                        .accessibilityIdentifier("settings.aboutSupport")
                }
                Section {
                    Button("Reset Progress", role: .destructive) { confirmReset = true }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .onAppear { settings = model.profile.settings }
        .onChange(of: settings) { _, newValue in model.updateSettings(newValue) }
        .confirmationDialog("Reset all local game progress?", isPresented: $confirmReset) {
            Button("Reset Progress", role: .destructive) { model.resetProgress() }
        } message: {
            Text("Coins, stars, upgrades, and tutorial progress will be removed. Purchases remain restorable.")
        }
    }

    private func binding(_ keyPath: WritableKeyPath<GameSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { settings[keyPath: keyPath] = $0 }
        )
    }
}

struct AboutSupportView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL

    private let supportURL = URL(string: "https://ck4957.github.io/pizza-rush/support/")!
    private let privacyURL = URL(string: "https://ck4957.github.io/pizza-rush/privacy/")!
    private let termsURL = URL(string: "https://ck4957.github.io/pizza-rush/terms/")!
    private let moreAppsURL = URL(
        string: "https://apps.apple.com/us/developer/chirag-narendra-kular/id1792669286"
    )!

    var body: some View {
        VStack(spacing: 6) {
            AppHeader(title: "About & Support") { model.showSettings() }
            Form {
                Section {
                    HStack {
                        Image("AppIconImage")
                            .resizable()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading) {
                            Text("Pizza Rush").font(.title2.bold())
                            Text(versionText).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Support") {
                    Button("Report a Bug") { openURL(supportURL) }
                    Button("Support & Quick Answers") { openURL(supportURL) }
                    Button("More Apps by Developer") { openURL(moreAppsURL) }
                }

                Section("Privacy & Legal") {
                    Button("Privacy Policy") { openURL(privacyURL) }
                    Button("Terms of Use") { openURL(termsURL) }
                    if model.adService.isPrivacyOptionsRequired {
                        Button("Advertising Privacy Choices") {
                            Task { await model.adService.presentPrivacyOptions() }
                        }
                    }
                }

                Section("Remove Ads") {
                    if model.profile.removeAdsUnlocked {
                        Label("Interstitial ads removed", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Color.pizzaOlive)
                    } else if model.isRemoveAdsReviewFixture {
                        Button("Remove Ads — $4.99") {}
                    } else if let product = model.purchaseService.removeAdsProduct {
                        Button("Remove Ads — \(product.displayPrice)") {
                            Task { await model.purchaseService.purchaseRemoveAds() }
                        }
                    } else {
                        Text("Remove Ads is currently unavailable.")
                            .foregroundStyle(.secondary)
                    }
                    Button("Restore Purchases") {
                        Task { await model.purchaseService.restore() }
                    }
                }

                Section("Advertising") {
                    Text("Optional rewarded ads can double a completed level's coins. Limited interstitials appear only at eligible level transitions. Pizza Rush does not request tracking permission.")
                        .font(.footnote)
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}
