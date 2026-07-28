import SpriteKit
import SwiftUI

extension AppModel: PizzaRushSceneDelegate {
    func pizzaRushScene(_ scene: PizzaRushScene, didRequest command: PlayerCommand) {
        handle(command)
    }
}

struct GameplayView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scene = PizzaRushScene(size: CGSize(width: 390, height: 560))
    @State private var showingPause = false
    @State private var tutorialStep: Int?

    var body: some View {
        if let session = model.session {
            ZStack {
                VStack(spacing: 0) {
                    GameplayHUD(snapshot: session.snapshot) {
                        model.pauseGame()
                        showingPause = true
                    }
                    OrderStrip(session: session)

                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .accessibilityHidden(true)
                        .overlay(alignment: .bottomLeading) {
                            StationLegend()
                                .padding(10)
                        }

                    ContextControls(session: session)
                }
                .background(Color.pizzaCream)

                if showingPause {
                    PauseOverlay(
                        resume: {
                            showingPause = false
                            model.resumeGame()
                        },
                        quit: {
                            showingPause = false
                            model.showMainMenu()
                        }
                    )
                }

                if let tutorialStep {
                    TutorialOverlay(
                        level: session.snapshot.level.number,
                        step: tutorialStep,
                        continueAction: advanceTutorial
                    )
                } else if let instruction = guidedInstruction(for: session) {
                    VStack {
                        TutorialGuideBanner(instruction: instruction)
                            .padding(.top, 58)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
            }
            .onAppear {
                scene.gameDelegate = model
                scene.reduceMotion = reduceMotion
                scene.update(snapshot: session.snapshot)
                beginTutorialIfNeeded(level: session.snapshot.level.number)
            }
            .onChange(of: session.snapshot) { _, snapshot in
                scene.update(snapshot: snapshot)
            }
            .onChange(of: reduceMotion) { _, value in
                scene.reduceMotion = value
            }
            .overlay {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: session.snapshot.status != .running)) { context in
                    Color.clear
                        .allowsHitTesting(false)
                        .onChange(of: context.date) { _, date in
                            model.tick(at: date)
                        }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        } else {
            ProgressView("Preparing kitchen…")
        }
    }

    private func beginTutorialIfNeeded(level: Int) {
        guard
            level <= 3,
            !model.profile.settings.tutorialSkipped,
            !model.profile.tutorialSteps.contains("level_\(level)_intro")
        else { return }
        model.pauseGame()
        tutorialStep = 0
    }

    private func advanceTutorial() {
        guard let tutorialStep, let level = model.session?.snapshot.level.number else { return }
        model.persistence.markTutorialStep("level_\(level)_brief_step_\(tutorialStep + 1)")
        let instructions = TutorialOverlay.instructions(for: level)
        if tutorialStep + 1 < instructions.count {
            self.tutorialStep = tutorialStep + 1
        } else {
            model.persistence.markTutorialStep("level_\(level)_intro")
            self.tutorialStep = nil
            model.resumeGame()
        }
    }

    private func guidedInstruction(for session: GameSessionController) -> String? {
        guard
            session.snapshot.level.number == 1,
            !model.profile.settings.tutorialSkipped,
            model.profile.tutorialSteps.contains("level_1_intro"),
            !model.profile.tutorialSteps.contains("level_1_complete")
        else { return nil }

        guard let pizza = session.snapshot.selectedPizzaID.flatMap({ id in
            session.snapshot.pizzas.first { $0.id == id }
        }) else {
            return "1 of 7 · Start with Dough"
        }
        switch pizza.state {
        case .preparing where !pizza.ingredients.contains(.sauce):
            return "2 of 7 · Add Sauce"
        case .preparing where !pizza.ingredients.contains(.cheese):
            return "3 of 7 · Add Cheese"
        case .assembled:
            return "4 of 7 · Send the pizza to the Oven"
        case .baking:
            return session.bakeQuality(for: pizza.bakeProgress) == .perfect
                ? "5 of 7 · Perfect! Remove from Oven"
                : "5 of 7 · Wait for the star-marked Perfect window"
        case .slicing, .undercooked, .perfectlyCooked, .overcooked:
            return "6 of 7 · Slice & Box"
        case .boxed:
            return "7 of 7 · Deliver Order"
        case .burned:
            return "Discard the burned pizza, then try again"
        default:
            return nil
        }
    }
}

private struct TutorialGuideBanner: View {
    let instruction: String

    var body: some View {
        Label(instruction, systemImage: "hand.point.up.left.fill")
            .font(.subheadline.bold())
            .foregroundStyle(Color.pizzaCharcoal)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.pizzaGold, in: Capsule())
            .overlay {
                Capsule().stroke(Color.pizzaCharcoal.opacity(0.28), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.20), radius: 4, y: 2)
            .accessibilityLabel("Tutorial: \(instruction)")
            .accessibilityIdentifier("tutorial.guide")
    }
}

private struct GameplayHUD: View {
    let snapshot: GameSnapshot
    let pause: () -> Void

