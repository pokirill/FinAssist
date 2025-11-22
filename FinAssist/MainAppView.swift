import SwiftUI
import Foundation

struct MainAppView: View {
    @State private var goals: [Goal] = []
    @State private var incomes: [Income] = []
    @State private var bonuses: [Bonus] = []
    @State private var expenses: [Expense] = []
    @State private var credits: [Credit] = []
    @State private var showingAddGoal = false
    @State private var selectedGoal: Goal? = nil
    @State private var editingGoal: Goal? = nil
    @State private var showingFeedback = false
    @State private var showingSettings = false

    @AppStorage("emergencyFundEnabled") private var emergencyFundEnabled: Bool = true
    @AppStorage("emergencyFundMonths") private var emergencyFundMonths: Int = 3
    @AppStorage("emergencyFundSkipPeriod") private var emergencyFundSkipPeriod: Bool = false

    private let goalsKey = "user_goals"
    private let incomeKey = "user_income"
    private let expenseKey = "user_expense"
    private let creditsKey = "user_credits"

    var body: some View {
        NavigationView {
            mainContent
        }
        .onAppear {
            loadGoals()
            loadFinancialData()
            updateEmergencyFund()
        }
        .onChange(of: emergencyFundEnabled) { _ in
            updateEmergencyFund()
        }
        .onChange(of: emergencyFundMonths) { _ in
            updateEmergencyFund()
        }
        .refreshable {
            loadFinancialData()
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    Text("Мои цели")
                        .font(.largeTitle).bold()
                        .foregroundColor(AppColors.textPrimary)
                        .padding([.top, .horizontal])
                        .padding(.bottom, 4)

                summaryBlock
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: toolbarContent)
                .sheet(isPresented: $showingAddGoal) {
                    AddGoalView(goals: $goals, onSave: saveGoals)
                }
                .sheet(item: $selectedGoal) { goal in
                    DepositView(
                        goal: Binding(
                            get: {
                                goals.first(where: { $0.id == goal.id }) ?? goal
                            },
                            set: { updated in
                                if let idx = goals.firstIndex(where: { $0.id == updated.id }) {
                                    goals[idx] = updated
                                    saveGoals()
                                }
                            }
                        ),
                        onClose: { selectedGoal = nil },
                        onSave: saveGoals
                    )
                }
                .sheet(item: $editingGoal) { goal in
                    EditGoalView(goal: goal, onSave: { updatedGoal in
                        if let idx = goals.firstIndex(where: { $0.id == updatedGoal.id }) {
                            goals[idx] = updatedGoal
                            saveGoals()
                        }
                        editingGoal = nil
                    })
                }
                .sheet(isPresented: $showingFeedback) {
                    FeedbackView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    @ViewBuilder
    private var summaryBlock: some View {
        let today = Date()
        let horizonDate = Calendar.current.date(byAdding: .year, value: 10, to: today)!
                    
        
        // Проверяем, есть ли данные о доходах и расходах
        let hasFinancialData = !incomes.isEmpty || !expenses.isEmpty
        let totalMonthlyIncome = incomes.reduce(0) { $0 + $1.totalMonthlyIncome }
        let baseMonthlyExpense = expenses.reduce(0) { $0 + $1.totalMonthlyExpense }
        
        // Добавляем кредиты к расходам (только активные)
        let totalCreditPayments = credits.reduce(0.0) { sum, credit in
            // Учитываем только активные кредиты (без даты окончания или с будущей датой)
            if credit.endDate == nil || credit.endDate! > Date() {
                return sum + credit.monthlyAmount
            }
            return sum
        }
        let totalMonthlyExpense = baseMonthlyExpense + totalCreditPayments
        let hasEnoughIncome = totalMonthlyIncome > totalMonthlyExpense
        
        let events = EventBuilder.buildEvents(
                        incomes: incomes,
                        bonuses: bonuses,
                        expenses: expenses,
                        credits: credits,
                        from: today,
                        to: horizonDate
                    )
        let (updatedGoals, _, freeCashByDate, accumulatedByDate) = ForecastEngine.dayByDayForecast(
            events: events,
            goals: goals,
            wishlistItems: [],
            from: today,
            to: horizonDate,
            skipEmergencyFundInPeriod: emergencyFundSkipPeriod
        )
        
        // Рассчитываем новую статистику для верхнего блока
        let freePerMonth = (totalMonthlyIncome - totalMonthlyExpense)
        
        // Считаем активные цели (не достигнутые) - проверяем по ИСХОДНЫМ данным!
        let activeGoals = updatedGoals.filter { updatedGoal in
            let originalGoal = goals.first(where: { $0.id == updatedGoal.id }) ?? updatedGoal
            return originalGoal.currentAmount < originalGoal.targetAmount
        }
        
        let goalsOnTrack = activeGoals.filter { goal in
            let required = goal.requiredPerMonth ?? 0
            let actual = goal.actualPerMonth ?? 0
            
            // Проверяем не только деньги, но и прогнозную дату
            let hasEnoughMoney = required > 0 && actual >= required
            
            guard let forecast = goal.forecastDate else { return false }
            let daysOverdue = Calendar.current.dateComponents([.day], from: goal.targetDate, to: forecast).day ?? 0
            // Допуск 30 дней из-за дискретности выплат и приоритетов
            let meetsDeadline = daysOverdue <= 30
            
            return hasEnoughMoney && meetsDeadline
        }.count
        
        let goalsAtRisk = activeGoals.filter { goal in
            let required = goal.requiredPerMonth ?? 0
            let actual = goal.actualPerMonth ?? 0
            
            // Под риском если: недостаточно денег ИЛИ не укладываемся в дату
            if required > 0 && actual < required {
                return true
            }
            
            guard let forecast = goal.forecastDate else { return false }
            let daysOverdue = Calendar.current.dateComponents([.day], from: goal.targetDate, to: forecast).day ?? 0
            // Допуск 30 дней
            return daysOverdue > 30
        }.count
        
        // Для хотелок: свободно минус выделено на цели
        let totalActualPerMonth = activeGoals.reduce(0.0) { sum, goal in
            sum + (goal.actualPerMonth ?? 0)
        }
        let wishlistPerMonth = max(0, freePerMonth - totalActualPerMonth)
        
        // Пустое состояние: нет доходов/расходов
        if !hasFinancialData {
            VStack(alignment: .leading, spacing: 6) {
                Text("⚠️ Необходимо указать доходы и расходы")
                    .font(.headline)
                    .foregroundColor(AppColors.warning)
                Text("Перейдите на вкладку «Доходы и расходы» для настройки")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding()
            .background(AppColors.warning.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 8)
        } else if !hasEnoughIncome {
            VStack(alignment: .leading, spacing: 6) {
                Text("⚠️ Доходы не покрывают расходы")
                    .font(.headline)
                    .foregroundColor(AppColors.danger)
                Text("При текущих параметрах цели недостижимы. Проверьте доходы и расходы.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding()
            .background(AppColors.danger.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 8)
        } else {
            // Новый компактный summary-блок
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Свободно на цели:")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: freePerMonth)) ?? "0") ₽/мес")
                        .font(.headline)
                        .foregroundColor(freePerMonth > 0 ? AppColors.primary : AppColors.danger)
                }
                
                HStack {
                    Text("Цели:")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    if updatedGoals.isEmpty {
                        Text("пока нет целей")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    } else {
                        HStack(spacing: 4) {
                            if goalsOnTrack > 0 {
                                Text("\(goalsOnTrack) в графике")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.success)
                            }
                            if goalsOnTrack > 0 && goalsAtRisk > 0 {
                                Text("•")
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            if goalsAtRisk > 0 {
                                Text("\(goalsAtRisk) под риском")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.warning)
                            }
                            // Если все цели достигнуты (нет активных целей)
                            if activeGoals.isEmpty && !updatedGoals.isEmpty {
                                Text("все достигнуты")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.success)
                            }
                        }
                    }
                }
                
                HStack {
                    Text("На хотелки:")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    if wishlistPerMonth > 0 {
                        Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: wishlistPerMonth)) ?? "0") ₽/мес")
                            .font(.subheadline)
                            .foregroundColor(AppColors.accent)
                    } else {
                        Text("Всё уходит на обязательные платежи и цели")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .padding()
            .background(AppColors.surface)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        
        // Пустое состояние: нет целей
        if updatedGoals.isEmpty {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "target")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.primary.opacity(0.5))
                
                Text("Добавьте первую цель")
                    .font(.title2).bold()
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Начните путь к своей мечте – создайте цель и следите за прогрессом")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button(action: {
                    showingAddGoal = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Добавить цель")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(AppColors.primary)
                    .cornerRadius(12)
                }
            }
            .padding()
            Spacer()
        } else {
            List {
                ForEach(updatedGoals) { updatedGoal in
                    // Берем исходную цель для проверки достижения
                    let originalGoal = goals.first(where: { $0.id == updatedGoal.id }) ?? updatedGoal
                    let isAchieved = originalGoal.currentAmount >= originalGoal.targetAmount
                    
                    // Используем updatedGoal для данных расчета, но исходное состояние для achieved
                    goalCard(
                        goal: updatedGoal,
                        forecast: updatedGoal.forecastDate,
                        achieved: isAchieved,
                        forecastCurrentAmount: originalGoal.currentAmount
                    )
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            // Подушка не редактируется/удаляется вручную
                            if updatedGoal.type != .emergencyFund {
                                Button {
                                    editingGoal = originalGoal
                                } label: {
                                    Label("Редактировать", systemImage: "pencil")
                                }
                                .tint(AppColors.primary)
                                
                                Button(role: .destructive) {
                                    if let index = goals.firstIndex(where: { $0.id == originalGoal.id }) {
                                        goals.remove(at: index)
                                        saveGoals()
                                    }
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                }
            }
            .listStyle(.plain)
            .padding(.bottom, 32)
        }
    }

    func saveGoals() {
        if let data = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(data, forKey: goalsKey)
            print("Сохранено целей: \(goals.count)")
        }
        
        // Обновляем сводные данные для использования в других экранах (например, WishlistView)
        let totalMonthlyIncome = incomes.reduce(0) { $0 + $1.totalMonthlyIncome }
        let baseMonthlyExpense = expenses.reduce(0) { $0 + $1.totalMonthlyExpense }
        let totalCreditPayments = credits.reduce(0.0) { sum, credit in
            if credit.endDate == nil || credit.endDate! > Date() {
                return sum + credit.monthlyAmount
            }
            return sum
        }
        let totalMonthlyExpense = baseMonthlyExpense + totalCreditPayments
        
        UserDefaults.standard.set(totalMonthlyIncome, forKey: "totalMonthlyIncome")
        UserDefaults.standard.set(totalMonthlyExpense, forKey: "totalMonthlyExpense")
    }

    func loadGoals() {
        if let data = UserDefaults.standard.data(forKey: goalsKey),
           let decoded = try? JSONDecoder().decode([Goal].self, from: data) {
            goals = decoded
            print("Загружено целей: \(goals.count)")
        } else {
            print("Цели не найдены в UserDefaults")
        }
    }
    
    func loadFinancialData() {
        // Очищаем массивы перед загрузкой, чтобы избежать дублирования
        incomes = []
        bonuses = []
        expenses = []
        credits = []
        
        // Загружаем доходы
        if let incomeData = UserDefaults.standard.data(forKey: incomeKey),
           let decodedIncome = try? JSONDecoder().decode(Income.self, from: incomeData) {
            incomes = [decodedIncome]
            // Извлекаем bonuses из income
            bonuses = decodedIncome.bonuses
            print("Загружены данные о доходах: \(decodedIncome.totalMonthlyIncome) ₽")
        }
        
        // Загружаем расходы
        if let expenseData = UserDefaults.standard.data(forKey: expenseKey),
           let decodedExpense = try? JSONDecoder().decode(Expense.self, from: expenseData) {
            expenses = [decodedExpense]
            print("Загружены данные о расходах: \(decodedExpense.totalMonthlyExpense) ₽")
        }
        
        // Загружаем кредиты
        if let creditsData = UserDefaults.standard.data(forKey: creditsKey),
           let decodedCredits = try? JSONDecoder().decode([Credit].self, from: creditsData) {
            credits = decodedCredits
            print("Загружены данные о кредитах: \(credits.count)")
        }
    }
    
    func updateEmergencyFund() {
        guard emergencyFundEnabled else {
            // Удаляем подушку если она выключена
            goals.removeAll { $0.type == .emergencyFund }
            saveGoals()
            return
        }
        
        // Рассчитываем целевую сумму подушки
        let monthlyIncome = incomes.first?.totalMonthlyIncome ?? 0
        let targetAmount = monthlyIncome * Double(emergencyFundMonths)
        
        guard targetAmount > 0 else { return }
        
        // Ищем существующую подушку
        if let index = goals.firstIndex(where: { $0.type == .emergencyFund }) {
            // Обновляем существующую подушку
            goals[index].targetAmount = targetAmount
            goals[index].skipInPeriod = emergencyFundSkipPeriod
        } else {
            // Создаем новую подушку
            let emergencyFund = Goal(
                name: "Подушка безопасности",
                targetAmount: targetAmount,
                currentAmount: 0,
                targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date(),
                description: "Резервный фонд на \(emergencyFundMonths) месяцев",
                priority: .important,
                type: .emergencyFund
            )
            goals.insert(emergencyFund, at: 0)
        }
        
        saveGoals()
    }
    
    func clearAllData() {
        // Очистка всех данных приложения
        UserDefaults.standard.removeObject(forKey: goalsKey)
        UserDefaults.standard.removeObject(forKey: incomeKey)
        UserDefaults.standard.removeObject(forKey: expenseKey)
        UserDefaults.standard.removeObject(forKey: creditsKey)
        UserDefaults.standard.removeObject(forKey: "hasCalculatedThroughApp")
        UserDefaults.standard.removeObject(forKey: "monthlySaving")
        UserDefaults.standard.removeObject(forKey: "savingDay")
        // НЕ очищаем didShowOnboarding, чтобы не показывать онбординг повторно
        
        // Сбрасываем локальные состояния
        goals = []
        incomes = []
        bonuses = []
        expenses = []
        credits = []
        
        print("✅ Все данные приложения очищены")
        
        // Перезагружаем данные
        loadGoals()
        loadFinancialData()
    }

    @ViewBuilder
    func goalCard(goal: Goal, forecast: Date?, achieved: Bool = false, forecastCurrentAmount: Double? = nil) -> some View {
        GoalCardView(
            goal: goal,
            forecast: forecast,
            achieved: achieved,
            forecastCurrentAmount: forecastCurrentAmount,
            incomes: incomes,
            emergencyFundMonths: emergencyFundMonths,
            selectedGoal: $selectedGoal,
            showingSettings: $showingSettings
        )
    }
    
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                Button(action: {
                    showingSettings = true
                }) {
                    Label("Настройки", systemImage: "gearshape")
                }
                
                Button(action: {
                    showingFeedback = true
                }) {
                    Label("Обратная связь", systemImage: "bubble.left.and.bubble.right")
                }
                
                Divider()
                
                Button(role: .destructive, action: {
                    clearAllData()
                }) {
                    Label("Очистить все данные", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(AppColors.primary)
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                showingAddGoal = true
            }) {
                Image(systemName: "plus")
                    .foregroundColor(AppColors.primary)
            }
        }
    }
}

