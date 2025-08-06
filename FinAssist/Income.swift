import Foundation

struct Income: Codable, Identifiable {
    let id: UUID
    var salary: Salary?
    var bonuses: [Bonus]
    
    var totalMonthlyIncome: Double {
        let salaryAmount = salary?.monthlyAmount ?? 0
        let regularBonuses = bonuses.filter { $0.isRegular }.reduce(0) { $0 + $1.monthlyAmount }
        return salaryAmount + regularBonuses
    }
    
    func incomeForMonth(_ date: Date) -> Double {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        var totalIncome: Double = 0
        
        if let salary = salary {
            totalIncome += salary.monthlyAmount
        }
        
        for bonus in bonuses {
            if bonus.isRegular {
                if let period = bonus.period {
                    switch period {
                    case .monthly:
                        totalIncome += bonus.amount
                    case .quarterly:
                        if month % 3 == 1 {
                            totalIncome += bonus.amount
                        }
                    case .yearly:
                        if month == 12 {
                            totalIncome += bonus.amount
                        }
                    }
                }
            } else {
                if let bonusDate = bonus.date {
                    let bonusMonth = calendar.component(.month, from: bonusDate)
                    let bonusYear = calendar.component(.year, from: bonusDate)
                    
                    if bonusMonth == month && bonusYear == year {
                        totalIncome += bonus.amount
                    }
                }
            }
        }
        
        return totalIncome
    }
    
    init() {
        self.id = UUID()
        self.salary = nil
        self.bonuses = []
    }
}

struct Salary: Codable, Identifiable {
    let id: UUID
    var monthlyAmount: Double
    var advanceDate: Int
    var advancePercentage: Double
    var salaryDate: Int
    var salaryPercentage: Double
    
    init(monthlyAmount: Double, advanceDate: Int, advancePercentage: Double, salaryDate: Int, salaryPercentage: Double) {
        self.id = UUID()
        self.monthlyAmount = monthlyAmount
        self.advanceDate = advanceDate
        self.advancePercentage = advancePercentage
        self.salaryDate = salaryDate
        self.salaryPercentage = salaryPercentage
    }
}

struct Bonus: Codable, Identifiable {
    let id: UUID
    var name: String
    var amount: Double
    var isRegular: Bool
    var date: Date?
    var period: BonusPeriod?
    
    var monthlyAmount: Double {
        guard isRegular, let period = period else { return 0 }
        switch period {
        case .monthly:
            return amount
        case .quarterly:
            return amount / 3
        case .yearly:
            return amount / 12
        }
    }
    
    init(name: String, amount: Double, isRegular: Bool, date: Date? = nil, period: BonusPeriod? = nil) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.isRegular = isRegular
        self.date = date
        self.period = period
    }
}

enum BonusPeriod: String, CaseIterable, Codable {
    case monthly = "Месяц"
    case quarterly = "Квартал"
    case yearly = "Год"
}