    var body: some View {
        HStack {
            Button(action: pause) {
                Image(systemName: "pause.fill")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Pause shift")
            .accessibilityIdentifier("game.pause")

            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text(timeText)
                    .fixedSize()
            }
            .font(.title3.monospacedDigit().bold())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(Int(snapshot.remainingTime.rounded(.up))) seconds remaining")

            Spacer()
            Label("\(snapshot.revenue)", systemImage: "dollarsign.circle.fill")
                .font(.headline.monospacedDigit())
                .accessibilityLabel("\(snapshot.revenue) coins this shift")
        }
        .padding(.horizontal, 10)
        .frame(height: 52)
        .background(Color.pizzaCream)
    }

    private var timeText: String {
        let total = max(0, Int(snapshot.remainingTime.rounded(.up)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

private struct OrderStrip: View {
    let session: GameSessionController

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(session.snapshot.orders) { order in
                    let recipe = session.recipe(for: order)
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(recipe?.displayName ?? "Order")
                                .font(.subheadline.bold())
                            Spacer()
                            Image(systemName: patienceSymbol(order.patienceRemaining))
                                .accessibilityHidden(true)
                        }
                        HStack(spacing: 7) {
                            ForEach(recipe?.requiredIngredients ?? []) { ingredient in
                                Image(systemName: ingredient.symbolName)
                                    .accessibilityLabel(ingredient.displayName)
                            }
                        }
                        ProgressView(value: order.patienceRemaining)
                            .tint(patienceColor(order.patienceRemaining))
                    }
                    .padding(10)
                    .frame(width: 170, alignment: .leading)
                    .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.pizzaCharcoal.opacity(0.16), lineWidth: 1)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "\(recipe?.displayName ?? "Order"), \(order.emotionalState), \(Int(order.patienceRemaining * 100)) percent patience"
                    )
                    .accessibilityIdentifier("order.\(order.id.uuidString)")
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
        }
        .background(Color.pizzaCream)
    }

    private func patienceSymbol(_ value: Double) -> String {
        switch value {
        case 0.60...: "face.smiling.fill"
        case 0.30..<0.60: "face.dashed.fill"
        default: "exclamationmark.triangle.fill"
        }
    }

    private func patienceColor(_ value: Double) -> Color {
        switch value {
        case 0.60...: .pizzaOlive
        case 0.30..<0.60: .pizzaGold
        default: .pizzaTomato
        }
    }
}

private struct StationLegend: View {
    var body: some View {
        HStack(spacing: 6) {
            Label("Prep", systemImage: "circle.grid.2x2.fill")
            Image(systemName: "chevron.right")
            Label("Bake", systemImage: "flame.fill")
            Image(systemName: "chevron.right")
            Label("Cut", systemImage: "circle.grid.cross.fill")
            Image(systemName: "chevron.right")
            Label("Send", systemImage: "takeoutbag.and.cup.and.straw.fill")
        }
        .font(.caption2.bold())
        .foregroundStyle(Color.pizzaCream)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.pizzaCharcoal.opacity(0.88), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Production order: Prep, Bake, Cut, Send")
    }
}

private struct ContextControls: View {
    @Environment(AppModel.self) private var model
    let session: GameSessionController

