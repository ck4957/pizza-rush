import SwiftUI

extension Color {
    static let pizzaCream = Color(red: 1.00, green: 0.95, blue: 0.85)
    static let pizzaCharcoal = Color(red: 0.20, green: 0.17, blue: 0.16)
    static let pizzaTomato = Color(red: 0.85, green: 0.29, blue: 0.20)
    static let pizzaCrust = Color(red: 0.85, green: 0.61, blue: 0.32)
    static let pizzaOlive = Color(red: 0.40, green: 0.45, blue: 0.24)
    static let pizzaBlue = Color(red: 0.30, green: 0.46, blue: 0.58)
    static let pizzaGold = Color(red: 0.95, green: 0.73, blue: 0.26)
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            Color.pizzaCream.ignoresSafeArea()

            switch model.route {
            case .mainMenu:
                MainMenuView()
            case .levels:
                LevelSelectView()
            case let .preLevel(number):
                PreLevelView(levelNumber: number)
            case .gameplay:
                GameplayView()
            case .results:
                ResultsView()
            case .upgrades:
                UpgradesView()
            case .settings:
                SettingsView()
            case .aboutSupport:
                AboutSupportView()
            }

            if let message = model.userMessage {
                Text(message)
                    .font(.headline)
                    .foregroundStyle(Color.pizzaCream)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.pizzaCharcoal.opacity(0.94), in: Capsule())
                    .padding(.top, 10)
                    .accessibilityIdentifier("toast.message")
                    .onTapGesture { model.clearMessage() }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .foregroundStyle(Color.pizzaCharcoal)
        .tint(.pizzaTomato)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: model.userMessage)
        .preferredColorScheme(.light)
    }
}

struct AppHeader: View {
    let title: String
    let backAction: () -> Void

    var body: some View {
        HStack {
            Button(action: backAction) {
                Label("Back", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Back")

            Spacer()
            Text(title)
                .font(.title2.bold())
                .minimumScaleFactor(0.75)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
}

struct PrimaryGameButton: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var color: Color = .pizzaTomato

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.pizzaCream)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(color.opacity(configuration.isPressed ? 0.78 : 1), in: RoundedRectangle(cornerRadius: 18))
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.98 : 1))
    }
}
