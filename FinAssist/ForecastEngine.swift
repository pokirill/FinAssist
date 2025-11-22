import Foundation

class ForecastEngine {
    static var timelineLogEnabled = false
    static var timelineLogMonths = 3
    static func dayByDayForecast(
        events: [Date: [Event]],
        goals: [Goal],
        wishlistItems: [WishlistItem] = [],
        includeNiceToHaveInPlan: Bool = false,
        from startDate: Date,
        to endDate: Date,
        skipEmergencyFundInPeriod: Bool = false
    ) -> ([Goal], [WishlistItem], [Date: Double], [Date: Double]) {
        // Создаем копии целей с исходными currentAmount для прогноза
        var sortedGoals = sortGoals(goals.map { goal in
            var copy = goal
            // Сохраняем исходный currentAmount, но сбрасываем forecastDate для нового расчета
            copy.forecastDate = nil
            copy.requiredPerMonth = nil
            copy.actualPerMonth = nil
            
            // Пропускаем подушку в этот период если установлен флаг
            if copy.type == .emergencyFund && skipEmergencyFundInPeriod {
                copy.skipInPeriod = true
            }
            
            return copy
        })
        
        let calendar = Calendar.current
        
        // ВАЖНО: Рассчитываем requiredPerMonth и actualPerMonth ДО симуляции!
        // Считаем свободный кэш из событий (до симуляции)
        var totalFreeCash: Double = 0
        for (eventDate, dayEvents) in events where eventDate >= startDate && eventDate <= endDate {
            let incomes = dayEvents.filter { $0.type == .income || $0.type == .bonus }.reduce(0) { $0 + $1.amount }
            let expenses = dayEvents.filter { $0.type == .expense || $0.type == .credit }.reduce(0) { $0 + $1.amount }
            totalFreeCash += (incomes - expenses)
        }
        let totalDays = max(1, calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 30)
        let totalMonths = Double(totalDays) / 30.0
        let freePerMonth = totalFreeCash / max(1, totalMonths)
        let logCutoffDate = calendar.date(byAdding: .month, value: timelineLogMonths, to: startDate) ?? endDate
        
        print("DEBUG: totalFreeCash=\(totalFreeCash), freePerMonth=\(freePerMonth), totalMonths=\(totalMonths)")
        print("DEBUG: Период симуляции: \(startDate) -> \(endDate)")
        
        // Рассчитываем requiredPerMonth для каждой цели
        for i in 0..<sortedGoals.count {
            var goal = sortedGoals[i]
            
            let originalCurrentAmount = goals.first(where: { $0.id == goal.id })?.currentAmount ?? 0
            let remainingNeeded = max(0, goal.targetAmount - originalCurrentAmount)
            
            print("DEBUG Goal \(goal.name): target=\(goal.targetAmount), current=\(originalCurrentAmount), remaining=\(remainingNeeded)")
            
            if remainingNeeded <= 0 {
                goal.requiredPerMonth = 0
                print("  -> Already achieved, requiredPerMonth = 0")
            } else {
                let monthsUntilTarget = calendar.dateComponents([.day], from: startDate, to: goal.targetDate).day.map { max(1, Double($0) / 30.0) } ?? 1
                // НЕ округляем requiredPerMonth - точная цифра для правильного расчета дат
                goal.requiredPerMonth = remainingNeeded / monthsUntilTarget
                print("  -> monthsUntilTarget=\(monthsUntilTarget), requiredPerMonth=\(goal.requiredPerMonth ?? 0)")
            }
            
            sortedGoals[i] = goal
        }
        
        // Распределяем actualPerMonth по приоритетам (для UI-оценки)
        var remaining = freePerMonth
        
        for i in 0..<sortedGoals.count {
            var goal = sortedGoals[i]
            
            let originalCurrentAmount = goals.first(where: { $0.id == goal.id })?.currentAmount ?? 0
            let alreadyAchieved = originalCurrentAmount >= goal.targetAmount
            
            if goal.skipInPeriod && !alreadyAchieved {
                goal.actualPerMonth = 0
            } else if alreadyAchieved {
                goal.actualPerMonth = 0
            } else {
                let needed = goal.requiredPerMonth ?? 0
                // Точное распределение для правильных дат
                let alloc = min(needed, max(0, remaining))
                goal.actualPerMonth = alloc
                remaining -= alloc
            }
            
            sortedGoals[i] = goal
        }
        
        // Теперь начинаем симуляцию с уже известными requiredPerMonth
        var cash: Double = 0
        var wishlistCopy = wishlistItems
            .sorted { $0.createdAt < $1.createdAt }
            .map { item in
                var copy = item
                copy.forecastDate = nil
                return copy
            }
        var freeCashByDate: [Date: Double] = [:]
        var accumulatedByDate: [Date: Double] = [:] // Накопления за день
        var date = startDate
        var totalAccumulated: Double = 0 // Общая сумма накоплений

        while date <= endDate {
            let dayEvents = events[date] ?? []
            let incomes = dayEvents.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let bonuses = dayEvents.filter { $0.type == .bonus }.reduce(0) { $0 + $1.amount }
            let expenses = dayEvents.filter { $0.type == .expense || $0.type == .credit }.reduce(0) { $0 + $1.amount }
            
            // Свободные деньги за день (доходы - расходы)
            let dailyFreeCash = incomes + bonuses - expenses
            cash += dailyFreeCash
            totalAccumulated += max(0, dailyFreeCash) // Накопления только положительные

            let hasIncomeEvent = dayEvents.contains(where: { $0.type == .income })
            let hasBonusEvent = dayEvents.contains(where: { $0.type == .bonus })
            let shouldAllocate = hasIncomeEvent || hasBonusEvent

            if shouldAllocate {
                let balanceBeforeAllocation = cash
                let goalAllocations = allocateToGoalsOnIncomeEvent(
                    balance: &cash,
                    goals: &sortedGoals,
                    eventDate: date,
                    includeNiceToHave: includeNiceToHaveInPlan
                )
                let wishlistAllocations = allocateToWishlistOnIncomeEvent(
                    balance: &cash,
                    wishlistItems: &wishlistCopy,
                    eventDate: date
                )
                if timelineLogEnabled && date <= logCutoffDate {
                    logEventTimeline(
                        date: date,
                        eventTypes: dayEvents.map { $0.type },
                        incomes: incomes,
                        bonuses: bonuses,
                        expenses: expenses,
                        balanceBefore: balanceBeforeAllocation,
                        balanceAfter: cash,
                        goals: sortedGoals,
                        goalAllocations: goalAllocations,
                        wishlistItems: wishlistCopy,
                        wishlistAllocations: wishlistAllocations
                    )
                }
            }

            freeCashByDate[date] = cash
            accumulatedByDate[date] = totalAccumulated
            
            // Пересортировка, если какая-то цель закрылась
            sortedGoals = sortGoals(sortedGoals)
            if sortedGoals.allSatisfy({ $0.currentAmount >= $0.targetAmount }) { break }
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        // DEBUG: проверяем что возвращаем
        print("=== DEBUG ForecastEngine ===")
        print("Returning \(sortedGoals.count) goals:")
        for goal in sortedGoals {
            let originalCurrent = goals.first(where: { $0.id == goal.id })?.currentAmount ?? 0
            let forecastStr = goal.forecastDate != nil ? DateFormatter.localizedString(from: goal.forecastDate!, dateStyle: .short, timeStyle: .none) : "нет"
            print("  \(goal.name):")
            print("    - original: \(originalCurrent)₽, forecasted: \(goal.currentAmount)₽")
            print("    - req: \(goal.requiredPerMonth ?? 0)₽/мес, act: \(goal.actualPerMonth ?? 0)₽/мес")
            print("    - forecast date: \(forecastStr), target: \(DateFormatter.localizedString(from: goal.targetDate, dateStyle: .short, timeStyle: .none))")
        }
        print("============================")
        
        return (sortedGoals, wishlistCopy, freeCashByDate, accumulatedByDate)
    }

    private static func sortGoals(_ goals: [Goal]) -> [Goal] {
        // Сортируем по приоритету, затем по дате внутри приоритета
        let priorityOrder: [GoalPriority: Int] = [
            .critical: 0,
            .important: 1,
            .niceToHave: 2
        ]
        
        return goals.sorted { goal1, goal2 in
            let priority1 = priorityOrder[goal1.priority] ?? 999
            let priority2 = priorityOrder[goal2.priority] ?? 999
            
            if priority1 != priority2 {
                return priority1 < priority2
            }
            
            // Если приоритеты одинаковые, сортируем по дате
            return goal1.targetDate < goal2.targetDate
        }
    }

    private static func allocateToGoalsOnIncomeEvent(balance: inout Double, goals: inout [Goal], eventDate: Date, includeNiceToHave: Bool) -> [UUID: Double] {
        guard balance > 0 else { return [:] }
        let priorityOrder: [GoalPriority: Int] = [
            .critical: 0,
            .important: 1,
            .niceToHave: 2
        ]
        
        let eligibleIndices = goals.indices.filter { index in
            let goal = goals[index]
            if goal.priority == .niceToHave && !includeNiceToHave { return false }
            if goal.skipInPeriod && !goal.isAchieved { return false }
            return !goal.isAchieved
        }
        
        var allocations: [UUID: Double] = [:]
        let sortedIndices = eligibleIndices.sorted { lhs, rhs in
            let left = goals[lhs]
            let right = goals[rhs]
            let priorityLeft = priorityOrder[left.priority] ?? 999
            let priorityRight = priorityOrder[right.priority] ?? 999
            if priorityLeft != priorityRight {
                return priorityLeft < priorityRight
            }
            return left.targetDate < right.targetDate
        }
        
        for index in sortedIndices {
            guard balance > 0 else { break }
            var goal = goals[index]
            if goal.currentAmount >= goal.targetAmount { continue }
            
            let remainingNeeded = goal.targetAmount - goal.currentAmount
            guard remainingNeeded > 0 else { continue }
            
            let allocation = min(balance, remainingNeeded)
            goal.currentAmount += allocation
            balance -= allocation
            allocations[goal.id, default: 0] += allocation

            if goal.currentAmount >= goal.targetAmount && goal.forecastDate == nil {
                goal.forecastDate = eventDate
            }
            goals[index] = goal
        }
        return allocations
    }

    private static func allocateToWishlistOnIncomeEvent(balance: inout Double, wishlistItems: inout [WishlistItem], eventDate: Date) -> [UUID: Double] {
        guard balance > 0 else { return [:] }

        var allocations: [UUID: Double] = [:]

        for index in wishlistItems.indices {
            guard balance > 0 else { break }
            var item = wishlistItems[index]
            let remainingNeeded = max(0, item.amount - item.saved)
            guard remainingNeeded > 0 else { continue }

            let allocation = min(balance, remainingNeeded)
            item.saved += allocation
            balance -= allocation

            if item.saved >= item.amount && item.forecastDate == nil {
                item.forecastDate = eventDate
            }
            wishlistItems[index] = item
        }
        return allocations
    }

    private static func logEventTimeline(
        date: Date,
        eventTypes: [EventType],
        incomes: Double,
        bonuses: Double,
        expenses: Double,
        balanceBefore: Double,
        balanceAfter: Double,
        goals: [Goal],
        goalAllocations: [UUID: Double],
        wishlistItems: [WishlistItem],
        wishlistAllocations: [UUID: Double]
    ) {
        guard timelineLogEnabled else { return }

        let typeNames = Set(eventTypes.map { $0.rawValue }).sorted().joined(separator: ", ")
        let dateString = AppUtils.shortDateFormatter.string(from: date)

        let goalDetails = goalAllocations.compactMap { id, amount in
            guard amount > 0, let name = goals.first(where: { $0.id == id })?.name else { return nil }
            return "\(name): \(Int(amount)) ₽"
        }.joined(separator: " | ")

        let wishlistDetails = wishlistAllocations.compactMap { id, amount in
            guard amount > 0, let name = wishlistItems.first(where: { $0.id == id })?.name else { return nil }
            return "\(name): \(Int(amount)) ₽"
        }.joined(separator: " | ")

        print("""
        [ForecastEvent] \(dateString) types=[\(typeNames)] incomes=\(Int(incomes)) bonuses=\(Int(bonuses)) expenses=\(Int(expenses))
          balance: \(Int(balanceBefore)) -> \(Int(balanceAfter))
          goals: \(goalDetails.isEmpty ? "—" : goalDetails)
          wishlist: \(wishlistDetails.isEmpty ? "—" : wishlistDetails)
        """)
    }
}