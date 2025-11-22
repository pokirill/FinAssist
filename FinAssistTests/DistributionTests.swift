import Testing
import Foundation
@testable import FinAssist

struct DistributionTests {

    @Test func testPlannedExpensesStickToPeriod() async throws {
        var income = Income()
        income.salary = Salary(monthlyAmount: 100_000, advanceDate: 10, salaryDate: 25, advancePercentage: 40, salaryPercentage: 60)
        
        var expense = Expense()
        expense.rent = 30_000
        expense.rentDay = 12
        
        let advanceCalc = DistributionCalculator(
            income: income,
            expense: expense,
            credits: [],
            goals: [],
            emergencyFundEnabled: true,
            selectedPeriod: .advance
        )
        
        let salaryCalc = DistributionCalculator(
            income: income,
            expense: expense,
            credits: [],
            goals: [],
            emergencyFundEnabled: true,
            selectedPeriod: .salary
        )
        
        #expect(advanceCalc.plannedCategoryExpenses.contains { $0.name == "Аренда" })
        #expect(advanceCalc.totalPlanned == 30_000)
        #expect(!salaryCalc.plannedCategoryExpenses.contains { $0.name == "Аренда" })
        #expect(salaryCalc.totalPlanned == 0)
    }

    @Test func testWalletDividesByDays() async throws {
        var income = Income()
        income.salary = Salary(monthlyAmount: 100_000, advanceDate: 10, salaryDate: 25, advancePercentage: 40, salaryPercentage: 60)

        let monthlyWallet = income.totalMonthlyIncome
        let advanceInterval = PeriodHelpers.interval(for: .advance, salary: income.salary!)
        let salaryInterval = PeriodHelpers.interval(for: .salary, salary: income.salary!)
        let daysInMonth = PeriodHelpers.daysInMonth()

        let advanceCalc = DistributionCalculator(
            income: income,
            expense: Expense(),
            credits: [],
            goals: [],
            emergencyFundEnabled: true,
            selectedPeriod: .advance
        )

        let expectedAdvance = monthlyWallet * (PeriodHelpers.days(in: advanceInterval) / daysInMonth)
        #expect(abs(advanceCalc.walletTarget - expectedAdvance) < 0.5)

        let salaryCalc = DistributionCalculator(
            income: income,
            expense: Expense(),
            credits: [],
            goals: [],
            emergencyFundEnabled: true,
            selectedPeriod: .salary
        )

        let expectedSalary = monthlyWallet * (PeriodHelpers.days(in: salaryInterval) / daysInMonth)
        #expect(abs(salaryCalc.walletTarget - expectedSalary) < 0.5)
    }
    
    @Test func testCapacityPreventsNegativeBlocks() async throws {
        var income = Income()
        income.salary = Salary(monthlyAmount: 100_000, advanceDate: 10, salaryDate: 25, advancePercentage: 40, salaryPercentage: 60)

        let advanceCalc = DistributionCalculator(
            income: income,
            expense: Expense(),
            credits: [],
            goals: [],
            emergencyFundEnabled: true,
            selectedPeriod: .advance
        )

        #expect(advanceCalc.capacity < 0)
        #expect(advanceCalc.totalGoals == 0)
        #expect(advanceCalc.unexpectedAmount == 0)
    }

    @Test func testGoalsStillSpreadWhenAdvanceSaturated() async throws {
        var income = Income()
        income.salary = Salary(monthlyAmount: 100_000, advanceDate: 10, salaryDate: 25, advancePercentage: 40, salaryPercentage: 60)
        
        let targetDate = Date().addingTimeInterval(30 * 24 * 60 * 60)
        let monthlyRequirement = PeriodHelpers.monthlyRequirement(target: 30_000, current: 0, targetDate: targetDate)
        let goal = Goal(name: "New Car", targetAmount: 30_000, currentAmount: 0, targetDate: targetDate)

        let advanceCalc = DistributionCalculator(
            income: income,
            expense: Expense(),
            credits: [],
            goals: [goal],
            emergencyFundEnabled: true,
            selectedPeriod: .advance
        )

        let salaryCalc = DistributionCalculator(
            income: income,
            expense: Expense(),
            credits: [],
            goals: [goal],
            emergencyFundEnabled: true,
            selectedPeriod: .salary
        )

        #expect(advanceCalc.totalGoals == 0)
        #expect(salaryCalc.totalGoals > 0)

        let desiredSalaryGoals = salaryCalc.periodIncomeShare * monthlyRequirement
        #expect(abs(salaryCalc.totalGoals - min(salaryCalc.capacity, desiredSalaryGoals)) < 0.01)
    }

