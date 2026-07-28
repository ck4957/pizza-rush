import Foundation

enum IngredientID: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case dough
    case sauce
    case cheese
    case pepperoni
    case mushroom
    case olive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dough: "Dough"
        case .sauce: "Sauce"
        case .cheese: "Cheese"
        case .pepperoni: "Pepperoni"
        case .mushroom: "Mushroom"
        case .olive: "Olive"
        }
    }

    var symbolName: String {
        switch self {
        case .dough: "circle.fill"
        case .sauce: "drop.fill"
        case .cheese: "square.grid.3x3.fill"
        case .pepperoni: "circle.grid.2x2.fill"
        case .mushroom: "umbrella.fill"
        case .olive: "circle.dotted"
        }
    }
}

struct RecipeDefinition: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let displayName: String
    let requiredIngredients: [IngredientID]
    let preparationDuration: TimeInterval
    let baseBakeDuration: TimeInterval
    let baseReward: Int
    let difficulty: Int
}

enum StationID: String, Codable, CaseIterable, Sendable {
    case prep
    case oven
    case cutting
    case dispatch
    case customer
    case trash
}

enum PizzaState: String, Codable, Equatable, Sendable {
    case dough
    case preparing
    case assembled
    case baking
    case undercooked
    case perfectlyCooked
    case overcooked
    case burned
    case slicing
    case boxed
    case delivered
    case discarded
}

enum BakeQuality: String, Codable, Equatable, Sendable {
    case undercooked
    case good
    case perfect
    case overcooked
    case burned

    var multiplier: Double {
        switch self {
        case .perfect: 1.25
        case .good: 1.00
        case .undercooked: 0.70
        case .overcooked: 0.60
        case .burned: 0
        }
    }

    var accessibilityCue: String {
        switch self {
        case .undercooked: "circle"
        case .good: "checkmark"
        case .perfect: "star"
        case .overcooked: "exclamationmark"
        case .burned: "smoke"
        }
    }
}

struct PizzaEntity: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var ingredients: [IngredientID]
    var state: PizzaState
    var station: StationID
    var bakeProgress: Double
    var quality: BakeQuality?
    var assignedOrderID: UUID?

    var isEditable: Bool {
        state == .preparing || state == .assembled
    }
}

enum OrderStatus: String, Codable, Equatable, Sendable {
    case waiting
    case preparing
    case ready
    case delivered
    case expired
}

struct CustomerOrder: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let recipeID: String
    let patienceDuration: TimeInterval
    let baseReward: Int
    var patienceRemaining: Double
    var status: OrderStatus

    var emotionalState: String {
        switch patienceRemaining {
        case 0.60...: "Happy"
        case 0.30..<0.60: "Neutral"
        case 0.000_001..<0.30: "Frustrated"
        default: "Left"
        }
    }
}

enum ObjectiveKind: String, Codable, CaseIterable, Sendable {
    case revenue
    case customers
    case combo
}

struct LevelObjective: Codable, Equatable, Sendable {
    let kind: ObjectiveKind
    let target: Int

    var description: String {
        switch kind {
        case .revenue: "Earn \(target) coins"
        case .customers: "Serve \(target) customers"
        case .combo: "Reach a \(target)-order combo"
        }
    }
}

struct SpawnInterval: Codable, Equatable, Sendable {
    let minimum: TimeInterval
    let maximum: TimeInterval
}

struct RushWave: Codable, Equatable, Sendable {
    let startsAt: TimeInterval
    let duration: TimeInterval
    let spawnMultiplier: Double
}

struct LevelDefinition: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let number: Int
    let duration: TimeInterval
    let objective: LevelObjective
    let allowedRecipes: [String]
    let maxConcurrentOrders: Int
    let spawnInterval: SpawnInterval
    let patienceMultiplier: Double
    let rushWaves: [RushWave]
    let secondaryThreshold: Int
    let masteryThreshold: Int
}

enum UpgradeCategory: String, Codable, CaseIterable, Sendable, Identifiable {
    case oven
    case preparation
    case cutting
    case delivery
    case ingredients

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oven: "Oven"
        case .preparation: "Prep Counter"
        case .cutting: "Cutting Station"
        case .delivery: "Delivery Counter"
        case .ingredients: "Ingredient Equipment"
        }
    }
}

struct UpgradeResolver: Sendable {
    static let tierCosts = [250, 700, 1_800, 4_500, 10_000]

    let levels: [String: Int]

    func level(for category: UpgradeCategory) -> Int {
        levels[category.rawValue, default: 0]
    }

    func capacity(for station: StationID) -> Int {
        switch station {
        case .prep: min(3, 1 + level(for: .preparation) / 2)
        case .oven: min(3, 1 + level(for: .oven) / 2)
        case .cutting: min(2, 1 + level(for: .cutting) / 3)
        case .dispatch: min(3, 1 + level(for: .delivery) / 2)
        case .customer, .trash: Int.max
        }
    }

