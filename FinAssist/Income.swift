import Foundation

struct Income: Codable, Identifiable {
    let id: UUID
    var name: String // добавлено для day-by-day-алгоритма
    var currency: String // добавлено для day-by-day-алгоритма
    var salary: Salary?
    var bonuses: [Bonus]
    var payouts: [Payout] // добавлено для day-by-day-алгоритма
    var totalMonthlyIncome: Double {
        // Только зарплата, так как bonuses могут быть разовыми или периодическими
        // и не должны входить в ежемесячный доход
        let salaryAmount = salary?.monthlyAmount ?? 0
        return salaryAmount
    }
    
    init() {
        self.id = UUID()
        self.name = ""
        self.currency = "RUB"
        self.salary = nil
        self.bonuses = []
        self.payouts = []
    }
}

struct Salary: Codable, Identifiable {
    let id: UUID
    var monthlyAmount: Double
    var advanceDate: Int // 1–28
    var advancePercentage: Double // 0–100
    var salaryDate: Int // 1–28
    var salaryPercentage: Double // 0–100
    
    init(monthlyAmount: Double, advanceDate: Int, advancePercentage: Double, salaryDate: Int, salaryPercentage: Double) {
        self.id = UUID()
        self.monthlyAmount = monthlyAmount
        self.advanceDate = advanceDate
        self.advancePercentage = advancePercentage
        self.salaryDate = salaryDate
        self.salaryPercentage = salaryPercentage
    }
}

struct Payout: Codable {
    var day: Int // 1..31
    var share: Double // 0..1
} 
