import Testing
import Foundation
@testable import FinAssist

struct ForecastEngineTests {
    private var calendar: Calendar { Calendar(identifier: .gregorian) }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)!
    }

    @Test func GoalForecast_isOnIncomeEvent() async throws {
        let startDate = makeDate(year: 2025, month: 1, day: 1)
        let endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!

        var income = Income()
        income.salary = Salary(monthlyAmount: 200_000, advanceDate: 10, advancePercentage: 50, salaryDate: 20, salaryPercentage: 50)
        income.payouts = [
            Payout(day: 10, share: 0.5),
            Payout(day: 20, share: 0.5)
        ]

        let goal = Goal(name: "Накопить", targetAmount: 150_000, currentAmount: 0, targetDate: calendar.date(byAdding: .month, value: 3, to: startDate)!)

        let events = EventBuilder.buildEvents(
            incomes: [income],
            bonuses: [],
            expenses: [],
            credits: [],
            from: startDate,
            to: endDate
        )

        let expectedForecastDate = makeDate(year: 2025, month: 1, day: 20)
        let (updatedGoals, _, _, _) = ForecastEngine.dayByDayForecast(
            events: events,
            goals: [goal],
            wishlistItems: [],
            from: startDate,
            to: endDate
        )

        guard let forecast = updatedGoals.first?.forecastDate else {
            #expect(false)
            return
        }
        #expect(calendar.isDate(forecast, inSameDayAs: expectedForecastDate))
    }

    @Test func NoNegativeBalance_withGoals() async throws {
        let startDate = makeDate(year: 2025, month: 2, day: 1)
        let endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!

        var income = Income()
        income.salary = Salary(monthlyAmount: 100_000, advanceDate: 10, advancePercentage: 50, salaryDate: 20, salaryPercentage: 50)
        income.payouts = [
            Payout(day: 10, share: 0.5),
            Payout(day: 20, share: 0.5)
        ]

        var expense = Expense()
        expense.rent = 60_000
        expense.rentDay = 10
        expense.utilities = 40_000
        expense.utilitiesDay = 20

        let goal = Goal(name: "Крупная покупка", targetAmount: 50_000, currentAmount: 0, targetDate: calendar.date(byAdding: .month, value: 6, to: startDate)!)

        let events = EventBuilder.buildEvents(
            incomes: [income],
            bonuses: [],
            expenses: [expense],
            credits: [],
            from: startDate,
            to: endDate
        )

        let (updatedGoals, _, freeCashByDate, _) = ForecastEngine.dayByDayForecast(
            events: events,
            goals: [goal],
            wishlistItems: [],
            from: startDate,
            to: endDate
        )

        #expect(updatedGoals.first?.currentAmount == 0)
        let minBalance = freeCashByDate.values.min() ?? 0
        #expect(minBalance >= 0)
    }

    @Test func WishlistForecast_sequentialAndDistinct() async throws {
        let startDate = makeDate(year: 2025, month: 3, day: 1)
        let endDate = calendar.date(byAdding: .month, value: 3, to: startDate)!

        var income = Income()
        income.salary = Salary(monthlyAmount: 20_000, advanceDate: 10, advancePercentage: 50, salaryDate: 20, salaryPercentage: 50)
        income.payouts = [
            Payout(day: 10, share: 0.5),
            Payout(day: 20, share: 0.5)
        ]

        let wishlistItems = [
            WishlistItem(name: "Вечеринка", amount: 10_000, createdAt: startDate),
            WishlistItem(name: "Камера", amount: 30_000, createdAt: startDate.addingTimeInterval(60 * 60 * 24))
        ]

        let events = EventBuilder.buildEvents(
            incomes: [income],
            bonuses: [],
            expenses: [],
            credits: [],
            from: startDate,
            to: endDate
        )

        let (_, updatedWishlistItems, _, _) = ForecastEngine.dayByDayForecast(
            events: events,
            goals: [],
            wishlistItems: wishlistItems,
            from: startDate,
            to: endDate
        )

        guard let firstForecast = updatedWishlistItems.first?.forecastDate,
              let secondForecast = updatedWishlistItems.last?.forecastDate else {
            #expect(false)
            return
        }

        #expect(firstForecast < secondForecast)
        #expect(!calendar.isDate(firstForecast, inSameDayAs: secondForecast))
    }

    @Test func IntraPrioritySprint() async throws {
        let startDate = makeDate(year: 2025, month: 1, day: 1)
        let endDate = calendar.date(byAdding: .month, value: 4, to: startDate)!

        var income = Income()
        income.salary = Salary(monthlyAmount: 100_000, advanceDate: 10, advancePercentage: 50, salaryDate: 20, salaryPercentage: 50)
        income.payouts = [
            Payout(day: 10, share: 0.5),
            Payout(day: 20, share: 0.5)
        ]

        let goalA = Goal(
            name: "Срочная цель",
            targetAmount: 70_000,
            currentAmount: 0,
            targetDate: calendar.date(byAdding: .month, value: 1, to: startDate)!,
            priority: .important
        )

        let goalB = Goal(
            name: "Долгосрочная цель",
            targetAmount: 80_000,
            currentAmount: 0,
            targetDate: calendar.date(byAdding: .month, value: 6, to: startDate)!,
            priority: .important
        )

        let events = EventBuilder.buildEvents(
            incomes: [income],
            bonuses: [],
            expenses: [],
            credits: [],
            from: startDate,
            to: endDate
        )

        let (updatedGoals, _, _, _) = ForecastEngine.dayByDayForecast(
            events: events,
            goals: [goalA, goalB],
            wishlistItems: [],
            from: startDate,
            to: endDate
        )

        let mapped = Dictionary(uniqueKeysWithValues: updatedGoals.map { ($0.name, $0) })
        guard let updatedA = mapped[goalA.name],
              let updatedB = mapped[goalB.name],
              let forecastA = updatedA.forecastDate,
              let forecastB = updatedB.forecastDate else {
            #expect(false)
            return
        }

        #expect(updatedA.currentAmount >= updatedA.targetAmount)
        #expect(updatedB.currentAmount >= updatedB.targetAmount)
        #expect(forecastA < forecastB)
    }

    @Test func NiceToHaveExcludedByDefault() async throws {
        let startDate = makeDate(year: 2025, month: 4, day: 1)
        let endDate = calendar.date(byAdding: .month, value: 2, to: startDate)!

        var income = Income()
        income.salary = Salary(monthlyAmount: 100_000, advanceDate: 10, advancePercentage: 50, salaryDate: 20, salaryPercentage: 50)
        income.payouts = [
            Payout(day: 10, share: 0.5),
            Payout(day: 20, share: 0.5)
        ]

        let niceGoal = Goal(
            name: "Ноут",
            targetAmount: 100_000,
            currentAmount: 0,
            targetDate: calendar.date(byAdding: .month, value: 6, to: startDate)!,
            priority: .niceToHave
        )

        let events = EventBuilder.buildEvents(
            incomes: [income],
            bonuses: [],
            expenses: [],
            credits: [],
            from: startDate,
            to: endDate
        )

        let (updatedGoals, _, _, _) = ForecastEngine.dayByDayForecast(
            events: events,
            goals: [niceGoal],
            wishlistItems: [],
            from: startDate,
            to: endDate
        )

        guard let updated = updatedGoals.first else {
            #expect(false)
            return
        }

        #expect(updated.priority == .niceToHave)
        #expect(updated.currentAmount == 0)
        #expect(updated.forecastDate == nil)
    }

    @Test func BonusGoesOnlyToGoals() async throws {
        let startDate = makeDate(year: 2025, month: 1, day: 1)
        let endDate = calendar.date(byAdding: .month, value: 2, to: startDate)!
        let bonusDate = makeDate(year: 2025, month: 1, day: 15)

        var income = Income()
        income.salary = Salary(monthlyAmount: 0, advanceDate: 10, advancePercentage: 50, salaryDate: 20, salaryPercentage: 50)
        income.payouts = [
            Payout(day: 10, share: 0.5),
            Payout(day: 20, share: 0.5)
        ]

        let bonus = Bonus(name: "Премия", amount: 50_000, type: .oneTime, date: bonusDate, period: nil, start: nil, end: nil)

        let goal = Goal(
            name: "Бонусная цель",
            targetAmount: 40_000,
            currentAmount: 0,
            targetDate: calendar.date(byAdding: .month, value: 3, to: startDate)!,
            priority: .critical
        )

        let item = WishlistItem(name: "Хотелка", amount: 30_000, createdAt: startDate)

        let events = EventBuilder.buildEvents(
            incomes: [income],
            bonuses: [bonus],
            expenses: [],
            credits: [],
            from: startDate,
            to: endDate
        )

        let (updatedGoals, updatedWishlistItems, freeCashByDate, _) = ForecastEngine.dayByDayForecast(
            events: events,
            goals: [goal],
            wishlistItems: [item],
            from: startDate,
            to: endDate
        )

        guard let updatedGoal = updatedGoals.first else {
            #expect(false)
            return
        }
        guard let updatedItem = updatedWishlistItems.first else {
            #expect(false)
            return
        }

        #expect(updatedGoal.currentAmount == 40_000)
        #expect(updatedItem.saved == 10_000)
        #expect(freeCashByDate[bonusDate] == 0)
    }

    @Test func ForecastDatesOnlyOnIncomeOrBonus_global() async throws {
        let startDate = makeDate(year: 2025, month: 2, day: 1)
        let endDate = calendar.date(byAdding: .month, value: 3, to: startDate)!
        let bonusDate = makeDate(year: 2025, month: 2, day: 17)

        var income = Income()
        income.salary = Salary(monthlyAmount: 120_000, advanceDate: 10, advancePercentage: 50, salaryDate: 20, salaryPercentage: 50)
        income.payouts = [
            Payout(day: 10, share: 0.5),
            Payout(day: 20, share: 0.5)
        ]

        let bonus = Bonus(name: "Премия", amount: 20_000, type: .oneTime, date: bonusDate, period: nil, start: nil, end: nil)

        let goal = Goal(
            name: "Цель с датой",
            targetAmount: 50_000,
            currentAmount: 0,
            targetDate: calendar.date(byAdding: .month, value: 6, to: startDate)!,
            priority: .important
        )

        let wishlistItems = [
            WishlistItem(name: "Хотелка-1", amount: 10_000, createdAt: startDate),
            WishlistItem(name: "Хотелка-2", amount: 15_000, createdAt: startDate.addingTimeInterval(60 * 60 * 24))
        ]

        let events = EventBuilder.buildEvents(
            incomes: [income],
            bonuses: [bonus],
            expenses: [],
            credits: [],
            from: startDate,
            to: endDate
        )

        let allowedDates = Set(events.compactMap { (date, dayEvents) -> Date? in
            guard dayEvents.contains(where: { $0.type == .income || $0.type == .bonus }) else { return nil }
            return calendar.startOfDay(for: date)
        })

        let (updatedGoals, updatedWishlistItems, _, _) = ForecastEngine.dayByDayForecast(
            events: events,
            goals: [goal],
            wishlistItems: wishlistItems,
            from: startDate,
            to: endDate
        )

        for wishlist in updatedWishlistItems {
            if let forecast = wishlist.forecastDate {
                let forecastDay = calendar.startOfDay(for: forecast)
                #expect(allowedDates.contains(forecastDay))
            }
        }

        for goal in updatedGoals {
            if let forecast = goal.forecastDate {
                let forecastDay = calendar.startOfDay(for: forecast)
                #expect(allowedDates.contains(forecastDay))
            }
        }
    }

    @Test func BalanceNeverNegative_global() async throws {
        let startDate = makeDate(year: 2025, month: 5, day: 1)
        let endDate = calendar.date(byAdding: .month, value: 6, to: startDate)!
        let seeds: [UInt64] = [42, 202, 999]

        for seed in seeds {
            var rng = SeededGenerator(seed: seed)
            let scenario = ForecastTestHelpers.randomScenario(rng: &rng, startDate: startDate, endDate: endDate)
            let events = EventBuilder.buildEvents(
                incomes: [scenario.income],
                bonuses: scenario.bonuses,
                expenses: [scenario.expense],
                credits: scenario.credits,
                from: startDate,
                to: endDate
            )

            let (_, _, freeCashByDate, _) = ForecastEngine.dayByDayForecast(
                events: events,
                goals: scenario.goals,
                wishlistItems: scenario.wishlistItems,
                from: startDate,
                to: endDate
            )
            let minBalance = freeCashByDate.values.min() ?? 0
            #expect(minBalance >= 0)
        }
    }

    @Test func DistributionMatchesForecast_monthly() async throws {
        let startDate = makeDate(year: 2025, month: 6, day: 1)
        let endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!

        var income = Income()
        income.salary = Salary(monthlyAmount: 130_000, advanceDate: 10, advancePercentage: 50, salaryDate: 25, salaryPercentage: 50)
        income.payouts = [
            Payout(day: 10, share: 0.5),
            Payout(day: 25, share: 0.5)
        ]

        var expense = Expense()
        expense.walletDaily = 30_000
        expense.rent = 40_000
        expense.rentDay = 5

        let credit = Credit(name: "Loan", monthlyAmount: 10_000, day: 15)

        let goalA = Goal(name: "Квартира", targetAmount: 100_000, currentAmount: 0, targetDate: calendar.date(byAdding: .month, value: 12, to: startDate)!, priority: .critical)
        let goalB = Goal(name: "Путешествие", targetAmount: 60_000, currentAmount: 0, targetDate: calendar.date(byAdding: .month, value: 6, to: startDate)!, priority: .important)

        let wishlistItems = [
            WishlistItem(name: "Смартфон", amount: 20_000, createdAt: startDate)
        ]

        let events = EventBuilder.buildEvents(
            incomes: [income],
            bonuses: [],
            expenses: [expense],
            credits: [credit],
            from: startDate,
            to: endDate
        )

        let originalGoals = [goalA, goalB]
        let (updatedGoals, updatedWishlistItems, _, _) = ForecastEngine.dayByDayForecast(
            events: events,
            goals: originalGoals,
            wishlistItems: wishlistItems,
            from: startDate,
            to: endDate
        )

        let goalAllocations = updatedGoals.reduce(0) { sum, updated in
            let original = originalGoals.first(where: { $0.id == updated.id })?.currentAmount ?? 0
            return sum + max(0, updated.currentAmount - original)
        }

        let distribution = DistributionCalculator(
            income: income,
            expense: expense,
            credits: [credit],
            goals: originalGoals,
            emergencyFundEnabled: true,
            selectedPeriod: .month
        )

        #expect(abs(goalAllocations - distribution.totalGoals) < 1)
        let wishlistAllocated = updatedWishlistItems.reduce(0) { $0 + $1.saved }
        #expect(wishlistAllocated <= distribution.totalGoals + 1) // sanity check
    }
}