    var bakeDurationMultiplier: Double {
        max(0.65, 1 - Double(level(for: .oven)) * 0.06)
    }

    var perfectWindowIncrease: Double {
        min(0.10, Double(level(for: .oven)) * 0.02)
    }

    var patienceBonus: Double {
        min(0.20, Double(level(for: .delivery)) * 0.04)
    }
}

struct GameSettings: Codable, Equatable, Sendable {
    var musicEnabled = true
    var effectsEnabled = true
    var hapticsEnabled = true
    var assistMode = false
    var leftHanded = false
    var tutorialSkipped = false
}

struct PlayerProfile: Codable, Equatable, Sendable {
    var coins = 0
    var highestUnlockedLevel = 1
    var totalOrdersCompleted = 0
    var totalPerfectPizzas = 0
    var bestCombo = 0
    var levelStars: [String: Int] = [:]
    var bestScores: [String: Int] = [:]
    var upgrades: [String: Int] = [:]
    var tutorialSteps: Set<String> = []
    var rewardedClaims: Set<String> = []
    var removeAdsUnlocked = false
    var settings = GameSettings()
    var completionCount = 0
}

struct LevelResult: Codable, Equatable, Sendable {
    let levelID: String
    let levelNumber: Int
    let stars: Int
    let revenue: Int
    let customersServed: Int
    let perfectPizzas: Int
    let bestCombo: Int
    let coinsEarned: Int
    let isNewRecord: Bool
    let rewardClaimID: String
}

enum SessionStatus: String, Codable, Equatable, Sendable {
    case idle
    case running
    case paused
    case completed
}

struct GameSnapshot: Equatable, Sendable {
    var level: LevelDefinition
    var status: SessionStatus
    var remainingTime: TimeInterval
    var revenue: Int
    var customersServed: Int
    var perfectPizzas: Int
    var combo: Int
    var bestCombo: Int
    var pizzas: [PizzaEntity]
    var orders: [CustomerOrder]
    var selectedPizzaID: UUID?
    var lastMessage: String
    var result: LevelResult?

    static func idle(level: LevelDefinition) -> GameSnapshot {
        GameSnapshot(
            level: level,
            status: .idle,
            remainingTime: level.duration,
            revenue: 0,
            customersServed: 0,
            perfectPizzas: 0,
            combo: 0,
            bestCombo: 0,
            pizzas: [],
            orders: [],
            selectedPizzaID: nil,
            lastMessage: "Tap dough to begin.",
            result: nil
        )
    }
}

struct ContentCatalog: Codable, Equatable, Sendable {
    let recipes: [RecipeDefinition]
    let levels: [LevelDefinition]
}

enum ContentValidationError: Error, Equatable {
    case duplicateRecipe(String)
    case duplicateLevel(String)
    case missingRecipe(level: String, recipe: String)
    case invalidTarget(String)
    case emptyAllowedRecipes(String)
    case invalidRecipe(String)
    case nonSequentialLevels
}

enum ContentValidator {
    static func validate(_ catalog: ContentCatalog) -> [ContentValidationError] {
        var errors: [ContentValidationError] = []
        let recipeIDs = catalog.recipes.map(\.id)
        let levelIDs = catalog.levels.map(\.id)

        for id in Set(recipeIDs) where recipeIDs.filter({ $0 == id }).count > 1 {
            errors.append(.duplicateRecipe(id))
        }
        for id in Set(levelIDs) where levelIDs.filter({ $0 == id }).count > 1 {
            errors.append(.duplicateLevel(id))
        }
        for recipe in catalog.recipes {
            let required = Set(recipe.requiredIngredients)
            if !required.contains(.sauce) || !required.contains(.cheese) || recipe.baseReward <= 0 {
                errors.append(.invalidRecipe(recipe.id))
            }
        }
        let knownRecipes = Set(recipeIDs)
        for level in catalog.levels {
            if level.objective.target <= 0 || level.duration <= 0 {
                errors.append(.invalidTarget(level.id))
            }
            if level.allowedRecipes.isEmpty {
                errors.append(.emptyAllowedRecipes(level.id))
            }
            for recipe in level.allowedRecipes where !knownRecipes.contains(recipe) {
                errors.append(.missingRecipe(level: level.id, recipe: recipe))
            }
        }
        if catalog.levels.map(\.number) != Array(1 ... catalog.levels.count) {
            errors.append(.nonSequentialLevels)
        }
        return errors
    }
}

enum ContentLoader {
    static func load(bundle: Bundle = .main) -> ContentCatalog {
        guard
            let recipesURL = bundle.url(forResource: "recipes", withExtension: "json", subdirectory: "GameData"),
            let levelsURL = bundle.url(forResource: "levels_world_1", withExtension: "json", subdirectory: "GameData"),
            let recipeData = try? Data(contentsOf: recipesURL),
            let levelData = try? Data(contentsOf: levelsURL),
            let recipes = try? JSONDecoder().decode([RecipeDefinition].self, from: recipeData),
            let levels = try? JSONDecoder().decode([LevelDefinition].self, from: levelData)
        else {
            return safeCatalog
        }

        let catalog = ContentCatalog(recipes: recipes, levels: levels)
        return ContentValidator.validate(catalog).isEmpty ? catalog : safeCatalog
    }

