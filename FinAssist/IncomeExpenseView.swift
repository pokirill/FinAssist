import SwiftUI


struct IncomeExpenseView: View {
    @State private var income: Income = Income()
    @State private var expense: Expense = Expense()
    @State private var showingIncomeModal = false
    @State private var showingExpenseModal = false
    @State private var showingAnalytics = false
    @State private var manualSavingAmount: Double = 0
    @State private var hasCalculatedThroughApp = false
    
    @AppStorage("monthlySaving") private var monthlySaving: Double = 0
    @AppStorage("savingDay") private var savingDay: Int = 10
    
    private let incomeKey = "user_income"
    private let expenseKey = "user_expense"
    
    var availableForGoals: Double {
        let totalIncome = income.totalMonthlyIncome
        let totalExpense = expense.totalMonthlyExpense
        let available = totalIncome - totalExpense
        
        print("Расчет: доходы \(totalIncome) - расходы \(totalExpense) = доступно \(available)")
        
        return available
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    Text("Ежемесячно")
                        .font(.largeTitle).bold()
                        .foregroundColor(AppColors.textPrimary)
                        .padding([.top, .horizontal])
                        .padding(.bottom, 4)
                    
                    if !hasCalculatedThroughApp && monthlySaving == 0 {
                        // Первый вход - выбор способа
                        firstTimeView
                    } else if hasCalculatedThroughApp {
                        // Показываем аналитику
                        analyticsView
                    } else {
                        // Ручной ввод - показываем сумму + предложение
                        manualInputView
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingIncomeModal = true
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }
                .sheet(isPresented: $showingIncomeModal) {
                    IncomeModalView(income: $income, onSave: saveData)
                }
                .sheet(isPresented: $showingExpenseModal) {
                    ExpenseModalView(expense: $expense, onSave: saveData)
                }
            }
        }
        .onAppear {
            loadData()
        }
    }
    
    // Первый вход
    private var firstTimeView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Как вы хотите указать сумму накоплений?")
                    .font(.title2)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    manualSavingAmount = 0
                    monthlySaving = 0
                    hasCalculatedThroughApp = false
                }) {
                    HStack {
                        Image(systemName: "hand.point.up")
                            .foregroundColor(AppColors.primary)
                        Text("Указать сумму накоплений самостоятельно")
                            .foregroundColor(AppColors.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.surface)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    showingIncomeModal = true
                }) {
                    HStack {
                        Image(systemName: "calculator")
                            .foregroundColor(AppColors.accent)
                        Text("Рассчитать сумму через приложение")
                            .foregroundColor(AppColors.accent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.surface)
                    .cornerRadius(12)
                }
            }
            .padding()
            
            Spacer()
        }
    }
    
    // Ручной ввод
    private var manualInputView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Text("Ваша сумма накоплений")
                    .font(.title2)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack {
                    Text("\(numberFormatter.string(from: NSNumber(value: monthlySaving)) ?? "0") ₽")
                        .font(.largeTitle).bold()
                        .foregroundColor(AppColors.primary)
                    
                    Button(action: {
                        // Показать модалку для редактирования
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(AppColors.accent)
                    }
                }
                
                Button(action: {
                    showingIncomeModal = true
                }) {
                    HStack {
                        Image(systemName: "calculator")
                        Text("Рассчитать через приложение")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding()
            
            Spacer()
        }
    }
    
    // Аналитика
    private var analyticsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Сводка
                VStack(spacing: 12) {
                    HStack {
                        Text("Доходы")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("\(numberFormatter.string(from: NSNumber(value: income.totalMonthlyIncome)) ?? "0") ₽")
                            .font(.headline)
                            .foregroundColor(AppColors.success)
                    }
                    
                    HStack {
                        Text("Расходы")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("\(numberFormatter.string(from: NSNumber(value: expense.totalMonthlyExpense)) ?? "0") ₽")
                            .font(.headline)
                            .foregroundColor(AppColors.danger)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Доступно для целей")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("\(numberFormatter.string(from: NSNumber(value: availableForGoals)) ?? "0") ₽")
                            .font(.headline)
                            .foregroundColor(AppColors.primary)
                    }
                }
                .padding()
                .background(AppColors.surface)
                .cornerRadius(12)
                
                // Кнопки редактирования
                HStack(spacing: 12) {
                    Button(action: {
                        showingIncomeModal = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Доходы")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.success)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingExpenseModal = true
                    }) {
                        HStack {
                            Image(systemName: "minus.circle")
                            Text("Расходы")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.danger)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                // Круговая диаграмма расходов
                ExpenseAnalyticsView(expense: expense)
                    .frame(height: 200)
                    .padding()
                    .background(AppColors.surface)
                    .cornerRadius(12)
            }
            .padding()
        }
    }
    
    func saveData() {
        if let incomeData = try? JSONEncoder().encode(income) {
            UserDefaults.standard.set(incomeData, forKey: incomeKey)
        }
        if let expenseData = try? JSONEncoder().encode(expense) {
            UserDefaults.standard.set(expenseData, forKey: expenseKey)
        }
        
        monthlySaving = availableForGoals
        hasCalculatedThroughApp = true
    }
    
    func loadData() {
        if let incomeData = UserDefaults.standard.data(forKey: incomeKey),
           let decodedIncome = try? JSONDecoder().decode(Income.self, from: incomeData) {
            income = decodedIncome
        }
        
        if let expenseData = UserDefaults.standard.data(forKey: expenseKey),
           let decodedExpense = try? JSONDecoder().decode(Expense.self, from: expenseData) {
            expense = decodedExpense
        }
    }
}