private struct ForecastTestHelpers {
    static func randomScenario(rng: inout SeededGenerator, startDate: Date, endDate: Date) -> (
        income: Income, expense: Expense, bonuses: [Bonus], credits: [Credit], goals: [Goal], wishlistItems: [WishlistItem]
    ) {
        var income = Income()
        income.salary = Salary(monthlyAmount: 110_000, advanceDate: 10, advancePercentage: 50, salaryDate: 25, salaryPercentage: 50)
        income.payouts = [
            Payout(day: 10, share: 0.5),
            Payout(day: 25, share: 0.5)
        ]

        var expense = Expense()
        expense.walletDaily = Double((rng.next() % 4_000) + 10_000)
        expense.rent = Double((rng.next() % 40_000) + 25_000)
        expense.rentDay = Int((rng.next() % 20) + 1)
        expense.groceries = Double((rng.next() % 15_000) + 5_000)
        expense.groceriesDay = Int((rng.next() % 28) + 1)

        var credits: [Credit] = []
        if rng.next() % 2 == 0 {
            let monthly = Double((rng.next() % 15_000) + 5_000)
            credits.append(Credit(name: "Кредит", monthlyAmount: monthly, day: Int((rng.next() % 20) + 5)))
        }

        let goalA = Goal(
            name: "Цель A",
            targetAmount: 50_000,
            currentAmount: 0,
            targetDate: Calendar.current.date(byAdding: .month, value: 4, to: startDate)!,
            priority: .critical
        )
        let goalB = Goal(
            name: "Цель B",
            targetAmount: 30_000,
            currentAmount: 0,
            targetDate: Calendar.current.date(byAdding: .month, value: 6, to: startDate)!,
            priority: .important
        )

        let wishlistItem = WishlistItem(
            name: "Мелкая хотелка",
            amount: Double((rng.next() % 20_000) + 5_000),
            createdAt: startDate
        )

        return (income, expense, [], credits, [goalA, goalB], [wishlistItem])
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