struct GoalCardView: View {
    let goal: Goal
    let forecast: Date?
    let achieved: Bool
    let forecastCurrentAmount: Double?
    let incomes: [Income]
    let emergencyFundMonths: Int
    @Binding var selectedGoal: Goal?
    @Binding var showingSettings: Bool
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        // Используем переданный параметр achieved (на основе исходных данных)
        // а не goal.currentAmount (который изменён после симуляции)
        let currentlyAchieved = achieved
        let isOverdue = forecast != nil && (forecast! > goal.targetDate) &&
            (Calendar.current.dateComponents([.day], from: goal.targetDate, to: forecast!).day ?? 0) > 7
        // Используем forecastCurrentAmount (исходное значение) для отображения
        let displayAmount = max(0, forecastCurrentAmount ?? goal.currentAmount)
        let progress = min(displayAmount / max(goal.targetAmount, 1), 1.0)
        
        // Статус цели для свернутого вида
        let shortStatus: (text: String, color: Color, icon: String) = {
            if currentlyAchieved {
                return ("✓ Достигнута", AppColors.success, "checkmark.circle.fill")
            }
            
            // Для целей с приоритетом "Желаемая" показываем прогноз, а не статус
            if goal.priority == .niceToHave {
                if let forecast = forecast {
                    let dateStr = AppUtils.shortDateFormatter.string(from: forecast)
                    return ("📅 \(dateStr)", AppColors.primary, "calendar")
                } else {
                    return ("⚙️ Расчет...", AppColors.textSecondary.opacity(0.7), "hourglass")
                }
            }
            
            let required = goal.requiredPerMonth ?? 0
            let actual = goal.actualPerMonth ?? 0
            
            if required == 0 && actual == 0 {
                // Нет данных
                return ("⚙️ Расчет...", AppColors.textSecondary.opacity(0.7), "hourglass")
            }
            
            // Проверяем не только actual >= required, но и прогнозную дату!
            if required > 0 {
                let hasEnoughMoney = actual >= required
                
                // Проверяем укладываемся ли в желаемую дату (допуск 30 дней = 1 месяц)
                // Небольшое отклонение допустимо из-за дискретности выплат и приоритетов
                let meetsDeadline: Bool = {
                    guard let forecast = forecast else { return false }
                    let daysOverdue = Calendar.current.dateComponents([.day], from: goal.targetDate, to: forecast).day ?? 0
                    return daysOverdue <= 30
                }()
                
                if hasEnoughMoney && meetsDeadline {
                    return ("✓ Успеваем", AppColors.success, "checkmark.circle.fill")
                } else {
                    return ("⚠ Не успеваем", AppColors.warning, "exclamationmark.triangle.fill")
                }
            } else {
                return ("", AppColors.textSecondary, "")
            }
        }()
        