    @Test func testCreditOnlyInPlannedSection() async throws {
        var income = Income()
        income.salary = Salary(monthlyAmount: 100_000, advanceDate: 10, salaryDate: 25, advancePercentage: 40, salaryPercentage: 60)

        let credit = Credit(name: "Loan", monthlyAmount: 7_000, day: 12)
        let calc = DistributionCalculator(
            income: income,
            expense: Expense(),
            credits: [credit],
            goals: [],
            emergencyFundEnabled: true,
            selectedPeriod: .advance
        )
        
        #expect(calc.totalPlanned == 7_000)
        #expect(calc.creditExpenses.count == 1)
        #expect(calc.totalRegular == 0)
        #expect(calc.walletTarget >= 0)
    }

    @Test func creditsCountedOnce_everywhere() async throws {
        var income = Income()
        income.salary = Salary(monthlyAmount: 120_000, advanceDate: 10, salaryDate: 25, advancePercentage: 50, salaryPercentage: 50)

        var expense = Expense()
        expense.rent = 20_000
        expense.rentDay = 5
        let credit = Credit(name: "Loan", monthlyAmount: 8_000, day: 15)

        let calc = DistributionCalculator(
            income: income,
            expense: expense,
            credits: [credit],
            goals: [],
            emergencyFundEnabled: true,
            selectedPeriod: .month
        )

        #expect(calc.totalPlanned - expense.rent == credit.monthlyAmount)
        #expect(calc.creditExpenses.count == 1)
        #expect(calc.totalRegular >= 0)
        #expect(calc.walletTarget >= 0)
    }
    
    @Test func walletNotRemainder() async throws {
        var income = Income()
        income.salary = Salary(monthlyAmount: 120_000, advanceDate: 10, salaryDate: 25, advancePercentage: 40, salaryPercentage: 60)
        var expense = Expense()
        expense.groceries = 30_000
        expense.communication = 10_000
        expense.groceriesDay = nil
        expense.communicationDay = nil
        
        let calc = DistributionCalculator(
            income: income,
            expense: expense,
            credits: [],
            goals: [],
            emergencyFundEnabled: true,
            selectedPeriod: .advance
        )
        
        let advanceInterval = PeriodHelpers.interval(for: .advance, salary: income.salary!)
        let daysInMonth = PeriodHelpers.daysInMonth()
        let expectedWallet = calc.monthlyWalletPlan / daysInMonth * PeriodHelpers.days(in: advanceInterval)
        #expect(abs(calc.walletTarget - expectedWallet) < 0.5)
        #expect(calc.walletTarget > 0)
    }
    
    @Test func walletSplitByDays() async throws {
        var income = Income()
        income.salary = Salary(monthlyAmount: 160_000, advanceDate: 5, salaryDate: 25, advancePercentage: 40, salaryPercentage: 60)
        var expense = Expense()
        expense.walletDaily = 60_000

        let advanceInterval = PeriodHelpers.interval(for: .advance, salary: income.salary!)
        let salaryInterval = PeriodHelpers.interval(for: .salary, salary: income.salary!)
        let monthDays = PeriodHelpers.days(in: advanceInterval) + PeriodHelpers.days(in: salaryInterval)

        let advanceCalc = DistributionCalculator(
            income: income,
            expense: expense,
            credits: [],
            goals: [],
            emergencyFundEnabled: true,
            selectedPeriod: .advance
        )
        let expectedAdvanceWallet = 60_000 * PeriodHelpers.days(in: advanceInterval) / monthDays
        #expect(abs(advanceCalc.walletTarget - expectedAdvanceWallet) < 1)

        let salaryCalc = DistributionCalculator(
            income: income,
            expense: expense,
            credits: [],
            goals: [],
            emergencyFundEnabled: true,
            selectedPeriod: .salary
        )
        let expectedSalaryWallet = 60_000 * PeriodHelpers.days(in: salaryInterval) / monthDays
        #expect(abs(salaryCalc.walletTarget - expectedSalaryWallet) < 1)
    }

    @Test func noNegativesInDistribution() async throws {
        var income = Income()
        income.salary = Salary(monthlyAmount: 120_000, advanceDate: 5, salaryDate: 25, advancePercentage: 35, salaryPercentage: 60)
        let calc = DistributionCalculator(
            income: income,
            expense: Expense(),
            credits: [],
            goals: [],
            emergencyFundEnabled: true,
            selectedPeriod: .advance
        )
        
        for value in [calc.totalPlanned, calc.totalRegular, calc.walletTarget, calc.emergencyAmount, calc.totalGoals, calc.unexpectedAmount] {
            #expect(value >= 0)
        }
    }

    @Test func sumMatchesIncome() async throws {
        var income = Income()
        income.salary = Salary(monthlyAmount: 130_000, advanceDate: 5, salaryDate: 28, advancePercentage: 40, salaryPercentage: 60)
        let calc = DistributionCalculator(
            income: income,
            expense: Expense(),
            credits: [],
            goals: [],
            emergencyFundEnabled: true,
            selectedPeriod: .advance
        )

        let total =
            calc.totalPlanned +
            calc.totalRegular +
            calc.walletTarget +
            calc.emergencyAmount +
            calc.totalGoals +
            calc.unexpectedAmount
        #expect(abs(calc.periodIncome - total) < 0.1)
    }

