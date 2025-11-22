import Foundation

enum GoalPriority: String, Codable, CaseIterable {
    case critical = "critical"
    case important = "important"
    case niceToHave = "niceToHave"
    
    var displayName: String {
        switch self {
        case .critical: return "Критичная"
        case .important: return "Важная"
        case .niceToHave: return "Желаемая"
        }
    }
}

enum GoalType: String, Codable {
    case regular = "regular"
    case emergencyFund = "emergencyFund"
    case travel = "travel"
    
    var displayName: String {
        switch self {
        case .regular: return "Обычная цель"
        case .emergencyFund: return "Подушка безопасности"
        case .travel: return "Путешествие"
        }
    }
}

// Подцели для путешествия
struct TravelSubgoal: Codable, Equatable {
    var name: String  // tickets, accommodation, entertainment
    var amount: Double
    var targetDate: Date
    var currentAmount: Double
    
    init(name: String, amount: Double, targetDate: Date, currentAmount: Double = 0) {
        self.name = name
        self.amount = amount
        self.targetDate = targetDate
        self.currentAmount = currentAmount
    }
    
    var displayName: String {
        switch name {
        case "tickets": return "Билеты"
        case "accommodation": return "Жилье"
        case "entertainment": return "Развлечения"
        default: return name
        }
    }
}

struct Goal: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var targetDate: Date
    var description: String
    var deposits: [Deposit]
    var forecastDate: Date?
    var priority: GoalPriority
    var type: GoalType
    var skipInPeriod: Bool // Не откладывать в этот период (для подушки)
    
    // Для расчета "Нужно/План дает"
    var requiredPerMonth: Double? // Сколько нужно откладывать в месяц
    var actualPerMonth: Double? // Сколько реально получается
    
    // Для типа "Путешествие"
    var travelSubgoals: [TravelSubgoal]?
    
    // Для обратной совместимости
    enum CodingKeys: String, CodingKey {
        case id, name, targetAmount, currentAmount, targetDate, description, deposits, forecastDate, priority, type, skipInPeriod, requiredPerMonth, actualPerMonth, travelSubgoals
    }
    
    init(name: String, targetAmount: Double, currentAmount: Double = 0, targetDate: Date, description: String = "", priority: GoalPriority = .important, type: GoalType = .regular, travelSubgoals: [TravelSubgoal]? = nil) {
        self.id = UUID()
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetDate = targetDate
        self.description = description
        self.deposits = []
        self.forecastDate = nil
        self.priority = priority
        self.type = type
        self.skipInPeriod = false
        self.requiredPerMonth = nil
        self.actualPerMonth = nil
        self.travelSubgoals = travelSubgoals
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        targetAmount = try container.decode(Double.self, forKey: .targetAmount)
        currentAmount = try container.decode(Double.self, forKey: .currentAmount)
        targetDate = try container.decode(Date.self, forKey: .targetDate)
        description = try container.decode(String.self, forKey: .description)
        deposits = try container.decode([Deposit].self, forKey: .deposits)
        forecastDate = try container.decodeIfPresent(Date.self, forKey: .forecastDate)
        // Обратная совместимость
        priority = try container.decodeIfPresent(GoalPriority.self, forKey: .priority) ?? .important
        type = try container.decodeIfPresent(GoalType.self, forKey: .type) ?? .regular
        skipInPeriod = try container.decodeIfPresent(Bool.self, forKey: .skipInPeriod) ?? false
        requiredPerMonth = try container.decodeIfPresent(Double.self, forKey: .requiredPerMonth)
        actualPerMonth = try container.decodeIfPresent(Double.self, forKey: .actualPerMonth)
        travelSubgoals = try container.decodeIfPresent([TravelSubgoal].self, forKey: .travelSubgoals)
    }
    
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    var isAchieved: Bool {
        currentAmount >= targetAmount
    }
    
    var isOverdue: Bool {
        guard let forecast = forecastDate else { return false }
        return forecast > targetDate
    }
} 
