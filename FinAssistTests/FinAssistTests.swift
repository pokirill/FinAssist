//
//  FinAssistTests.swift
//  FinAssistTests
//
//  Created by Кирилл Попов on 02/07/2025.
//

import Testing

struct FinAssistTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func totalExpensesIncludesCreditsOnce() async throws {
        var expense = Expense()
        expense.rent = 20_000
        let credit = Credit(name: "Loan", monthlyAmount: 5_000, day: 12)
        #expect(IncomeExpenseView.sumActiveCreditPayments(from: [credit]) == 5_000)
        #expect(IncomeExpenseView.sumActiveCreditPayments(from: [credit, credit]) == 10_000)
        let combined = expense.totalMonthlyExpense + IncomeExpenseView.sumActiveCreditPayments(from: [credit])
        #expect(combined == 25_000)
    }
}
