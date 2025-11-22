import SwiftUI

struct IncomeExpenseView: View {
    @State private var income: Income = Income()
    @State private var expense: Expense = Expense()
    @State private var credits: [Credit] = []
    @State private var goals: [Goal] = []
    @State private var showingIncomeModal = false
    @State private var showingExpenseModal = false
    @State private var showingAnalytics = false
    @State private var showingPeriodDistribution = false
    @State private var manualSavingAmount: Double = 0
    @State private var hasCalculatedThroughApp = false
    
    @AppStorage("monthlySaving") private var monthlySaving: Double = 0
    @AppStorage("savingDay") private var savingDay: Int = 10
    @AppStorage("emergencyFundEnabled") private var emergencyFundEnabled: Bool = true
    
    private let incomeKey = "user_income"
    private let expenseKey = "user_expense"
    private let creditsKey = "user_credits"
    
    // Доступно для целей и жизни (Net Income)
    static func sumActiveCreditPayments(from credits: [Credit]) -> Double {
        credits.reduce(0.0) { sum, credit in
            guard credit.endDate == nil || credit.endDate! > Date() else { return sum }
            return sum + credit.monthlyAmount
        }
    }

    private var totalCreditPayments: Double {
        Self.sumActiveCreditPayments(from: credits)
    }

    private var totalExpensesWithCredits: Double {
        expense.totalMonthlyExpense + totalCreditPayments
    }

    var availableForGoals: Double {
        income.totalMonthlyIncome - totalExpensesWithCredits
    }
    
    // Потребность целей в месяц
    var goalsRequirement: Double {
        var req: Double = 0
        
        // Подушка
        if emergencyFundEnabled, let ef = goals.first(where: { $0.type == .emergencyFund }), !ef.isAchieved {
            req += calculateMonthlyReq(for: ef)
        }
        
        // Остальные активные цели
        let activeGoals = goals.filter { $0.type != .emergencyFund && !$0.isAchieved }
        for goal in activeGoals {
            req += calculateMonthlyReq(for: goal)
        }
        return req
    }
    
    // Кошелек (остаток после целей)
    var walletAmount: Double {
        availableForGoals - goalsRequirement
    }
    
    private func calculateMonthlyReq(for goal: Goal) -> Double {
        let remaining = max(0, goal.targetAmount - goal.currentAmount)
        let days = Calendar.current.dateComponents([.day], from: Date(), to: goal.targetDate).day ?? 30
        let months = max(1, Double(days) / 30.0)
        return remaining / months
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    Text("Доходы и расходы")
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
                    ExpenseModalView(expense: $expense, credits: $credits, onSave: {
                        saveData()
                        loadData()
                    })
                }
                .sheet(isPresented: $showingPeriodDistribution) {
                    PeriodDistributionView(
                        income: income,
                        expense: $expense,
                        credits: $credits,
                        goals: goals
                    )
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
                    hasCalculatedThroughApp = true
                }) {
                    HStack {
                        Image(systemName: "chart.bar")
                        .foregroundColor(AppColors.primary)
                        Text("Рассчитать через доходы и расходы")
                            .foregroundColor(AppColors.primary)
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
            Spacer()
            
            VStack(spacing: 16) {
                Text("Укажите ежемесячную сумму накоплений")
                    .font(.title2)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                TextField("Сумма", value: $manualSavingAmount, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    monthlySaving = manualSavingAmount
                }) {
                    Text("Сохранить")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.primary)
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
                        Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: income.totalMonthlyIncome)) ?? "0") ₽")
                            .font(.headline)
                            .foregroundColor(AppColors.success)
                    }
                    
                    HStack {
                        Text("Расходы")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: totalExpensesWithCredits)) ?? "0") ₽")
                            .font(.headline)
                            .foregroundColor(AppColors.danger)
                    }
                    
                    if !credits.isEmpty {
                        let totalCreditPayments = credits.reduce(0.0) { sum, credit in
                            if credit.endDate == nil || credit.endDate! > Date() {
                                return sum + credit.monthlyAmount
                            }
                            return sum
                        }
                        
                        HStack {
                            Text("Кредиты")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: totalCreditPayments)) ?? "0") ₽")
                                .font(.headline)
                                .foregroundColor(AppColors.warning)
                        }
                    }
                    
                    Divider()
                    
                    // Net Income
                    HStack {
                        Text("Доступно для целей")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: availableForGoals)) ?? "0") ₽")
                            .font(.headline)
                            .foregroundColor(AppColors.primary)
                    }
                    
                    // Wallet (Residual)
                    HStack {
                        Text("Кошелёк (остаток)")
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: walletAmount)) ?? "0") ₽")
                            .font(.headline)
                            .foregroundColor(AppColors.success)
                    }
                }
                .padding()
                .background(AppColors.surface)
                .cornerRadius(12)
                
                // Круговая диаграмма расходов
                ExpensePieChart(expense: expense)
                    .padding()
                    .background(AppColors.surface)
                    .cornerRadius(12)
                
                // Кнопки редактирования
                VStack(spacing: 12) {
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
                    
                    Button(action: {
                        // Загружаем актуальные цели перед открытием
                        if let goalsData = UserDefaults.standard.data(forKey: "user_goals"),
                           let decodedGoals = try? JSONDecoder().decode([Goal].self, from: goalsData) {
                            goals = decodedGoals
                        }
                        showingPeriodDistribution = true
                    }) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text("Распределение по периодам")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
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
        if let creditsData = try? JSONEncoder().encode(credits) {
            UserDefaults.standard.set(creditsData, forKey: creditsKey)
        }
        
        // Сохраняем totalMonthlyIncome и totalMonthlyExpense (с учетом кредитов)
        UserDefaults.standard.set(income.totalMonthlyIncome, forKey: "totalMonthlyIncome")
        
        let totalExpenseWithCredits = totalExpensesWithCredits
        UserDefaults.standard.set(totalExpenseWithCredits, forKey: "totalMonthlyExpense")
        
        monthlySaving = availableForGoals
        hasCalculatedThroughApp = true
        
        UserDefaults.standard.set(true, forKey: "hasCalculatedThroughApp")
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
        
        if let creditsData = UserDefaults.standard.data(forKey: creditsKey),
           let decodedCredits = try? JSONDecoder().decode([Credit].self, from: creditsData) {
            credits = decodedCredits
        }
        
        if let goalsData = UserDefaults.standard.data(forKey: "user_goals"),
           let decodedGoals = try? JSONDecoder().decode([Goal].self, from: goalsData) {
            goals = decodedGoals
        }
        
        hasCalculatedThroughApp = UserDefaults.standard.bool(forKey: "hasCalculatedThroughApp")
        
        if hasCalculatedThroughApp {
            monthlySaving = availableForGoals
        }
    }
}

