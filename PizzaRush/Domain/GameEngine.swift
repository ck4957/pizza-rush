import Foundation

enum PlayerCommand: Equatable, Sendable {
    case startPizza
    case selectPizza(UUID)
    case addIngredient(IngredientID, to: UUID)
    case removeIngredient(IngredientID, from: UUID)
    case movePizza(UUID, to: StationID)
    case removePizzaFromOven(UUID)
    case slicePizza(UUID)
    case deliverPizza(UUID, to: UUID)
    case discardPizza(UUID)
}

struct GameEngine: Sendable {
    private(set) var snapshot: GameSnapshot
    private let recipes: [String: RecipeDefinition]
    private let upgrades: UpgradeResolver
    private let assistMode: Bool
    private var completionOrdinal: Int
    private var nextEntityOrdinal = 1
    private var nextOrderOrdinal = 1
    private var elapsed: TimeInterval = 0
    private var nextSpawnAt: TimeInterval = 0
    private var accumulator: TimeInterval = 0
    private let fixedStep = 1.0 / 60.0

    init(
        level: LevelDefinition,
        recipes: [RecipeDefinition],
        upgrades: UpgradeResolver,
        completionOrdinal: Int,
        assistMode: Bool = false
    ) {
        snapshot = .idle(level: level)
        self.recipes = Dictionary(uniqueKeysWithValues: recipes.map { ($0.id, $0) })
        self.upgrades = upgrades
        self.completionOrdinal = completionOrdinal
        self.assistMode = assistMode
    }

    mutating func start() {
        guard snapshot.status == .idle else { return }
        snapshot.status = .running
        snapshot.remainingTime = snapshot.level.duration
        spawnOrderIfPossible()
        nextSpawnAt = nextSpawnDelay()
    }

    mutating func pause(preserveMessage: Bool = false) {
        guard snapshot.status == .running else { return }
        snapshot.status = .paused
        if !preserveMessage {
            snapshot.lastMessage = "Shift paused."
        }
    }

    mutating func resume() {
        guard snapshot.status == .paused else { return }
        snapshot.status = .running
        accumulator = 0
        snapshot.lastMessage = "Back to the rush."
    }

    mutating func advance(by delta: TimeInterval) {
        guard snapshot.status == .running, delta > 0 else { return }
        accumulator += min(delta, 0.25)
        while accumulator >= fixedStep, snapshot.status == .running {
            simulate(step: fixedStep)
            accumulator -= fixedStep
        }
    }

    mutating func handle(_ command: PlayerCommand) {
        guard snapshot.status == .running else { return }
        switch command {
        case .startPizza:
            startPizza()
        case let .selectPizza(id):
            guard snapshot.pizzas.contains(where: { $0.id == id }) else { return }
            snapshot.selectedPizzaID = id
        case let .addIngredient(ingredient, id):
            add(ingredient, to: id)
        case let .removeIngredient(ingredient, id):
            remove(ingredient, from: id)
        case let .movePizza(id, station):
            move(id, to: station)
        case let .removePizzaFromOven(id):
            removeFromOven(id)
        case let .slicePizza(id):
            slice(id)
        case let .deliverPizza(id, orderID):
            deliver(id, to: orderID)
        case let .discardPizza(id):
            discard(id)
        }
    }

    mutating func forceCompleteForFixture(stars: Int = 3) {
        guard snapshot.status == .running else { return }
        snapshot.revenue = max(
            snapshot.revenue,
            snapshot.level.objective.kind == .revenue
                ? snapshot.level.masteryThreshold
                : 720
        )
        snapshot.customersServed = max(
            snapshot.customersServed,
            snapshot.level.objective.kind == .customers
                ? snapshot.level.masteryThreshold
                : 6
        )
        snapshot.combo = max(
            snapshot.combo,
            snapshot.level.objective.kind == .combo
                ? snapshot.level.masteryThreshold
                : 8
        )
        snapshot.bestCombo = snapshot.combo
        snapshot.perfectPizzas = max(snapshot.perfectPizzas, 4)
        complete(forcedStars: stars)
    }