        VStack(alignment: .leading, spacing: 10) {
            // Шапка карточки (всегда видна, кликабельна)
            HStack(spacing: 12) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
            HStack {
                    VStack(alignment: .leading, spacing: 6) {
                Text(goal.name)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                        
                        HStack(spacing: 8) {
                            // Приоритет
                            Text(goal.priority.displayName)
                                .font(.caption)
                                .foregroundColor(goal.priority == .critical ? AppColors.danger : 
                                                goal.priority == .important ? AppColors.warning : 
                                                AppColors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(goal.priority == .critical ? AppColors.danger.opacity(0.1) :
                                            goal.priority == .important ? AppColors.warning.opacity(0.1) :
                                            AppColors.textSecondary.opacity(0.1))
                                .cornerRadius(6)
                            
                            // Статус - ВСЕГДА показываем для незавершенных целей
                            if !currentlyAchieved && !shortStatus.text.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: shortStatus.icon)
                                        .font(.caption2)
                                    Text(shortStatus.text)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(shortStatus.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(shortStatus.color.opacity(0.15))
                                .cornerRadius(6)
                            }
                        }
                    }
                Spacer()
                    
                    HStack(spacing: 8) {
                        if currentlyAchieved {
                    Text("🏆")
                        .font(.headline)
                        }
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    selectedGoal = goal
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Прогресс-бар (всегда виден)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [AppColors.primary, AppColors.accent]),
                        startPoint: .leading, endPoint: .trailing))
                    .frame(height: 10)
                    .opacity(0.15)
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [AppColors.primary, AppColors.accent]),
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: CGFloat(progress) * UIScreen.main.bounds.width * 0.7, height: 10)
                    .animation(.easeInOut, value: progress)
            }
            .padding(.vertical, 2)
            
            // Детали (показываем только при развертывании)
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Цель: \(AppUtils.numberFormatter.string(from: NSNumber(value: goal.targetAmount)) ?? "0") ₽, накоплено: \(AppUtils.numberFormatter.string(from: NSNumber(value: displayAmount)) ?? "0") ₽")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    // Для подушки НЕ показываем "Желаемая дата"
                    // Для целей с приоритетом "Желаемая" тоже не показываем (пользователь не указывал)
                    if goal.type != .emergencyFund && goal.priority != .niceToHave {
            HStack {
                Text("Желаемая дата: \(AppUtils.dateFormatter.string(from: goal.targetDate))")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
            }
                    }
                    // Для подушки: показываем сколько месяцев покрытия уже есть
                    if goal.type == .emergencyFund {
                        let monthlyIncome = incomes.first?.totalMonthlyIncome ?? 1
                        let currentMonthsCoverage = displayAmount / monthlyIncome
                        Text("💰 Покрытие: \(String(format: "%.1f", currentMonthsCoverage)) мес. из \(emergencyFundMonths)")
                            .font(.caption)
                            .foregroundColor(currentMonthsCoverage >= Double(emergencyFundMonths) ? AppColors.success : AppColors.primary)
                        
                        // Кнопка настройки подушки
                        Button {
                            showingSettings = true
                        } label: {
                            HStack {
                                Image(systemName: "gearshape")
                                    .font(.caption)
                                Text("Настроить подушку")
                                    .font(.caption)
                            }
                            .foregroundColor(AppColors.primary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(AppColors.primary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Блок "Нужно / План дает" - ТОЛЬКО для незавершенных целей И не "Желаемых"
                    if !currentlyAchieved && goal.priority != .niceToHave {
                        Divider()
                            .padding(.vertical, 4)
                        
                        // Точные значения для логики
                        let requiredExact = goal.requiredPerMonth ?? 0
                        let actualExact = goal.actualPerMonth ?? 0
                        
                        // Округляем до сотен для красивого UI
                        let requiredDisplay = (requiredExact / 100.0).rounded() * 100.0
                        let actualDisplay = (actualExact / 100.0).rounded() * 100.0
                        
                        if requiredExact > 0 {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Нужно:")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                    Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: requiredDisplay)) ?? "0") ₽/мес")
                                        .font(.subheadline).bold()
                                        .foregroundColor(AppColors.textPrimary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("План даёт:")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                    Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: actualDisplay)) ?? "0") ₽/мес")
                                        .font(.subheadline).bold()
                                        .foregroundColor(actualExact >= requiredExact ? AppColors.success : AppColors.warning)
                                }
                            }
                            
                            // Статус цели - проверяем ТОЧНЫЕ значения, не округленные!
                            let hasEnoughMoney = actualExact >= requiredExact
                            let meetsDeadline: Bool = {
                                guard let forecast = forecast else { return false }
                                let daysOverdue = Calendar.current.dateComponents([.day], from: goal.targetDate, to: forecast).day ?? 0
                                // Допуск 30 дней из-за дискретности выплат и приоритетов
                                return daysOverdue <= 30
                            }()
                            
                            if hasEnoughMoney && meetsDeadline {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(AppColors.success)
                                    Text("Успеваем, в графике")
                                        .font(.caption).bold()
                                        .foregroundColor(AppColors.success)
                                }
                            } else if !hasEnoughMoney {
                                let deficit = requiredExact - actualExact
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundColor(AppColors.warning)
                                    Text("Не успеваем, нужно +\(AppUtils.numberFormatter.string(from: NSNumber(value: deficit)) ?? "0") ₽/мес")
                                        .font(.caption).bold()
                                        .foregroundColor(AppColors.warning)
                                }
                            }
                            // Для случая !meetsDeadline - показываем только внизу в блоке прогноза
                        }
                    }
                    
                    // Для "Желаемых" целей показываем просто информацию о прогнозе
                    if !currentlyAchieved && goal.priority == .niceToHave {
                        Divider()
                            .padding(.vertical, 4)
                        
                        Text("Для желаемых целей копим из остатков после основных целей")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .italic()
                    }
                    
                    // Подцели для путешествия
                    if goal.type == .travel, let subgoals = goal.travelSubgoals {
                        Divider()
                            .padding(.vertical, 4)
                        
                        Text("🗺 План поездки:")
                            .font(.subheadline).bold()
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.bottom, 4)
                        
                        VStack(spacing: 12) {
                            ForEach(subgoals, id: \.name) { subgoal in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(subgoal.displayName)
                                                .font(.caption).bold()
                                                .foregroundColor(AppColors.textPrimary)
                                            
                                            if subgoal.currentAmount >= subgoal.amount {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.caption)
                                                    .foregroundColor(AppColors.success)
                                            }
                                        }
                                        
                                        Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: subgoal.amount)) ?? "0") ₽")
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("К \(AppUtils.shortDateFormatter.string(from: subgoal.targetDate))")
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                        
                                        // Прогресс бар для каждой подцели
                                        let progress = min(subgoal.currentAmount / subgoal.amount, 1.0)
                                        ProgressView(value: progress)
                                            .frame(width: 80)
                                            .tint(AppColors.accent)
                                    }
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(AppColors.background)
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Прогнозная дата
                    Divider()
                        .padding(.vertical, 4)
                    
                    if !currentlyAchieved {
                        if let forecast = forecast {
                            HStack(spacing: 4) {
                                Text("Прогноз достижения:")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Text(AppUtils.shortDateFormatter.string(from: forecast))
                                    .font(.caption).bold()
                                    .foregroundColor(isOverdue ? AppColors.danger : AppColors.primary)
                            }
                            
                            if isOverdue {
                                Text("⚠️ Не укладываемся в желаемую дату")
                                    .font(.caption)
                                    .foregroundColor(AppColors.danger)
                            }
                        } else if goal.requiredPerMonth != nil && (goal.requiredPerMonth ?? 0) > 0 {
                            Text("⚠️ При текущих параметрах цель недостижима")
                        .font(.caption)
                        .foregroundColor(AppColors.danger)
                }
            } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                Text("Цель достигнута! 🎉")
                                .font(.caption).bold()
                        }
                    .foregroundColor(AppColors.success)
                    }
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(16)
        .shadow(color: AppColors.primary.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    currentlyAchieved ? AppColors.success : (isOverdue ? AppColors.danger : Color.clear),
                    lineWidth: (isOverdue || currentlyAchieved) ? 2 : 0
                )
        )
        .onAppear {
            // DEBUG вывод при появлении карточки
            print("GoalCardView \(goal.name): currentlyAchieved=\(currentlyAchieved), req=\(goal.requiredPerMonth?.description ?? "nil"), act=\(goal.actualPerMonth?.description ?? "nil")")
        }
    }
}
