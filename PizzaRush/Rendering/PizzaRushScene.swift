import SpriteKit

@MainActor
protocol PizzaRushSceneDelegate: AnyObject {
    func pizzaRushScene(_ scene: PizzaRushScene, didRequest command: PlayerCommand)
}

@MainActor
final class PizzaRushScene: SKScene {
    weak var gameDelegate: (any PizzaRushSceneDelegate)?
    var reduceMotion = false

    private let background = SKSpriteNode(imageNamed: "kitchen-background")
    private let entityLayer = SKNode()
    private let effectLayer = SKNode()
    private var pizzaNodes: [UUID: SKNode] = [:]
    private var activeDragID: UUID?
    private var snapshot: GameSnapshot?

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1)
        background.zPosition = 0
        addChild(background)
        entityLayer.zPosition = 2_000
        effectLayer.zPosition = 10_000
        addChild(entityLayer)
        addChild(effectLayer)
        installStationFocusRings()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func didMove(to view: SKView) {
        view.preferredFramesPerSecond = 60
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = true
        view.isAccessibilityElement = false
        layoutBackground()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutBackground()
        layoutStationFocusRings()
        if let snapshot {
            update(snapshot: snapshot)
        }
    }

    func update(snapshot: GameSnapshot) {
        self.snapshot = snapshot
        let liveIDs = Set(snapshot.pizzas.map(\.id))
        for (id, node) in pizzaNodes where !liveIDs.contains(id) {
            pizzaNodes[id] = nil
            if reduceMotion {
                node.removeFromParent()
            } else {
                emitBurst(at: node.position, color: UIColor(red: 0.95, green: 0.73, blue: 0.26, alpha: 1))
                node.run(
                    .sequence([
                        .group([
                            .moveBy(x: 22, y: 18, duration: 0.22),
                            .fadeOut(withDuration: 0.22),
                            .scale(to: 0.82, duration: 0.22)
                        ]),
                        .removeFromParent()
                    ])
                )
            }
        }

        for pizza in snapshot.pizzas {
            let node = pizzaNodes[pizza.id] ?? makePizzaNode(pizza)
            refresh(node: node, pizza: pizza)
            let target = point(for: pizza.station, ordinal: stationOrdinal(for: pizza, in: snapshot))
            if node.position != target, activeDragID != pizza.id {
                if reduceMotion {
                    node.position = target
                } else {
                    node.run(.move(to: target, duration: 0.18), withKey: "stationMove")
                }
            }
            node.zPosition = 2_000 - target.y
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        let candidate = pizzaNodes
            .filter { _, node in node.calculateAccumulatedFrame().insetBy(dx: -24, dy: -24).contains(location) }
            .min { lhs, rhs in
                distance(lhs.value.position, location) < distance(rhs.value.position, location)
            }
        guard let (id, node) = candidate else { return }
        activeDragID = id
        node.removeAction(forKey: "stationMove")
        node.setScale(reduceMotion ? 1 : 1.08)
        gameDelegate?.pizzaRushScene(self, didRequest: .selectPizza(id))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard
            let id = activeDragID,
            let node = pizzaNodes[id],
            let location = touches.first?.location(in: self)
        else { return }
        node.position = location
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let id = activeDragID, let node = pizzaNodes[id] else { return }
        defer {
            activeDragID = nil
            node.setScale(1)
        }
        let location = touches.first?.location(in: self) ?? node.position
        guard let station = nearestStation(to: location) else {
            if let pizza = snapshot?.pizzas.first(where: { $0.id == id }) {
                node.run(.move(to: point(for: pizza.station, ordinal: 0), duration: 0.16))
            }
            return
        }
        gameDelegate?.pizzaRushScene(self, didRequest: .movePizza(id, to: station))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func makePizzaNode(_ pizza: PizzaEntity) -> SKNode {
        let container = SKNode()
        container.name = pizza.id.uuidString
        container.userData = NSMutableDictionary()
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 86, height: 27))
        shadow.fillColor = .black.withAlphaComponent(0.20)
        shadow.strokeColor = .clear
        shadow.position.y = -10
        shadow.zPosition = -1
        container.addChild(shadow)

        let crust = SKShapeNode(ellipseOf: CGSize(width: 82, height: 52))
        crust.name = "crust"
        crust.fillColor = UIColor(red: 0.85, green: 0.60, blue: 0.32, alpha: 1)
        crust.strokeColor = UIColor(red: 0.45, green: 0.20, blue: 0.10, alpha: 1)
        crust.lineWidth = 3
        container.addChild(crust)
        entityLayer.addChild(container)
        pizzaNodes[pizza.id] = container
        if !reduceMotion {
            container.setScale(0.82)
            container.run(
                .sequence([
                    .scale(to: 1.10, duration: 0.10),
                    .scale(to: 1.0, duration: 0.08)
                ])
            )
            emitBurst(at: container.position, color: UIColor.white.withAlphaComponent(0.85))
        }
        return container
    }

    private func refresh(node: SKNode, pizza: PizzaEntity) {
        let ingredientSignature = pizza.ingredients.map(\.rawValue).joined(separator: ",")
        let previousIngredientSignature = node.userData?["ingredients"] as? String
        if previousIngredientSignature != ingredientSignature {
            node.children
                .filter { $0.name?.hasPrefix("ingredient-") == true }
                .forEach { $0.removeFromParent() }
            installIngredients(on: node, pizza: pizza)
            node.userData?["ingredients"] = ingredientSignature
            if previousIngredientSignature != nil, !reduceMotion {
                node.run(
                    .sequence([
                        .scale(to: 0.95, duration: 0.04),
                        .scale(to: 1.10, duration: 0.08),
                        .scale(to: 1.0, duration: 0.07)
                    ])
                )
                emitBurst(
                    at: node.position,
                    color: UIColor(red: 0.96, green: 0.86, blue: 0.50, alpha: 0.9)
                )
            }
        }

        let previousState = (node.userData?["state"] as? String).flatMap(PizzaState.init(rawValue:))
        if previousState != pizza.state {
            animateStateChange(on: node, from: previousState, to: pizza.state)
            node.userData?["state"] = pizza.state.rawValue
        }

        updateBakeIndicator(on: node, pizza: pizza)

        if let crust = node.childNode(withName: "crust") as? SKShapeNode {
            switch pizza.state {
            case .burned:
                crust.fillColor = UIColor(red: 0.18, green: 0.13, blue: 0.11, alpha: 1)
            case .baking where pizza.bakeProgress >= 0.85:
                crust.fillColor = UIColor(red: 0.95, green: 0.65, blue: 0.28, alpha: 1)
            default:
                crust.fillColor = UIColor(red: 0.85, green: 0.60, blue: 0.32, alpha: 1)
            }
        }
    }

    private func installIngredients(on node: SKNode, pizza: PizzaEntity) {
        let ingredientColors: [IngredientID: UIColor] = [
            .sauce: UIColor(red: 0.76, green: 0.17, blue: 0.11, alpha: 1),
            .cheese: UIColor(red: 0.96, green: 0.86, blue: 0.50, alpha: 1),
            .pepperoni: UIColor(red: 0.72, green: 0.12, blue: 0.08, alpha: 1),
            .mushroom: UIColor(red: 0.78, green: 0.68, blue: 0.55, alpha: 1),
            .olive: UIColor(red: 0.12, green: 0.12, blue: 0.10, alpha: 1)
        ]
        let positions = [
            CGPoint(x: -22, y: 7),
            CGPoint(x: 0, y: 11),
            CGPoint(x: 22, y: 6),
            CGPoint(x: -12, y: -8),
            CGPoint(x: 13, y: -7)
        ]
        for (offset, ingredient) in pizza.ingredients.filter({ $0 != .dough }).enumerated() {
            let topping = SKShapeNode(circleOfRadius: ingredient == .cheese ? 13 : 7)
            topping.name = "ingredient-\(ingredient.rawValue)"
            topping.position = positions[offset % positions.count]
            topping.fillColor = ingredientColors[ingredient] ?? .white
            topping.strokeColor = .clear
            topping.alpha = ingredient == .cheese ? 0.65 : 1
            node.addChild(topping)
        }
    }

    private func animateStateChange(
        on node: SKNode,
        from previousState: PizzaState?,
        to state: PizzaState
    ) {
        guard !reduceMotion, previousState != nil else { return }
        switch state {
        case .baking:
            node.run(
                .sequence([
                    .rotate(byAngle: -0.06, duration: 0.08),
                    .rotate(byAngle: 0.10, duration: 0.10),
                    .rotate(toAngle: 0, duration: 0.08)
                ])
            )
        case .slicing:
            node.run(
                .sequence([
                    .scaleX(to: 1.08, duration: 0.06),
                    .scaleX(to: 1.0, duration: 0.08)
                ])
            )
        case .boxed:
            node.run(
                .sequence([
                    .scaleY(to: 0.88, duration: 0.07),
                    .scaleY(to: 1.0, duration: 0.10)
                ])
            )
        case .burned:
            node.run(.sequence([.fadeAlpha(to: 0.65, duration: 0.12), .fadeAlpha(to: 1, duration: 0.12)]))
        default:
            break
        }
    }

    private func updateBakeIndicator(on node: SKNode, pizza: PizzaEntity) {
        node.childNode(withName: "bake-ring")?.removeFromParent()
        node.childNode(withName: "bake-cue")?.removeFromParent()
        guard pizza.state == .baking || pizza.state == .burned else { return }

        let progress = min(1.25, max(0, pizza.bakeProgress))
        let quality: BakeQuality = switch progress {
        case ..<0.65: .undercooked
        case ..<0.85: .good
        case ..<1.00: .perfect
        case ..<1.25: .overcooked
        default: .burned
        }
        let path = CGMutablePath()
        path.addArc(
            center: .zero,
            radius: 48,
            startAngle: -.pi / 2,
            endAngle: -.pi / 2 + .pi * 2 * min(1, progress),
            clockwise: false
        )
        let ring = SKShapeNode(path: path)
        ring.name = "bake-ring"
        ring.fillColor = .clear
        ring.strokeColor = switch quality {
        case .undercooked: UIColor(red: 0.30, green: 0.46, blue: 0.58, alpha: 1)
        case .good: UIColor(red: 0.40, green: 0.45, blue: 0.24, alpha: 1)
        case .perfect: UIColor(red: 0.95, green: 0.73, blue: 0.26, alpha: 1)
        case .overcooked, .burned: UIColor(red: 0.85, green: 0.29, blue: 0.20, alpha: 1)
        }
        ring.lineWidth = quality == .perfect ? 6 : 4
        ring.zPosition = 8
        node.addChild(ring)

        let cueText: String = switch quality {
        case .undercooked: "●"
        case .good: "✓"
        case .perfect: "★"
        case .overcooked: "!"
        case .burned: "☁"
        }
        let cue = SKLabelNode(text: cueText)
        cue.name = "bake-cue"
        cue.fontName = "AvenirNext-Bold"
        cue.fontSize = 18
        cue.fontColor = ring.strokeColor
        cue.position = CGPoint(x: 0, y: 38)
        cue.zPosition = 9
        node.addChild(cue)
        if quality == .perfect, !reduceMotion, node.action(forKey: "perfectPulse") == nil {
            node.run(
                .repeatForever(
                    .sequence([
                        .scale(to: 1.04, duration: 0.35),
                        .scale(to: 1.0, duration: 0.35)
                    ])
                ),
                withKey: "perfectPulse"
            )
        } else if quality != .perfect {
            node.removeAction(forKey: "perfectPulse")
            node.setScale(1)
        }
    }

    private func emitBurst(at position: CGPoint, color: UIColor) {
        guard !reduceMotion else { return }
        for index in 0 ..< 3 {
            let particle = SKShapeNode(circleOfRadius: 3)
            particle.fillColor = color
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 10_100
            effectLayer.addChild(particle)
            let angle = CGFloat(index) * (2 * .pi / 3) - .pi / 2
            particle.run(
                .sequence([
                    .group([
                        .moveBy(x: cos(angle) * 24, y: sin(angle) * 24, duration: 0.22),
                        .fadeOut(withDuration: 0.22),
                        .scale(to: 0.2, duration: 0.22)
                    ]),
                    .removeFromParent()
                ])
            )
        }
    }

    private func installStationFocusRings() {
        for station in [StationID.prep, .oven, .cutting, .dispatch] {
            let ring = SKShapeNode(rectOf: CGSize(width: 98, height: 70), cornerRadius: 18)
            ring.name = "station-\(station.rawValue)"
            ring.fillColor = .clear
            ring.strokeColor = UIColor.white.withAlphaComponent(0.55)
            ring.lineWidth = 2
            ring.zPosition = 1_100
            addChild(ring)
        }
        layoutStationFocusRings()
    }

    private func layoutStationFocusRings() {
        for station in [StationID.prep, .oven, .cutting, .dispatch] {
            childNode(withName: "station-\(station.rawValue)")?.position = point(for: station, ordinal: 0)
        }
    }

    private func layoutBackground() {
        guard background.texture?.size().width ?? 0 > 0 else { return }
        let textureSize = background.texture!.size()
        let scale = max(size.width / textureSize.width, size.height / textureSize.height)
        background.size = CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
        background.position = .zero
    }

    private func point(for station: StationID, ordinal: Int) -> CGPoint {
        let y = -size.height * 0.02 + CGFloat(ordinal) * 20
        return switch station {
        case .prep: CGPoint(x: -size.width * 0.34, y: y)
        case .oven: CGPoint(x: -size.width * 0.11, y: y + 12)
        case .cutting: CGPoint(x: size.width * 0.15, y: y + 8)
        case .dispatch: CGPoint(x: size.width * 0.36, y: y + 14)
        case .customer: CGPoint(x: size.width * 0.42, y: size.height * 0.28)
        case .trash: CGPoint(x: -size.width * 0.43, y: -size.height * 0.30)
        }
    }

    private func stationOrdinal(for pizza: PizzaEntity, in snapshot: GameSnapshot) -> Int {
        snapshot.pizzas.filter { $0.station == pizza.station }.firstIndex { $0.id == pizza.id } ?? 0
    }

    private func nearestStation(to location: CGPoint) -> StationID? {
        let stations: [StationID] = [.prep, .oven, .cutting, .dispatch, .customer, .trash]
        return stations
            .map { ($0, distance(point(for: $0, ordinal: 0), location)) }
            .filter { $0.1 < 120 }
            .min { $0.1 < $1.1 }?
            .0
    }

    private func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }
}