    mutating func configureFixture(_ scenario: String) {
        guard snapshot.status == .running else { return }
        switch scenario {
        case "build":
            startPizza()
            guard let id = snapshot.selectedPizzaID else { return }
            add(.sauce, to: id)
            add(.cheese, to: id)
        case "oven":
            startPizza()
            guard let id = snapshot.selectedPizzaID else { return }
            if let pizzaIndex = pizzaIndex(id), let recipe = assignedRecipe(for: snapshot.pizzas[pizzaIndex]) {
                for ingredient in recipe.requiredIngredients {
                    add(ingredient, to: id)
                }
            }
            move(id, to: .oven)
            if let pizzaIndex = pizzaIndex(id) {
                snapshot.pizzas[pizzaIndex].bakeProgress = 0.92
                snapshot.lastMessage = "Perfect window — remove now!"
            }
        case "rush":
            snapshot.orders.removeAll()
            while snapshot.orders.count < min(3, snapshot.level.maxConcurrentOrders) {
                spawnOrderIfPossible()
            }
            for station in [StationID.prep, .oven, .cutting, .dispatch] {
                guard let order = snapshot.orders.first(where: { order in
                    !snapshot.pizzas.contains(where: { $0.assignedOrderID == order.id })
                }) else { continue }
                let state: PizzaState = switch station {
                case .prep: .assembled
                case .oven: .baking
                case .cutting: .slicing
                case .dispatch: .boxed
                default: .preparing
                }
                snapshot.pizzas.append(
                    PizzaEntity(
                        id: deterministicUUID(namespace: 1, ordinal: nextEntityOrdinal),
                        ingredients: [.dough, .sauce, .cheese],
                        state: state,
                        station: station,
                        bakeProgress: station == .oven ? 0.72 : 0,
                        quality: station == .cutting || station == .dispatch ? .good : nil,
                        assignedOrderID: order.id
                    )
                )
                nextEntityOrdinal += 1
            }
            snapshot.lastMessage = "Lunch rush: keep every station moving."
        case "results":
            forceCompleteForFixture()
        default:
            break
        }
    }

    func recipe(for order: CustomerOrder) -> RecipeDefinition? {
        recipes[order.recipeID]
    }

    func bakeQuality(for progress: Double) -> BakeQuality {
        let expansion = upgrades.perfectWindowIncrease + (assistMode ? 0.05 : 0)
        return switch progress {
        case ..<0.65: .undercooked
        case ..<(0.85 - expansion): .good
        case ..<(1.00 + expansion): .perfect
        case ..<1.25: .overcooked
        default: .burned
        }
    }

    private mutating func simulate(step: TimeInterval) {
        elapsed += step
        snapshot.remainingTime = max(0, snapshot.level.duration - elapsed)

        for index in snapshot.orders.indices where snapshot.orders[index].status == .waiting {
            let assist = upgrades.patienceBonus + (snapshotAssistMode ? 0.35 : 0)
            let duration = snapshot.orders[index].patienceDuration * (1 + assist)
            snapshot.orders[index].patienceRemaining = max(
                0,
                snapshot.orders[index].patienceRemaining - step / duration
            )
            if snapshot.orders[index].patienceRemaining == 0 {
                snapshot.orders[index].status = .expired
                snapshot.combo = 0
                snapshot.lastMessage = "Customer left. Streak reset."
            }
        }
        snapshot.orders.removeAll { $0.status == .expired }

        for index in snapshot.pizzas.indices where snapshot.pizzas[index].state == .baking {
            let recipe = assignedRecipe(for: snapshot.pizzas[index])
            let duration = max(1, (recipe?.baseBakeDuration ?? 8) * upgrades.bakeDurationMultiplier)
            snapshot.pizzas[index].bakeProgress += step / duration
            let quality = bakeQuality(for: snapshot.pizzas[index].bakeProgress)
            if quality == .burned {
                snapshot.pizzas[index].state = .burned
                snapshot.pizzas[index].quality = .burned
                snapshot.combo = 0
                snapshot.lastMessage = "Burned. Drag to trash and remake."
            } else if quality == .perfect {
                snapshot.lastMessage = "Perfect window — remove now!"
            }
        }

        if elapsed >= nextSpawnAt {
            spawnOrderIfPossible()
            nextSpawnAt = elapsed + nextSpawnDelay()
        }

        if snapshot.remainingTime == 0 {
            complete()
        }
    }

