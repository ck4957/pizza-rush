import SwiftUI

@main
struct PizzaRushApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .task {
                    await model.prepare()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                model.resumeGame()
                Task { await model.purchaseService.refreshEntitlement() }
            case .inactive, .background:
                model.pauseGame()
                model.audio.stop()
            @unknown default:
                break
            }
        }
    }
}

