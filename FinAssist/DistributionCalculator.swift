import Foundation

enum DistributionPeriod: String, CaseIterable {
    case month = "Месяц"
    case advance = "Аванс"
    case salary = "Зарплата"
}

struct DistributionCalculator {
    let income: Income
    let expense: Expense
    let credits: [Credit]
    let goals: [Goal]
    let emergencyFundEnabled: Bool
    let selectedPeriod: DistributionPeriod
    
    // MARK: - Public Interface
    
    var periodIncome: Double {
        let total = income.totalMonthlyIncome
        guard let salary = income.salary else { return total }
        
        switch selectedPeriod {
        case .month:
            return total
        case .advance:
            return salary.monthlyAmount * (salary.advancePercentage / 100.0)
        case .salary:
            return salary.monthlyAmount * (salary.salaryPercentage / 100.0)
        }
    }
    
    var periodIncomeShare: Double {
        let total = max(income.totalMonthlyIncome, 1)
        return periodIncome / total
    }
    
    var capacity: Double {
        periodIncome - totalPlanned - totalRegular - walletTarget - emergencyAmount
    }

    var deficit: Double {
        max(0, -capacity)
    }

    private var calendar: Calendar { Calendar.current }
    
    private var monthStart: Date {
        let components = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: components)!
    }

    private var nextMonthStart: Date {
        calendar.date(byAdding: .month, value: 1, to: monthStart)!
    }

    private func dateFor(day: Int, monthOffset: Int = 0) -> Date? {
        guard let base = calendar.date(byAdding: .month, value: monthOffset, to: monthStart) else { return nil }
        var components = calendar.dateComponents([.year, .month], from: base)
        if let range = calendar.range(of: .day, in: .month, for: base) {
            components.day = min(max(day, range.lowerBound), range.upperBound - 1)
        } else {
            components.day = day
        }
        return calendar.date(from: components)
    }

    private var computedPeriodInterval: DateInterval? {
        switch selectedPeriod {
        case .month:
            return DateInterval(start: monthStart, end: nextMonthStart)
        case .advance:
            guard let salary = income.salary,
                  let advance = dateFor(day: salary.advanceDate, monthOffset: 0),
                  let salaryCurrent = dateFor(day: salary.salaryDate, monthOffset: 0),
                  let salaryNext = dateFor(day: salary.salaryDate, monthOffset: 1) else {
                return nil
            }
            let end = salaryCurrent > advance ? salaryCurrent : salaryNext
            return DateInterval(start: advance, end: end)
        case .salary:
            guard let salary = income.salary,
                  let salaryDate = dateFor(day: salary.salaryDate, monthOffset: 0),
                  let advanceCurrent = dateFor(day: salary.advanceDate, monthOffset: 0),
                  let advanceNext = dateFor(day: salary.advanceDate, monthOffset: 1) else {
                return nil
            }
            let end = advanceCurrent > salaryDate ? advanceCurrent : advanceNext
            return DateInterval(start: salaryDate, end: end)
        }
    }

    private var resolvedPeriodInterval: DateInterval {
        computedPeriodInterval ?? DateInterval(start: monthStart, end: nextMonthStart)
    }

    private var daysInSelectedPeriod: Double {
        let diff = calendar.dateComponents([.day], from: resolvedPeriodInterval.start, to: resolvedPeriodInterval.end).day ?? 0
        return max(1, Double(diff))
    }

    private var daysInMonth: Double {
        let diff = calendar.dateComponents([.day], from: monthStart, to: nextMonthStart).day ?? 0
        return max(1, Double(diff))
    }

    private var categoryDayPairs: [(category: ExpenseCategory, amount: Double, day: Int?)] {
        [
            (category: .rent, amount: expense.rent, day: expense.rentDay),
            (category: .loans, amount: expense.loans, day: expense.loansDay),
            (category: .utilities, amount: expense.utilities, day: expense.utilitiesDay),
            (category: .groceries, amount: expense.groceries, day: expense.groceriesDay),
            (category: .communication, amount: expense.communication, day: expense.communicationDay),
            (category: .subscriptions, amount: expense.subscriptions, day: expense.subscriptionsDay),
            (category: .transport, amount: expense.transport, day: expense.transportDay),
            (category: .hobbies, amount: expense.hobbies, day: expense.hobbiesDay),
            (category: .entertainment, amount: expense.entertainment, day: expense.entertainmentDay),
            (category: .beauty, amount: expense.beauty, day: expense.beautyDay),
            (category: .marketplaces, amount: expense.marketplaces, day: expense.marketplacesDay)
        ]
    }

    private var monthlyPlannedCategoriesTotal: Double {
        categoryDayPairs.reduce(0) {
            let dayAmount = $1.day != nil ? $1.amount : 0
            return $0 + dayAmount
        }
    }

    private var monthlyFlexibleRegularTotal: Double {
        expense.additional.reduce(0) { $0 + $1.amount }
    }

    private var monthlyCreditsTotal: Double {
        credits.filter { $0.endDate == nil || $0.endDate! > Date() }
            .reduce(0) { $0 + $1.monthlyAmount }
    }

    private var monthlyPlannedTotal: Double {
        monthlyPlannedCategoriesTotal + monthlyCreditsTotal
    }

    private var monthlyGoalsRequirements: [(goal: Goal, amount: Double)] {
        let activeGoals = goals.filter { $0.type != .emergencyFund && !$0.isAchieved }
        let sortedGoals = activeGoals.sorted { g1, g2 in
            if g1.priority != g2.priority {
                return g1.priority.rawValue < g2.priority.rawValue
            }
            return g1.targetDate < g2.targetDate
        }
        return sortedGoals.map { goal in
            (goal, calculateMonthlyReq(for: goal))
        }
    }

    private var monthlyGoalsTotal: Double {
        monthlyGoalsRequirements.reduce(0) { $0 + $1.amount }
    }

    private var monthlyEmergencyRequirement: Double {
        guard emergencyFundEnabled, let goal = goals.first(where: { $0.type == .emergencyFund && !$0.isAchieved }) else {
            return 0
        }
        return calculateMonthlyReq(for: goal)
    }

    private var monthlyWalletPlanValue: Double {
        max(0, expense.walletDaily)
    }
    
    var monthlyWalletPlan: Double {
        monthlyWalletPlanValue
    }
    
    // Planned (Specific to Period)
    var plannedCategoryExpenses: [(name: String, amount: Double, day: Int)] {
        var list: [(name: String, amount: Double, day: Int)] = []
        
        func add(_ amount: Double, _ day: Int?, _ name: String) {
            guard amount > 0 else { return }
            if let d = day, isDayInPeriod(d) {
                list.append((name: name, amount: amount, day: d))
            }
        }
        
        add(expense.rent, expense.rentDay, "Аренда")
        add(expense.utilities, expense.utilitiesDay, "Коммуналка")
        add(expense.groceries, expense.groceriesDay, "Продукты")
        add(expense.communication, expense.communicationDay, "Связь")
        add(expense.subscriptions, expense.subscriptionsDay, "Подписки")
        add(expense.transport, expense.transportDay, "Транспорт")
        add(expense.hobbies, expense.hobbiesDay, "Хобби")
        add(expense.entertainment, expense.entertainmentDay, "Развлечения")
        add(expense.beauty, expense.beautyDay, "Бьюти")
        add(expense.marketplaces, expense.marketplacesDay, "Маркетплейсы")
        
        return list.sorted { $0.day < $1.day }
    }
    
    var creditExpenses: [(name: String, amount: Double, day: Int)] {
        var list: [(name: String, amount: Double, day: Int)] = []
        for credit in credits {
            if credit.endDate == nil || credit.endDate! > Date() {
                if isDayInPeriod(credit.day) {
                    list.append((name: credit.name, amount: credit.monthlyAmount, day: credit.day))
                }
            }
        }
        return list.sorted { $0.day < $1.day }
    }
    
    var totalPlanned: Double {
        plannedCategoryExpenses.reduce(0) { $0 + $1.amount } +
        creditExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // Regular (Proportional)
    var regularExpenses: [(name: String, amount: Double)] {
        var list: [(String, Double)] = []
        let share = periodIncomeShare
        
        func add(_ amount: Double, _ day: Int?, _ name: String, category: ExpenseCategory) {
            guard amount > 0, day == nil else { return }
            list.append((name, amount * share))
        }
        
        add(expense.rent, expense.rentDay, "Аренда", category: .rent)
        add(expense.utilities, expense.utilitiesDay, "Коммуналка", category: .utilities)
        add(expense.groceries, expense.groceriesDay, "Продукты", category: .groceries)
        add(expense.communication, expense.communicationDay, "Связь", category: .communication)
        add(expense.subscriptions, expense.subscriptionsDay, "Подписки", category: .subscriptions)
        add(expense.transport, expense.transportDay, "Транспорт", category: .transport)
        add(expense.hobbies, expense.hobbiesDay, "Хобби", category: .hobbies)
        add(expense.entertainment, expense.entertainmentDay, "Развлечения", category: .entertainment)
        add(expense.beauty, expense.beautyDay, "Бьюти", category: .beauty)
        add(expense.marketplaces, expense.marketplacesDay, "Маркетплейсы", category: .marketplaces)
        
        return list
    }
    
    var totalRegular: Double {
        regularExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // Wallet (Uniform Time-based)
    var walletTarget: Double {
        let walletDaily = monthlyWalletPlanValue / daysInMonth
        return walletDaily * daysInSelectedPeriod
    }
    
    // Emergency
    var emergencyAmount: Double {
        monthlyEmergencyRequirement * periodIncomeShare
    }
    
    // Goals
    private var desiredGoalsAllocations: [(goal: Goal, amount: Double)] {
        let share = periodIncomeShare
        return monthlyGoalsRequirements.map { goalInfo in
            (goalInfo.goal, goalInfo.amount * share)
        }
    }
    
    private var desiredGoalsTotal: Double {
        desiredGoalsAllocations.reduce(0) { $0 + $1.amount }
    }

    private var allowedGoalsTotal: Double {
        max(0, min(capacity, desiredGoalsTotal))
    }

    var goalsAllocations: [(goal: Goal, amount: Double)] {
        guard desiredGoalsTotal > 0 else {
            return desiredGoalsAllocations.map { ($0.goal, 0) }
        }
        let scale = desiredGoalsTotal > 0 ? allowedGoalsTotal / desiredGoalsTotal : 0
        return desiredGoalsAllocations.map { ($0.goal, $0.amount * scale) }
    }
    
    var totalGoals: Double {
        goalsAllocations.reduce(0) { $0 + $1.amount }
    }
    
    var unexpectedAmount: Double {
        guard capacity > 0 else { return 0 }
        return max(0, capacity - totalGoals)
    }
    
    // MARK: - Helpers
    
    private func getPeriodInterval() -> (start: Int, end: Int)? {
        guard let sal = income.salary else { return nil }
        switch selectedPeriod {
        case .month: return nil
        case .advance: return (sal.advanceDate, sal.salaryDate)
        case .salary: return (sal.salaryDate, sal.advanceDate)
        }
    }
    
    private func isDayInPeriod(_ day: Int) -> Bool {
        guard let (start, end) = getPeriodInterval() else { return true }
        if start < end {
            return day >= start && day < end
        } else {
            return day >= start || day < end
        }
    }
    
    private func add(_ amount: Double, _ day: Int?, _ name: String, to list: inout [(String, Double, Int)]) {
        guard amount > 0 else { return }
        if let d = day {
            if isDayInPeriod(d) {
                list.append((name, amount, d))
            }
        }
    }
    
    private func calculateMonthlyReq(for goal: Goal) -> Double {
        let remaining = max(0, goal.targetAmount - goal.currentAmount)
        let days = Calendar.current.dateComponents([.day], from: Date(), to: goal.targetDate).day ?? 30
        let months = max(1, Double(days) / 30.0)
        return remaining / months
    }
}