    private var snapshotAssistMode: Bool {
        assistMode
    }

    private mutating func startPizza() {
        guard stationCount(.prep) < upgrades.capacity(for: .prep) else {
            snapshot.lastMessage = "Prep counter is full."
            return
        }
        guard let order = snapshot.orders.first(where: { $0.status == .waiting }) else {
            snapshot.lastMessage = "Wait for the next order."
            return
        }
        let pizza = PizzaEntity(
            id: deterministicUUID(namespace: 1, ordinal: nextEntityOrdinal),
            ingredients: [.dough],
            state: .preparing,
            station: .prep,
            bakeProgress: 0,
            quality: nil,
            assignedOrderID: order.id
        )
        nextEntityOrdinal += 1
        snapshot.pizzas.append(pizza)
        snapshot.selectedPizzaID = pizza.id
        if let index = snapshot.orders.firstIndex(where: { $0.id == order.id }) {
            snapshot.orders[index].status = .preparing
        }
        snapshot.lastMessage = "Add sauce, cheese, and the order toppings."
    }

    private mutating func add(_ ingredient: IngredientID, to id: UUID) {
        guard ingredient != .dough, let index = pizzaIndex(id) else { return }
        guard snapshot.pizzas[index].isEditable else {
            snapshot.lastMessage = "Ingredients cannot be added after baking begins."
            return
        }
        guard !snapshot.pizzas[index].ingredients.contains(ingredient) else {
            snapshot.lastMessage = "\(ingredient.displayName) is already added."
            return
        }
        snapshot.pizzas[index].ingredients.append(ingredient)

        guard let recipe = assignedRecipe(for: snapshot.pizzas[index]) else { return }
        let current = Set(snapshot.pizzas[index].ingredients)
        let required = Set(recipe.requiredIngredients).union([.dough])
        if current == required {
            snapshot.pizzas[index].state = .assembled
            snapshot.lastMessage = "Recipe complete. Move it to the oven."
        } else if !current.isSubset(of: required) {
            snapshot.lastMessage = "Wrong topping. Tap it again to remove it."
        } else {
            snapshot.lastMessage = "\(ingredient.displayName) added."
        }
    }

    private mutating func remove(_ ingredient: IngredientID, from id: UUID) {
        guard ingredient != .dough, let index = pizzaIndex(id) else { return }
        guard snapshot.pizzas[index].isEditable else { return }
        snapshot.pizzas[index].ingredients.removeAll { $0 == ingredient }
        snapshot.pizzas[index].state = .preparing
        snapshot.lastMessage = "\(ingredient.displayName) removed."
    }

    private mutating func move(_ id: UUID, to station: StationID) {
        guard let index = pizzaIndex(id) else { return }
        let pizza = snapshot.pizzas[index]
        switch (pizza.station, station) {
        case (.prep, .oven):
            guard pizza.state == .assembled else {
                snapshot.lastMessage = "Finish the requested ingredients first."
                return
            }
            guard stationCount(.oven) < upgrades.capacity(for: .oven) else {
                snapshot.lastMessage = "Oven is full. Pizza returned to prep."
                return
            }
            snapshot.pizzas[index].station = .oven
            snapshot.pizzas[index].state = .baking
            snapshot.pizzas[index].bakeProgress = 0
            snapshot.lastMessage = "Watch the bake ring."
        case (.oven, .cutting):
            removeFromOven(id)
        case (.cutting, .dispatch):
            slice(id)
        case (.dispatch, .customer):
            if let orderID = pizza.assignedOrderID {
                deliver(id, to: orderID)
            }
        case (_, .trash):
            discard(id)
        default:
            snapshot.lastMessage = "That move is not valid. Pizza returned."
        }
    }