// Круговая диаграмма расходов
struct ExpenseAnalyticsView: View {
    let expense: Expense
    @State private var showingDetails = false
    
    var expenseCategories: [(String, Double, Color)] {
        let categories = [
            ("Аренда", expense.rent, Color.red),
            ("Кредиты", expense.loans, Color.orange),
            ("Коммуналка", expense.utilities, Color.yellow),
            ("Продукты", expense.groceries, Color.green),
            ("Связь", expense.communication, Color.blue),
            ("Подписки", expense.subscriptions, Color.indigo),
            ("Транспорт", expense.transport, Color.purple),
            ("Хобби", expense.hobbies, Color.pink),
            ("Развлечения", expense.entertainment, Color.cyan),
            ("Красота", expense.beauty, Color.mint),
            ("Дополнительно", expense.additional.reduce(0) { $0 + $1.amount }, Color.brown)
        ]
        return categories.filter { $0.1 > 0 }
    }
    
    var dailyExpenses: [(String, Double)] {
        // Категории без фиксированной даты платежа
        let daily = [
            ("Продукты", expense.groceries),
            ("Транспорт", expense.transport),
            ("Развлечения", expense.entertainment),
            ("Красота", expense.beauty),
            ("Дополнительно", expense.additional.reduce(0) { $0 + $1.amount })
        ]
        return daily.filter { $0.1 > 0 }
    }
    
    var dailyTotal: Double {
        return dailyExpenses.reduce(0) { $0 + $1.1 } / 30 // Примерно в день
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                withAnimation {
                    showingDetails.toggle()
                }
            }) {
                HStack {
                    Text("Аналитика расходов")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(AppColors.primary)
                }
                .padding()
                .background(AppColors.surface)
                .cornerRadius(12)
            }
            
            if showingDetails {
                VStack(spacing: 20) {
                    // Круговая диаграмма и список категорий
                    HStack(spacing: 20) {
                        // Круговая диаграмма
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                                .frame(width: 120, height: 120)
                            
                            ForEach(0..<expenseCategories.count, id: \.self) { index in
                                Circle()
                                    .trim(from: startFraction(for: index), to: endFraction(for: index))
                                    .stroke(expenseCategories[index].2, lineWidth: 20)
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(-90))
                            }
                            
                            VStack {
                                Text("Всего")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Text("\(numberFormatter.string(from: NSNumber(value: expense.totalMonthlyExpense)) ?? "0") ₽")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }
                        
                        // Список категорий
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(0..<expenseCategories.count, id: \.self) { index in
                                let category = expenseCategories[index]
                                HStack {
                                    Circle()
                                        .fill(category.2)
                                        .frame(width: 8, height: 8)
                                    Text(category.0)
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                    Spacer()
                                    Text("\(numberFormatter.string(from: NSNumber(value: category.1)) ?? "0") ₽")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                            }
                        }
                    }
                    
                    // Ежедневные траты
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ежедневные траты")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Примерно в день: \(numberFormatter.string(from: NSNumber(value: dailyTotal)) ?? "0") ₽")
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                        
                        ForEach(0..<dailyExpenses.count, id: \.self) { index in
                            let daily = dailyExpenses[index]
                            HStack {
                                Text(daily.0)
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Spacer()
                                Text("\(numberFormatter.string(from: NSNumber(value: daily.1 / 30)) ?? "0") ₽/день")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(8)
                }
                .padding()
                .background(AppColors.surface)
                .cornerRadius(12)
            }
        }
    }
    
    private func startFraction(for index: Int) -> CGFloat {
        let total = expense.totalMonthlyExpense
        guard total > 0 else { return 0 }
        
        var sum: Double = 0
        for i in 0..<index {
            sum += expenseCategories[i].1
        }
        return CGFloat(sum / total)
    }
    
    private func endFraction(for index: Int) -> CGFloat {
        let total = expense.totalMonthlyExpense
        guard total > 0 else { return 0 }
        
        var sum: Double = 0
        for i in 0...index {
            sum += expenseCategories[i].1
        }
        return CGFloat(sum / total)
    }
}
