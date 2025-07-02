import SwiftUI

struct MainAppView: View {
    @State private var goals: [Goal] = []
    @State private var showingAddGoal = false
    @State private var selectedGoal: Goal? = nil
    @State private var editingGoal: Goal? = nil
    @State private var showingFeedback = false

    @AppStorage("monthlySaving") private var income: Double = 0
    @AppStorage("savingDay") private var savingDay: Int = 10

    private let goalsKey = "user_goals"

    init() {
        loadGoals()
    }

    var achievedGoals: [Goal] { goals.filter { $0.currentAmount >= $0.targetAmount } }
    var activeGoals: [Goal] { goals.filter { $0.currentAmount < $0.targetAmount } }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    Text("Мои цели")
                        .font(.largeTitle).bold()
                        .foregroundColor(AppColors.textPrimary)
                        .padding([.top, .horizontal])
                        .padding(.bottom, 4)

                    // Новый блок: прогноз накоплений за год
                    let yearlySaving = income * 12
                    let totalGoals = goals.reduce(0) { $0 + $1.targetAmount }
                    let availableAfterGoals = yearlySaving - totalGoals
                    VStack(alignment: .leading, spacing: 6) {
                        Text("За год вы сможете накопить: \(numberFormatter.string(from: NSNumber(value: yearlySaving)) ?? "0") ₽")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        Text("Останется после достижения всех целей: \(numberFormatter.string(from: NSNumber(value: availableAfterGoals)) ?? "0") ₽")
                            .font(.subheadline)
                            .foregroundColor(availableAfterGoals >= 0 ? AppColors.success : AppColors.danger)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    if goals.isEmpty {
                        Spacer()
                        Text("Добавьте первую цель, чтобы начать путь к мечте!")
                            .font(.title3)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    } else {
                        List {
                            let sortedActive = activeGoals.sorted { $0.targetDate < $1.targetDate }
                            let forecastDates = calculateForecastDates(for: sortedActive)
                            let zipped = Array(zip(sortedActive, forecastDates))
                            ForEach(zipped.indices, id: \ .self) { idx in
                                let (goal, forecast) = zipped[idx]
                                goalCard(goal: goal, forecast: forecast)
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .trailing) {
                                        Button {
                                            editingGoal = goal
                                        } label: {
                                            Label("Редактировать", systemImage: "pencil")
                                        }
                                        .tint(AppColors.primary)

                                        Button(role: .destructive) {
                                            if let index = goals.firstIndex(where: { $0.id == goal.id }) {
                                                goals.remove(at: index)
                                                saveGoals()
                                            }
                                        } label: {
                                            Label("Удалить", systemImage: "trash")
                                        }
                                    }
                            }
                            ForEach(achievedGoals.sorted { $0.targetDate < $1.targetDate }) { goal in
                                goalCard(goal: goal, forecast: nil, achieved: true)
                                    .listRowBackground(Color.clear)
                                    // Не добавляем свайпы для достигнутых целей
                            }
                        }
                        .listStyle(.plain)
                        .padding(.bottom, 32) // чтобы не перекрывало TabBar
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAddGoal = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingFeedback = true
                        }) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .foregroundColor(AppColors.accent)
                        }
                    }
                }
                .sheet(isPresented: $showingAddGoal) {
                    AddGoalView(goals: $goals, onSave: saveGoals)
                }
                .sheet(item: $selectedGoal) { goal in
                    DepositView(goal: Binding(
                        get: {
                            goals.first(where: { $0.id == goal.id }) ?? goal
                        },
                        set: { updated in
                            if let idx = goals.firstIndex(where: { $0.id == updated.id }) {
                                goals[idx] = updated
                                saveGoals()
                            }
                        }
                    )) {
                        selectedGoal = nil
                        saveGoals()
                    }
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
            }
        }
    }

    func saveGoals() {
        if let data = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(data, forKey: goalsKey)
        }
    }

    func loadGoals() {
        if let data = UserDefaults.standard.data(forKey: goalsKey),
           let decoded = try? JSONDecoder().decode([Goal].self, from: data) {
            goals = decoded
        }
    }

    func calculateForecastDates(for goals: [Goal]) -> [Date?] {
        var result: [Date?] = []
        var lastForecast: Date = Date()
        for goal in goals {
            let forecast = forecastDate(goal: goal, savingDay: savingDay, from: lastForecast)
            result.append(forecast)
            if let f = forecast { lastForecast = f }
        }
        return result
    }

    @ViewBuilder
    func goalCard(goal: Goal, forecast: Date?, achieved: Bool = false) -> some View {
        let isOverdue = forecast != nil && (forecast! > goal.targetDate) && (Calendar.current.dateComponents([.day], from: goal.targetDate, to: forecast!).day ?? 0) > 7
        let progress = min(goal.currentAmount / max(goal.targetAmount, 1), 1.0)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(goal.name)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                if achieved {
                    Text("🏆")
                        .font(.headline)
                        .padding(.trailing, 4)
                }
            }
            Text("Цель: \(numberFormatter.string(from: NSNumber(value: goal.targetAmount)) ?? "0") ₽, накоплено: \(numberFormatter.string(from: NSNumber(value: goal.currentAmount)) ?? "0") ₽")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
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
            HStack {
                Text("Желаемая дата: \(dateFormatter.string(from: goal.targetDate))")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
            }
            if !achieved {
                if let forecast = forecast {
                    HStack(spacing: 4) {
                        Text("Прогноз:")
                            .font(.caption)
                            .foregroundColor(isOverdue ? AppColors.danger : AppColors.textSecondary)
                        Text("\(dateFormatter.string(from: forecast))")
                            .font(.caption)
                            .foregroundColor(isOverdue ? AppColors.danger : AppColors.textSecondary)
                    }
                } else {
                    Text("Необходимо внести данные по накоплениям")
                        .font(.caption)
                        .foregroundColor(AppColors.danger)
                }
            } else {
                Text("Цель достигнута! 🎉")
                    .font(.caption)
                    .foregroundColor(AppColors.success)
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(16)
        .shadow(color: AppColors.primary.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    achieved ? AppColors.success : (isOverdue ? AppColors.danger : Color.clear),
                    lineWidth: (isOverdue || achieved) ? 2 : 0
                )
        )
        .onTapGesture {
            if !achieved {
                selectedGoal = goal
            }
        }
    }

    func deleteGoal(at offsets: IndexSet) {
        goals.remove(atOffsets: offsets)
        saveGoals()
    }

    func forecastDate(goal: Goal, savingDay: Int, from: Date = Date()) -> Date? {
        let monthlySaving = max(income, 0.0)
        let leftToSave = max(goal.targetAmount - goal.currentAmount, 0.0)
        let monthsToGoal = monthlySaving > 0 ? Int(ceil(leftToSave / monthlySaving)) : nil
        guard let months = monthsToGoal, months >= 0 else { return nil }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: from)
        let today = calendar.component(.day, from: from)

        // Если день накопления еще не наступил или сегодня день накопления — первая сумма уже в этом месяце
        if today <= savingDay {
            // ничего не меняем, первая выплата в этом месяце
        } else {
            // если день накопления уже прошел — первая выплата только в следующем месяце
            components.month! += 1
        }
        // Прибавляем оставшиеся месяцы
        components.month! += months - 1
        // Устанавливаем день накопления, но не больше последнего дня месяца
        if let targetMonthDate = calendar.date(from: components),
           let range = calendar.range(of: .day, in: .month, for: targetMonthDate) {
            components.day = min(savingDay, range.count)
            return calendar.date(from: components)
        }
        return nil
    }
}

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