    @Test func walletDoesNotAffectRegular() async throws {
        var income = Income()
        income.salary = Salary(monthlyAmount: 100_000, advanceDate: 10, salaryDate: 25, advancePercentage: 40, salaryPercentage: 60)
        var expense = Expense()
        expense.rent = 20_000
        expense.walletDaily = 10_000

        let baseCalc = DistributionCalculator(
            income: income,
            expense: expense,
            credits: [],
            goals: [],
            emergencyFundEnabled: true,
            selectedPeriod: .advance
        )

        expense.walletDaily = 0
        let controlCalc = DistributionCalculator(
            income: income,
            expense: expense,
            credits: [],
            goals: [],
            emergencyFundEnabled: true,
            selectedPeriod: .advance
        )

        #expect(abs(baseCalc.totalRegular - controlCalc.totalRegular) < 0.1)
    }
    
    @Test func testEmergencyFundExcludedWhenDisabled() async throws {
        var income = Income()
        income.salary = Salary(monthlyAmount: 100_000, advanceDate: 10, salaryDate: 25, advancePercentage: 40, salaryPercentage: 60)
        
        let goal = Goal(name: "EF", targetAmount: 150_000, currentAmount: 0, targetDate: Date().addingTimeInterval(365 * 24 * 3600), type: .emergencyFund)
        
        let enabledCalc = DistributionCalculator(
            income: income,
            expense: Expense(),
            credits: [],
            goals: [goal],
            emergencyFundEnabled: true,
            selectedPeriod: .month
        )
        
        let disabledCalc = DistributionCalculator(
            income: income,
            expense: Expense(),
            credits: [],
            goals: [goal],
            emergencyFundEnabled: false,
            selectedPeriod: .month
        )
        
        #expect(enabledCalc.emergencyAmount > 0)
        #expect(disabledCalc.emergencyAmount == 0)
    }
}

private enum PeriodHelpers {
    static var calendar: Calendar { Calendar.current }

    static func daysInMonth() -> Double {
        let components = calendar.dateComponents([.year, .month], from: Date())
        guard let start = calendar.date(from: components),
              let next = calendar.date(byAdding: .month, value: 1, to: start) else {
            return 30
        }
        let diff = calendar.dateComponents([.day], from: start, to: next).day ?? 0
        return max(1, Double(diff))
    }

    static func dateFor(day: Int, monthOffset: Int = 0) -> Date? {
        let components = calendar.dateComponents([.year, .month], from: Date())
        guard var base = calendar.date(from: components),
              let shifted = calendar.date(byAdding: .month, value: monthOffset, to: base) else {
            return nil
        }
        base = shifted
        var pick = calendar.dateComponents([.year, .month], from: base)
        if let range = calendar.range(of: .day, in: .month, for: base) {
            pick.day = min(max(day, range.lowerBound), range.upperBound - 1)
        } else {
            pick.day = day
        }
        return calendar.date(from: pick)
    }

    static func interval(for period: DistributionPeriod, salary: Salary) -> DateInterval {
        switch period {
        case .month:
            let components = calendar.dateComponents([.year, .month], from: Date())
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return DateInterval(start: start, end: end)
        case .advance:
            guard let advance = dateFor(day: salary.advanceDate, monthOffset: 0),
                  let salaryCurrent = dateFor(day: salary.salaryDate, monthOffset: 0),
                  let salaryNext = dateFor(day: salary.salaryDate, monthOffset: 1) else {
                fatalError("Invalid dates")
            }
            let end = salaryCurrent > advance ? salaryCurrent : salaryNext
            return DateInterval(start: advance, end: end)
        case .salary:
            guard let salaryDate = dateFor(day: salary.salaryDate, monthOffset: 0),
                  let advanceCurrent = dateFor(day: salary.advanceDate, monthOffset: 0),
                  let advanceNext = dateFor(day: salary.advanceDate, monthOffset: 1) else {
                fatalError("Invalid dates")
            }
            let end = advanceCurrent > salaryDate ? advanceCurrent : advanceNext
            return DateInterval(start: salaryDate, end: end)
        }
    }

    static func days(in interval: DateInterval) -> Double {
        let diff = calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 0
        return max(1, Double(diff))
    }

    static func monthlyRequirement(target: Double, current: Double, targetDate: Date) -> Double {
        let remaining = max(0, target - current)
        let days = calendar.dateComponents([.day], from: Date(), to: targetDate).day ?? 30
        let months = max(1, Double(days) / 30.0)
        return remaining / months
    }
}