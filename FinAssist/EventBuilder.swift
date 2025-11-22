import Foundation

class EventBuilder {
    static func buildEvents(
        incomes: [Income],
        bonuses: [Bonus],
        expenses: [Expense],
        credits: [Credit],
        from startDate: Date,
        to endDate: Date
    ) -> [Date: [Event]] {
        var events: [Date: [Event]] = [:]
        let calendar = Calendar.current
        var date = startDate

        while date <= endDate {
            var dayEvents: [Event] = []

            // Доходы
            for income in incomes {
                for payout in income.payouts {
                    let payoutDay = min(payout.day, lastDay(of: date))
                    if calendar.component(.day, from: date) == payoutDay {
                        // Используем salary.monthlyAmount * payout.share
                        let amount = (income.salary?.monthlyAmount ?? 0) * payout.share
                        dayEvents.append(Event(date: date, type: .income, amount: amount, sourceId: income.id, description: income.name))
                    }
                }
            }

            // Премии
            for bonus in bonuses {
                switch bonus.type {
                case .oneTime:
                    if let bonusDate = bonus.date, calendar.isDate(bonusDate, inSameDayAs: date) {
                        dayEvents.append(Event(date: date, type: .bonus, amount: bonus.amount, sourceId: bonus.id, description: bonus.name))
                    }
                case .recurring:
                    if let period = bonus.period, let start = bonus.start, let end = bonus.end, date >= start, date <= end {
                        if isBonusDay(date: date, period: period, start: start) {
                            dayEvents.append(Event(date: date, type: .bonus, amount: bonus.amount, sourceId: bonus.id, description: bonus.name))
                        }
                    }
                }
            }

            // Расходы
            for expense in expenses {
                // Используем totalMonthlyExpense для учета всех категорий расходов
                let totalExpense = expense.totalMonthlyExpense
                if totalExpense > 0 {
                    // Если day не установлен, используем 1 число месяца (дефолтная дата списания)
                    let expenseDay = min(expense.day ?? 1, lastDay(of: date))
                    if calendar.component(.day, from: date) == expenseDay {
                        let category = expense.category ?? "Расход"
                        dayEvents.append(Event(date: date, type: .expense, amount: totalExpense, sourceId: expense.id, description: category))
                    }
                }
            }

            // Кредиты
            for credit in credits {
                // Если endDate не задана, кредит бессрочный
                // Если задана, проверяем что текущая дата до окончания
                let shouldInclude = credit.endDate == nil || date <= credit.endDate!
                
                if shouldInclude {
                    let creditDay = min(credit.day, lastDay(of: date))
                    if calendar.component(.day, from: date) == creditDay {
                        dayEvents.append(Event(date: date, type: .credit, amount: credit.monthlyAmount, sourceId: credit.id, description: credit.name))
                    }
                }
            }

            if !dayEvents.isEmpty {
                events[date] = dayEvents
            }
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return events
    }

    private static func lastDay(of date: Date) -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.upperBound - 1
    }

    private static func isBonusDay(date: Date, period: BonusPeriod, start: Date) -> Bool {
        let calendar = Calendar.current
        switch period {
        case .month:
            return calendar.component(.day, from: date) == calendar.component(.day, from: start)
        case .quarter:
            let months = [0, 3, 6, 9]
            let startMonth = calendar.component(.month, from: start)
            let currentMonth = calendar.component(.month, from: date)
            return months.contains((currentMonth - startMonth) % 12) && calendar.component(.day, from: date) == calendar.component(.day, from: start)
        case .year:
            return calendar.component(.month, from: date) == calendar.component(.month, from: start) &&
                   calendar.component(.day, from: date) == calendar.component(.day, from: start)
        }
    }
}
