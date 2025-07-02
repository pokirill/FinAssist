import Foundation

struct Goal: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var targetDate: Date
    var description: String
    var deposits: [Deposit]
    var forecastDate: Date?

    init(name: String, targetAmount: Double, currentAmount: Double = 0, targetDate: Date, description: String = "") {
        self.id = UUID()
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetDate = targetDate
        self.description = description
        self.deposits = []
        self.forecastDate = nil
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
