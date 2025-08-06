import SwiftUI


struct ExpenseModalView: View {
    @Binding var expense: Expense
    var onSave: (() -> Void)?
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 0
    @State private var additionalExpenses: [AdditionalExpense] = []
    
    private let categories = ExpenseCategory.allCases
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Прогресс бар
                    HStack {
                        ForEach(0..<categories.count, id: \.self) { index in
                            Rectangle()
                                .fill(index <= currentStep ? AppColors.primary : AppColors.primary.opacity(0.3))
                                .frame(height: 4)
                                .animation(.easeInOut, value: currentStep)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Контент
                    TabView(selection: $currentStep) {
                        ForEach(0..<categories.count, id: \.self) { index in
                            expenseStep(for: categories[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    
                    // Навигация
                    HStack {
                        if currentStep > 0 {
                            Button("Назад") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .foregroundColor(AppColors.primary)
                        }
                        
                        Spacer()
                        
                        Button(currentStep == categories.count - 1 ? "Завершить" : "Далее") {
                            if currentStep == categories.count - 1 {
                                saveExpenses()
                                dismiss()
                            } else {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        }
                        .foregroundColor(AppColors.primary)
                        .disabled(!canProceed)
                    }
                    .padding()
                }
            }
            .navigationTitle("Расходы")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Шаг для каждой категории расходов
    private func expenseStep(for category: ExpenseCategory) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(category.rawValue)
                        .font(.title2).bold()
                        .foregroundColor(AppColors.textPrimary)
                    
                    if category == .additional {
                        Text("Здесь указываются регулярные траты, не вошедшие в категории выше")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("Например: ветеринарные услуги, подарки, траты на образование, поездки, авто, ремонт и пр.")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.top, 4)
                    } else {
                        Text("Укажите приблизительно, кратно тысяче")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                if category == .additional {
                    additionalExpensesView
                } else {
                    regularExpenseView(for: category)
                }
            }
            .padding()
        }
    }
    
    // Обычная категория расходов
    private func regularExpenseView(for category: ExpenseCategory) -> some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Сумма")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                TextField("0", text: Binding(
                    get: { getExpenseAmountString(for: category) },
                    set: { newValue in
                        let formatted = formatInput(newValue)
                        updateExpense(for: category, amount: Double(formatted.replacingOccurrences(of: " ", with: "")) ?? 0)
                    }
                ))
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            if category == .rent || category == .loans {
                VStack(alignment: .leading, spacing: 8) {
                    Text("День месяца")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Picker("День месяца", selection: .constant(15)) {
                        ForEach(1...28, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120)
                }
            }
        }
    }
    
    // Дополнительные расходы
    private var additionalExpensesView: some View {
        VStack(spacing: 16) {
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
    }
    
    // Шаг завершения
    private var completionStep: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.success)
                
                Text("Данные о расходах заполнены!")
                    .font(.title2)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Теперь вы можете получить точную аналитику ваших финансов")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var canProceed: Bool {
        let currentCategory = categories[currentStep]
        
        if currentCategory == .additional {
            return true // Разрешаем переход даже без данных
        } else {
            let amount = getExpenseAmount(for: currentCategory)
            return true // Разрешаем переход даже без данных
        }
    }
    
    private func updateExpense(for category: ExpenseCategory, amount: Double) {
        switch category {
        case .rent:
            expense.rent = amount
        case .loans:
            expense.loans = amount
        case .utilities:
            expense.utilities = amount
        case .groceries:
            expense.groceries = amount
        case .communication:
            expense.communication = amount
        case .subscriptions:
            expense.subscriptions = amount
        case .transport:
            expense.transport = amount
        case .hobbies:
            expense.hobbies = amount
        case .entertainment:
            expense.entertainment = amount
        case .beauty:
            expense.beauty = amount
        case .additional:
            break // Обрабатывается отдельно
        }
    }
    
    private func getExpenseAmount(for category: ExpenseCategory) -> Double {
        switch category {
        case .rent:
            return expense.rent
        case .loans:
            return expense.loans
        case .utilities:
            return expense.utilities
        case .groceries:
            return expense.groceries
        case .communication:
            return expense.communication
        case .subscriptions:
            return expense.subscriptions
        case .transport:
            return expense.transport
        case .hobbies:
            return expense.hobbies
        case .entertainment:
            return expense.entertainment
        case .beauty:
            return expense.beauty
        case .additional:
            return additionalExpenses.reduce(0) { $0 + $1.amount }
        }
    }
    
    private func getExpenseAmountString(for category: ExpenseCategory) -> String {
        let amount = getExpenseAmount(for: category)
        return numberFormatter.string(from: NSNumber(value: amount)) ?? ""
    }
    
    private func saveExpenses() {
        expense.additional = additionalExpenses
        onSave?()
    }
}

// Карточка дополнительного расхода
struct AdditionalExpenseCard: View {
    @Binding var expense: AdditionalExpense
    var onDelete: () -> Void
    @State private var name = ""
    @State private var amount = ""
    @State private var comment = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Дополнительный расход")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(AppColors.danger)
                }
            }
            
            VStack(spacing: 8) {
                TextField("Название", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: name) { expense.name = $0 }
                
                TextField("Сумма", text: $amount)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: amount) {
                        amount = formatInput($0)
                        expense.amount = Double(amount.replacingOccurrences(of: " ", with: "")) ?? 0
                    }
                
                TextField("Комментарий (необязательно)", text: $comment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: comment) { expense.comment = $0 }
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(12)
    }
} 