    static let safeCatalog = ContentCatalog(
        recipes: [
            RecipeDefinition(id: "cheese", displayName: "Cheese", requiredIngredients: [.sauce, .cheese], preparationDuration: 2, baseBakeDuration: 8, baseReward: 80, difficulty: 1),
            RecipeDefinition(id: "pepperoni", displayName: "Pepperoni", requiredIngredients: [.sauce, .cheese, .pepperoni], preparationDuration: 2, baseBakeDuration: 8, baseReward: 100, difficulty: 1),
            RecipeDefinition(id: "mushroom", displayName: "Mushroom", requiredIngredients: [.sauce, .cheese, .mushroom], preparationDuration: 2, baseBakeDuration: 8, baseReward: 100, difficulty: 1),
            RecipeDefinition(id: "olive", displayName: "Olive", requiredIngredients: [.sauce, .cheese, .olive], preparationDuration: 2, baseBakeDuration: 8, baseReward: 100, difficulty: 1),
            RecipeDefinition(id: "pepperoni_mushroom", displayName: "Pepperoni Mushroom", requiredIngredients: [.sauce, .cheese, .pepperoni, .mushroom], preparationDuration: 3, baseBakeDuration: 9, baseReward: 140, difficulty: 2),
            RecipeDefinition(id: "supreme", displayName: "Supreme", requiredIngredients: [.sauce, .cheese, .pepperoni, .mushroom, .olive], preparationDuration: 4, baseBakeDuration: 10, baseReward: 180, difficulty: 3)
        ],
        levels: (1 ... 20).map { number in
            let kind: ObjectiveKind = switch number % 3 {
            case 1: .revenue
            case 2: .customers
            default: .combo
            }
            let target = switch kind {
            case .revenue: 240 + number * 18
            case .customers: 2 + number / 4
            case .combo: min(8, 2 + number / 3)
            }
            let recipeIDs: [String] = switch number {
            case 1 ... 3: ["cheese", "pepperoni"]
            case 4 ... 7: ["cheese", "pepperoni", "mushroom"]
            case 8 ... 11: ["cheese", "pepperoni", "mushroom", "olive"]
            case 12 ... 15: ["pepperoni", "mushroom", "olive", "pepperoni_mushroom"]
            default: ["cheese", "pepperoni", "mushroom", "olive", "pepperoni_mushroom", "supreme"]
            }
            return LevelDefinition(
                id: String(format: "level_%02d", number),
                number: number,
                duration: number <= 3 ? 60 : 75,
                objective: LevelObjective(kind: kind, target: target),
                allowedRecipes: recipeIDs,
                maxConcurrentOrders: number < 7 ? 1 : min(4, 1 + number / 7),
                spawnInterval: SpawnInterval(
                    minimum: max(2.6, 5.5 - Double(number) * 0.10),
                    maximum: max(4.2, 7.0 - Double(number) * 0.10)
                ),
                patienceMultiplier: max(0.70, 1 - Double(number - 1) * 0.012),
                rushWaves: number >= 13 ? [RushWave(startsAt: 25, duration: 12, spawnMultiplier: 1.6)] : [],
                secondaryThreshold: Int(Double(target) * 1.25),
                masteryThreshold: Int(Double(target) * 1.55)
            )
        }
    )
}

enum ScoreCalculator {
    static func comboMultiplier(for streak: Int) -> Double {
        switch streak {
        case ...2: 1.0
        case 3 ... 4: 1.2
        case 5 ... 7: 1.4
        default: 1.6
        }
    }

    static func patienceMultiplier(remaining: Double) -> Double {
        switch remaining {
        case 0.60...: 1.20
        case 0.30..<0.60: 1.00
        default: 0.60
        }
    }

    static func reward(
        base: Int,
        quality: BakeQuality,
        patienceRemaining: Double,
        combo: Int,
        perfectBonus: Int = 20
    ) -> Int {
        let multiplied = Double(base)
            * quality.multiplier
            * patienceMultiplier(remaining: patienceRemaining)
            * comboMultiplier(for: combo)
        return Int(multiplied.rounded()) + (quality == .perfect ? perfectBonus : 0)
    }
}

enum StarCalculator {
    static func stars(
        achievedValue: Int,
        objectiveTarget: Int,
        secondaryThreshold: Int,
        masteryThreshold: Int
    ) -> Int {
        if achievedValue >= masteryThreshold {
            3
        } else if achievedValue >= secondaryThreshold {
            2
        } else if achievedValue >= objectiveTarget {
            1
        } else {
            0
        }
    }
}
