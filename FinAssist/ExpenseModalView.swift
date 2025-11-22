import SwiftUI

struct ExpenseModalView: View {
    @Binding var expense: Expense
    @Binding var credits: [Credit]
    var onSave: (() -> Void)?
    @Environment(\.dismiss) var dismiss
    
    @State private var additionalExpenses: [AdditionalExpense] = []
    @State private var expenseAmounts: [ExpenseCategory: String] = [:]
    @State private var expenseDays: [ExpenseCategory: Int?] = [:]
    @State private var showingCreditManagement = false
    
    // Исключаем кредиты из списка категорий, так как они управляются отдельно
    private let categories: [ExpenseCategory] = [
        .rent,
        .utilities,
        .groceries,
        .communication,
        .subscriptions,
        .transport,
        .hobbies,
        .entertainment,
        .beauty,
        .marketplaces
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Уточните примерные траты по категориям")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Text("Укажите ежемесячные суммы в рублях")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        ForEach(categories, id: \.self) { category in
                            ExpenseCategoryCard(
                                category: category,
                                amount: Binding(
                                    get: {
                                        if let value = expenseAmounts[category] {
                                            return value
                                        }
                                        let fallback = getExpenseAmountString(for: category)
                                        expenseAmounts[category] = fallback
                                        return fallback
                                    },
                                    set: { newValue in
                                        let formatted = AppUtils.formatInput(newValue)
                                        expenseAmounts[category] = formatted
                                        updateExpense(
                                            for: category,
                                            amount: Double(
                                                formatted.replacingOccurrences(of: " ", with: "")
                                            ) ?? 0
                                        )
                                    }
                                ),
                                day: Binding(
                                    get: { expenseDays[category] ?? nil },
                                    set: { newValue in
                                        // Если выбрано "—" (nil), удаляем из словаря
                                        if let value = newValue {
                                            expenseDays[category] = value
                                        } else {
                                            expenseDays.removeValue(forKey: category)
                                        }
                                        updateExpenseDay(for: category, day: newValue)
                                    }
                                )
                            )
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Кошелёк (повседневные траты)")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            TextField("Сумма", text: Binding(
                                get: { AppUtils.numberFormatter.string(from: NSNumber(value: expense.walletDaily)) ?? "" },
                                set: { newValue in
                                    let formatted = AppUtils.formatInput(newValue)
                                    expense.walletDaily = Double(formatted.replacingOccurrences(of: " ", with: "")) ?? 0
                                }
                            ))
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding()
                        .background(AppColors.surface)
                        .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Дополнительные расходы")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Text("Добавьте расходы, которые не подходят под основные категории")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            ForEach(additionalExpenses.indices, id: \.self) { index in
                                AdditionalExpenseCard(expense: $additionalExpenses[index], onDelete: {
                                    additionalExpenses.remove(at: index)
                                })
                            }
                            Button(action: {
                                additionalExpenses.append(AdditionalExpense(name: "", amount: 0, comment: ""))
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Добавить расход")
                                }
                                .foregroundColor(AppColors.primary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(AppColors.surface)
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(AppColors.surface)
                        .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Кредиты и займы")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        if credits.isEmpty {
                            Text("Добавьте кредиты, чтобы они учитывались в общей картине расходов.")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        } else {
                            ForEach(credits) { credit in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(credit.name)
                                            .font(.subheadline)
                                            .foregroundColor(AppColors.textPrimary)
                                        Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: credit.monthlyAmount)) ?? "0") ₽")
                                            .font(.caption)
                                            .foregroundColor(AppColors.danger)
                                    }
                                    Spacer()
                                    Text("\(credit.day) число")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                .padding()
                                .background(AppColors.surface.opacity(0.4))
                                .cornerRadius(10)
                            }
                        }
                        Button(action: {
                            showingCreditManagement = true
                        }) {
                            HStack {
                                Image(systemName: "creditcard")
                                Text(credits.isEmpty ? "Добавить кредит" : "Управлять кредитами")
                            }
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppColors.background)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.primary.opacity(0.4), lineWidth: 1)
                            )
                        }
                    }
                    .padding()
                    .background(AppColors.surface)
                    .cornerRadius(12)
                    .padding()
                }
            }
            .navigationTitle("Расходы")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveExpenses()
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
        .sheet(isPresented: $showingCreditManagement) {
            CreditManagementView(credits: $credits)
                .onDisappear {
                    onSave?()
            }
        }
        .onAppear {
            loadExistingData()
        }
    }

    private func loadExistingData() {
        additionalExpenses = expense.additional
        expenseAmounts.removeAll()
        expenseDays.removeAll()

        categories.forEach { category in
            let amount = getExpenseAmount(for: category)
            if amount > 0 {
                expenseAmounts[category] = AppUtils.numberFormatter.string(from: NSNumber(value: amount)) ?? ""
            }
            if let day = getExpenseDay(for: category) {
                expenseDays[category] = day
            }
        }
        // wallet
        expenseAmounts[.additional] = "" // ensure placeholder unaffected
    }

    private func updateExpense(for category: ExpenseCategory, amount: Double) {
        switch category {
        case .rent: expense.rent = amount
        case .loans: expense.loans = amount
        case .utilities: expense.utilities = amount
        case .groceries: expense.groceries = amount
        case .communication: expense.communication = amount
        case .subscriptions: expense.subscriptions = amount
        case .transport: expense.transport = amount
        case .hobbies: expense.hobbies = amount
        case .entertainment: expense.entertainment = amount
        case .beauty: expense.beauty = amount
        case .marketplaces: expense.marketplaces = amount
        case .additional: break
        }
    }

    private func updateExpenseDay(for category: ExpenseCategory, day: Int?) {
        switch category {
        case .rent: expense.rentDay = day
        case .loans: expense.loansDay = day
        case .utilities: expense.utilitiesDay = day
        case .groceries: expense.groceriesDay = day
        case .communication: expense.communicationDay = day
        case .subscriptions: expense.subscriptionsDay = day
        case .transport: expense.transportDay = day
        case .hobbies: expense.hobbiesDay = day
        case .entertainment: expense.entertainmentDay = day
        case .beauty: expense.beautyDay = day
        case .marketplaces: expense.marketplacesDay = day
        case .additional: break
        }
    }

    private func getExpenseAmount(for category: ExpenseCategory) -> Double {
        switch category {
        case .rent: return expense.rent
        case .loans: return expense.loans
        case .utilities: return expense.utilities
        case .groceries: return expense.groceries
        case .communication: return expense.communication
        case .subscriptions: return expense.subscriptions
        case .transport: return expense.transport
        case .hobbies: return expense.hobbies
        case .entertainment: return expense.entertainment
        case .beauty: return expense.beauty
        case .marketplaces: return expense.marketplaces
        case .additional: return 0
        }
    }

    private func getExpenseDay(for category: ExpenseCategory) -> Int? {
        switch category {
        case .rent: return expense.rentDay
        case .loans: return expense.loansDay
        case .utilities: return expense.utilitiesDay
        case .groceries: return expense.groceriesDay
        case .communication: return expense.communicationDay
        case .subscriptions: return expense.subscriptionsDay
        case .transport: return expense.transportDay
        case .hobbies: return expense.hobbiesDay
        case .entertainment: return expense.entertainmentDay
        case .beauty: return expense.beautyDay
        case .marketplaces: return expense.marketplacesDay
        case .additional: return nil
        }
    }

    private func getExpenseAmountString(for category: ExpenseCategory) -> String {
        let amount = getExpenseAmount(for: category)
        return AppUtils.numberFormatter.string(from: NSNumber(value: amount)) ?? ""
    }

    private func saveExpenses() {
        expense.additional = additionalExpenses
        onSave?()
    }
}

struct ExpenseCategoryCard: View {
    let category: ExpenseCategory
    @Binding var amount: String
    @Binding var day: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.rawValue)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            HStack(spacing: 12) {
                TextField("0", text: $amount)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: amount) { newValue in
                        amount = AppUtils.formatInput(newValue)
                    }
                DaySelector(day: $day)
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(12)
    }
}

struct DaySelector: View {
    @Binding var day: Int?
    
    var body: some View {
        // Используем Menu для компактности, визуально похож на кнопку/пикер
        Menu {
            Button("—") { day = nil }
            ForEach(1...28, id: \.self) { value in
                Button("\(value)") { day = value }
            }
        } label: {
            HStack(spacing: 4) {
                Text(day.map { "\($0)" } ?? "—")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(minWidth: 24) // Фиксированная ширина для цифр
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppColors.background)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.textSecondary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct AdditionalExpenseCard: View {
    @Binding var expense: AdditionalExpense
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Название", text: $expense.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            TextField("Сумма", value: $expense.amount, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(12)
    }
}