// Круговая диаграмма расходов (оставляем без изменений, но нужна для компиляции)
struct ExpensePieChart: View {
    let expense: Expense
    @State private var isExpanded = false
    
    private var sortedCategories: [(ExpenseCategory, Double)] {
        let categories: [(ExpenseCategory, Double)] = [
            (.rent, expense.rent),
            (.loans, expense.loans),
            (.utilities, expense.utilities),
            (.groceries, expense.groceries),
            (.communication, expense.communication),
            (.subscriptions, expense.subscriptions),
            (.transport, expense.transport),
            (.hobbies, expense.hobbies),
            (.entertainment, expense.entertainment),
            (.beauty, expense.beauty),
            (.marketplaces, expense.marketplaces)
        ]
        
        return categories
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
    }
    
    private var additionalExpensesTotal: Double {
        expense.additional.reduce(0) { sum, expense in
            sum + expense.amount
        }
    }
    
    private var totalExpenses: Double {
        expense.totalMonthlyExpense
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Аналитика по расходам")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AppColors.primary)
                        .font(.subheadline)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if totalExpenses > 0 {
                if isExpanded {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                                .frame(width: 180, height: 180)
                            
                            ForEach(Array(sortedCategories.enumerated()), id: \.offset) { index, item in
                                let (category, amount) = item
                                let percentage = amount / totalExpenses
                                let startAngle = calculateStartAngle(for: index)
                                let endAngle = startAngle + Angle(degrees: 360 * percentage)
                                
                                PieSlice(startAngle: startAngle, endAngle: endAngle, color: getColorForCategory(category))
                                    .frame(width: 180, height: 180)
                            }
                            
                            if additionalExpensesTotal > 0 {
                                let additionalPercentage = additionalExpensesTotal / totalExpenses
                                let startAngle = calculateStartAngle(for: sortedCategories.count)
                                let endAngle = startAngle + Angle(degrees: 360 * additionalPercentage)
                                
                                PieSlice(startAngle: startAngle, endAngle: endAngle, color: getColorForCategory(.additional))
                                    .frame(width: 180, height: 180)
                            }
                            
                            VStack {
                                Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: totalExpenses)) ?? "0")")
                                    .font(.title2).bold()
                                    .foregroundColor(AppColors.textPrimary)
                                Text("₽")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .frame(width: 180, height: 180)
                        
                        VStack(spacing: 8) {
                            ForEach(Array(sortedCategories.enumerated()), id: \.offset) { index, item in
                                let (category, amount) = item
                                ExpenseCategoryRow(
                                    category: category,
                                    amount: amount,
                                    total: totalExpenses,
                                    color: getColorForCategory(category)
                                )
                            }
                            
                            if additionalExpensesTotal > 0 {
                                ExpenseCategoryRow(
                                    category: .additional,
                                    amount: additionalExpensesTotal,
                                    total: totalExpenses,
                                    color: getColorForCategory(.additional)
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    HStack {
                        Text("Общая сумма расходов:")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: totalExpenses)) ?? "0") ₽")
                            .font(.subheadline).bold()
                            .foregroundColor(AppColors.primary)
                    }
                    .padding(.vertical, 8)
                }
            } else {
                Text("Нет данных о расходах")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .padding()
            }
        }
    }
    
    private func calculateStartAngle(for index: Int) -> Angle {
        var totalPercentage: Double = 0
        for i in 0..<index {
            if i < sortedCategories.count {
                totalPercentage += sortedCategories[i].1 / totalExpenses
            }
        }
        return Angle(degrees: 360 * totalPercentage)
    }
    
    private func getColorForCategory(_ category: ExpenseCategory) -> Color {
        switch category {
        case .rent: return AppColors.primary
        case .loans: return AppColors.danger
        case .utilities: return AppColors.warning
        case .groceries: return AppColors.success
        case .communication: return AppColors.accent
        case .subscriptions: return Color.purple
        case .transport: return Color.orange
        case .hobbies: return Color.pink
        case .entertainment: return Color.blue
        case .beauty: return Color.mint
        case .marketplaces: return Color.teal
        case .additional: return Color.gray
        }
    }
}

struct PieSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2 - 10
                
                path.move(to: center)
                path.addArc(center: center,
                           radius: radius,
                           startAngle: startAngle,
                           endAngle: endAngle,
                           clockwise: false)
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

struct ExpenseCategoryRow: View {
    let category: ExpenseCategory
    let amount: Double
    let total: Double
    let color: Color
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return (amount / total) * 100
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(category.rawValue)
                .font(.subheadline)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .truncationMode(.tail)
            
            Text("\(Int(percentage))%")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 40, alignment: .trailing)
            
            Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: amount)) ?? "0") ₽")
                .font(.subheadline)
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 90, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }
}