    private mutating func removeFromOven(_ id: UUID) {
        guard let index = pizzaIndex(id), snapshot.pizzas[index].station == .oven else { return }
        guard snapshot.pizzas[index].state == .baking else {
            if snapshot.pizzas[index].state == .burned {
                snapshot.lastMessage = "Burned pizzas must be discarded."
            }
            return
        }
        guard stationCount(.cutting) < upgrades.capacity(for: .cutting) else {
            snapshot.lastMessage = "Cutting board is full."
            return
        }
        let quality = bakeQuality(for: snapshot.pizzas[index].bakeProgress)
        guard quality != .burned else {
            snapshot.pizzas[index].state = .burned
            snapshot.lastMessage = "Burned pizzas must be discarded."
            return
        }
        snapshot.pizzas[index].quality = quality
        snapshot.pizzas[index].state = quality == .perfect ? .perfectlyCooked : {
            switch quality {
            case .undercooked: .undercooked
            case .overcooked: .overcooked
            default: .slicing
            }
        }()
        snapshot.pizzas[index].station = .cutting
        snapshot.pizzas[index].state = .slicing
        snapshot.lastMessage = quality == .perfect ? "Perfect bake! Slice it." : "Slice and box the pizza."
    }

    private mutating func slice(_ id: UUID) {
        guard let index = pizzaIndex(id), snapshot.pizzas[index].station == .cutting else { return }
        guard snapshot.pizzas[index].state == .slicing else { return }
        guard stationCount(.dispatch) < upgrades.capacity(for: .dispatch) else {
            snapshot.lastMessage = "Dispatch counter is full."
            return
        }
        snapshot.pizzas[index].state = .boxed
        snapshot.pizzas[index].station = .dispatch
        snapshot.lastMessage = "Boxed. Send it to the matching customer."
    }

    private mutating func deliver(_ id: UUID, to orderID: UUID) {
        guard
            let pizzaIndex = pizzaIndex(id),
            let orderIndex = snapshot.orders.firstIndex(where: { $0.id == orderID }),
            snapshot.pizzas[pizzaIndex].state == .boxed,
            snapshot.pizzas[pizzaIndex].assignedOrderID == orderID,
            snapshot.orders[orderIndex].status != .expired,
            let quality = snapshot.pizzas[pizzaIndex].quality,
            let recipe = recipes[snapshot.orders[orderIndex].recipeID]
        else {
            snapshot.combo = 0
            snapshot.lastMessage = "That box does not match this customer."
            return
        }

        let patience = snapshot.orders[orderIndex].patienceRemaining
        let nextCombo = patience >= 0.30 ? snapshot.combo + 1 : 0
        let reward = ScoreCalculator.reward(
            base: recipe.baseReward,
            quality: quality,
            patienceRemaining: patience,
            combo: max(1, nextCombo)
        )

        snapshot.revenue += reward
        snapshot.customersServed += 1
        snapshot.combo = nextCombo
        snapshot.bestCombo = max(snapshot.bestCombo, snapshot.combo)
        if quality == .perfect {
            snapshot.perfectPizzas += 1
        }
        snapshot.orders[orderIndex].status = .delivered
        snapshot.pizzas[pizzaIndex].state = .delivered
        snapshot.pizzas[pizzaIndex].station = .customer
        snapshot.lastMessage = quality == .perfect ? "Perfect pizza! +\(reward)" : "Delivered! +\(reward)"

        snapshot.orders.removeAll { $0.id == orderID }
        snapshot.pizzas.removeAll { $0.id == id }
        snapshot.selectedPizzaID = snapshot.pizzas.first?.id
        spawnOrderIfPossible()
    }