    var body: some View {
        VStack(spacing: 7) {
            HStack {
                Label("Combo \(session.snapshot.combo)", systemImage: "flame.fill")
                Spacer()
                Text(session.snapshot.lastMessage)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
            .font(.subheadline.bold())
            .padding(.horizontal, 12)

            if let pizza = selectedPizza {
                controls(for: pizza)
            } else {
                Button {
                    model.handle(.startPizza)
                } label: {
                    Label("Start with Dough", systemImage: IngredientID.dough.symbolName)
                }
                .buttonStyle(PrimaryGameButton(color: .pizzaBlue))
                .accessibilityHint("Places dough on the preparation counter")
                .accessibilityIdentifier("game.startDough")
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 8)
        .background(Color.pizzaCream)
    }

    @ViewBuilder
    private func controls(for pizza: PizzaEntity) -> some View {
        switch pizza.state {
        case .preparing, .assembled:
            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        ForEach(IngredientID.allCases.filter { $0 != .dough }) { ingredient in
                            let selected = pizza.ingredients.contains(ingredient)
                            Button {
                                model.handle(
                                    selected
                                        ? .removeIngredient(ingredient, from: pizza.id)
                                        : .addIngredient(ingredient, to: pizza.id)
                                )
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: ingredient.symbolName).font(.title3)
                                    Text(ingredient.displayName).font(.caption.bold())
                                }
                                .frame(
                                    minWidth: model.profile.settings.assistMode ? 88 : 72,
                                    minHeight: model.profile.settings.assistMode ? 62 : 52
                                )
                                .foregroundStyle(selected ? Color.pizzaCream : Color.pizzaCharcoal)
                                .background(
                                    selected ? Color.pizzaOlive : Color.white,
                                    in: RoundedRectangle(cornerRadius: 14)
                                )
                            }
                            .accessibilityLabel(
                                selected ? "Remove \(ingredient.displayName)" : "Add \(ingredient.displayName)"
                            )
                            .accessibilityIdentifier("ingredient.\(ingredient.rawValue)")
                        }
                    }
                    .padding(.leading, 12)
                }
                Button {
                    model.handle(.movePizza(pizza.id, to: .oven))
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "flame.fill").font(.title3)
                        Text("To Oven").font(.caption.bold())
                    }
                    .frame(width: 78)
                    .frame(minHeight: model.profile.settings.assistMode ? 62 : 52)
                }
                .buttonStyle(.borderedProminent)
                .disabled(pizza.state != .assembled)
                .accessibilityIdentifier("game.toOven")
                .padding(.trailing, 12)
            }
        case .baking:
            HStack(spacing: 14) {
                BakeMeter(progress: pizza.bakeProgress)
                Button("Remove from Oven") {
                    model.handle(.removePizzaFromOven(pizza.id))
                }
                .buttonStyle(PrimaryGameButton(color: .pizzaTomato))
                .accessibilityIdentifier("game.removeOven")
            }
            .padding(.horizontal, 12)
        case .slicing, .undercooked, .perfectlyCooked, .overcooked:
            Button {
                model.handle(.slicePizza(pizza.id))
            } label: {
                Label("Slice & Box", systemImage: "circle.grid.cross.fill")
            }
            .buttonStyle(PrimaryGameButton(color: .pizzaOlive))
            .accessibilityIdentifier("game.slice")
            .padding(.horizontal, 12)
        case .boxed:
            Button {
                if let orderID = pizza.assignedOrderID {
                    model.handle(.deliverPizza(pizza.id, to: orderID))
                }
            } label: {
                Label("Deliver Order", systemImage: "takeoutbag.and.cup.and.straw.fill")
            }
            .buttonStyle(PrimaryGameButton(color: .pizzaTomato))
            .accessibilityIdentifier("game.deliver")
            .padding(.horizontal, 12)
        case .burned:
            Button(role: .destructive) {
                model.handle(.discardPizza(pizza.id))
            } label: {
                Label("Discard Burned Pizza", systemImage: "trash.fill")
            }
            .buttonStyle(PrimaryGameButton(color: .pizzaCharcoal))
            .accessibilityIdentifier("game.discard")
            .padding(.horizontal, 12)
        default:
            EmptyView()
        }
    }

    private var selectedPizza: PizzaEntity? {
        guard let id = session.snapshot.selectedPizzaID else { return nil }
        return session.snapshot.pizzas.first { $0.id == id }
    }
}

private struct BakeMeter: View {
    let progress: Double

    private var quality: BakeQuality {
        switch progress {
        case ..<0.65: .undercooked
        case ..<0.85: .good
        case ..<1.00: .perfect
        case ..<1.25: .overcooked
        default: .burned
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Gauge(value: min(progress, 1.25), in: 0 ... 1.25) {
                Text("Bake")
            } currentValueLabel: {
                Image(systemName: quality.accessibilityCue)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(Gradient(colors: [.pizzaBlue, .pizzaGold, .pizzaTomato]))
            .frame(width: 54, height: 54)
            Text(quality.rawValue.capitalized)
                .font(.caption2.bold())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Bake state \(quality.rawValue)")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

private struct PauseOverlay: View {
    let resume: () -> Void
    let quit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Shift Paused").font(.largeTitle.bold())
            Button("Resume", action: resume)
                .buttonStyle(PrimaryGameButton())
                .accessibilityIdentifier("pause.resume")
            Button("Quit to Menu", action: quit)
                .buttonStyle(PrimaryGameButton(color: .pizzaCharcoal))
        }
        .padding(24)
        .frame(maxWidth: 330)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 28))
        .padding()
    }
}

private struct TutorialOverlay: View {
    let level: Int
    let step: Int
    let continueAction: () -> Void

    static func instructions(for level: Int) -> [String] {
        switch level {
        case 1:
            [
                "Tap dough to start a pizza.",
                "Add sauce, then cheese.",
                "Drag or send the finished recipe to the oven.",
                "Wait for the star-marked perfect window.",
                "Remove it, slice and box it, then deliver."
            ]
        case 2:
            [
                "Pepperoni orders add one topping.",
                "The customer icon and patience bar show how tips change.",
                "A mistake is recoverable: remove a topping before baking."
            ]
        default:
            [
                "Two orders can overlap. Keep each pizza matched to its customer.",
                "Fast correct deliveries build a combo.",
                "Burns, discards, and missed customers reset the streak."
            ]
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.48).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "hand.tap.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.pizzaGold)
                Text("Tutorial \(step + 1) of \(Self.instructions(for: level).count)")
                    .font(.caption.bold())
                    .textCase(.uppercase)
                Text(Self.instructions(for: level)[step])
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Button(step + 1 == Self.instructions(for: level).count ? "Start Cooking" : "Next") {
                    continueAction()
                }
                .buttonStyle(PrimaryGameButton())
                .accessibilityIdentifier("tutorial.next")
            }
            .padding(24)
            .frame(maxWidth: 330)
            .background(Color.pizzaCream, in: RoundedRectangle(cornerRadius: 28))
        }
    }
}