    private mutating func discard(_ id: UUID) {
        guard let index = pizzaIndex(id) else { return }
        let orderID = snapshot.pizzas[index].assignedOrderID
        snapshot.pizzas[index].state = .discarded
        snapshot.pizzas.remove(at: index)
        if let orderID, let orderIndex = snapshot.orders.firstIndex(where: { $0.id == orderID }) {
            snapshot.orders[orderIndex].status = .waiting
        }
        snapshot.combo = 0
        snapshot.selectedPizzaID = snapshot.pizzas.first?.id
        snapshot.lastMessage = "Discarded. Streak reset, but the shift continues."
    }

    private mutating func spawnOrderIfPossible() {
        guard snapshot.orders.count < snapshot.level.maxConcurrentOrders else { return }
        let allowed = snapshot.level.allowedRecipes
        guard !allowed.isEmpty else { return }
        let recipeID = allowed[(nextOrderOrdinal - 1) % allowed.count]
        guard let recipe = recipes[recipeID] else { return }
        let order = CustomerOrder(
            id: deterministicUUID(namespace: 2, ordinal: nextOrderOrdinal),
            recipeID: recipeID,
            patienceDuration: max(18, 38 * snapshot.level.patienceMultiplier),
            baseReward: recipe.baseReward,
            patienceRemaining: 1,
            status: .waiting
        )
        nextOrderOrdinal += 1
        snapshot.orders.append(order)
    }

    private func nextSpawnDelay() -> TimeInterval {
        let range = snapshot.level.spawnInterval
        let midpoint = (range.minimum + range.maximum) / 2
        let rushActive = snapshot.level.rushWaves.contains {
            elapsed >= $0.startsAt && elapsed <= $0.startsAt + $0.duration
        }
        let assistMultiplier = snapshotAssistMode ? 1.35 : 1.0
        return midpoint * assistMultiplier / (rushActive ? 1.6 : 1)
    }

    private mutating func complete(forcedStars: Int? = nil) {
        guard snapshot.status == .running else { return }
        snapshot.status = .completed
        completionOrdinal += 1

        let achievedValue = switch snapshot.level.objective.kind {
        case .revenue: snapshot.revenue
        case .customers: snapshot.customersServed
        case .combo: snapshot.bestCombo
        }
        let stars: Int
        if let forcedStars {
            stars = forcedStars
        } else {
            stars = StarCalculator.stars(
                achievedValue: achievedValue,
                objectiveTarget: snapshot.level.objective.target,
                secondaryThreshold: snapshot.level.secondaryThreshold,
                masteryThreshold: snapshot.level.masteryThreshold
            )
        }
        let coins = snapshot.revenue + stars * 25
        snapshot.result = LevelResult(
            levelID: snapshot.level.id,
            levelNumber: snapshot.level.number,
            stars: stars,
            revenue: snapshot.revenue,
            customersServed: snapshot.customersServed,
            perfectPizzas: snapshot.perfectPizzas,
            bestCombo: snapshot.bestCombo,
            coinsEarned: coins,
            isNewRecord: true,
            rewardClaimID: "\(snapshot.level.id)-completion-\(completionOrdinal)"
        )
        snapshot.lastMessage = stars > 0 ? "Shift complete!" : "So close. Retry the rush."
    }

    private func assignedRecipe(for pizza: PizzaEntity) -> RecipeDefinition? {
        guard
            let orderID = pizza.assignedOrderID,
            let order = snapshot.orders.first(where: { $0.id == orderID })
        else { return nil }
        return recipes[order.recipeID]
    }

    private func stationCount(_ station: StationID) -> Int {
        snapshot.pizzas.filter { $0.station == station }.count
    }

    private func pizzaIndex(_ id: UUID) -> Int? {
        snapshot.pizzas.firstIndex { $0.id == id }
    }

    private func deterministicUUID(namespace: UInt16, ordinal: Int) -> UUID {
        let suffix = String(format: "%012llx", UInt64(max(0, ordinal)))
        return UUID(uuidString: String(format: "00000000-0000-%04x-8000-%@", namespace, suffix))!
    }
}
