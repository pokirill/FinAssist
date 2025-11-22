import SwiftUI

struct PeriodDistributionView: View {
    @Environment(\.dismiss) var dismiss
    
    let income: Income
    @Binding var expense: Expense
    @Binding var credits: [Credit]
    let goals: [Goal]
    
    @AppStorage("emergencyFundEnabled") private var emergencyFundEnabled: Bool = true
    
    @State private var selectedPeriod: DistributionPeriod = .month
    @State private var showingExpenseModal = false
    
    private var calculator: DistributionCalculator {
        DistributionCalculator(
            income: income,
            expense: expense,
            credits: credits,
            goals: goals,
            emergencyFundEnabled: emergencyFundEnabled,
            selectedPeriod: selectedPeriod
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Segmented Control
                    Picker("Период", selection: $selectedPeriod) {
                        ForEach(DistributionPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Сводка
                    summaryBlock
                    
                    // Stacked Bar
                    stackedBar
                    
                    // Детальная таблица
                    detailsTable
                    
                    // Подсказка внизу
                    bottomHint
                }
                .padding(.bottom, 32)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Распределение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
            .sheet(isPresented: $showingExpenseModal) {
                ExpenseModalView(expense: $expense, credits: $credits, onSave: {
                    // View will update automatically due to Binding
                })
            }
        }
    }
    
    // MARK: - UI
    
    private var summaryBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Доход периода: \(format(calculator.periodIncome))")
                .font(.title3).bold()
                .foregroundColor(AppColors.textPrimary)
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                summaryRow(title: "Запланированные (включая кредиты)", amount: calculator.totalPlanned, color: AppColors.danger)
                summaryRow(title: "Регулярные", amount: calculator.totalRegular, color: AppColors.warning)
                summaryRow(title: "Кошелёк", amount: calculator.walletTarget, color: AppColors.success)
                if emergencyFundEnabled {
                    summaryRow(title: "Подушка", amount: calculator.emergencyAmount, color: Color.blue)
                }
                summaryRow(title: "Цели", amount: calculator.totalGoals, color: AppColors.primary)
                summaryRow(title: "Неожиданные / Хотелки", amount: calculator.unexpectedAmount, color: calculator.capacity <= 0 ? AppColors.danger : Color.gray)
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func summaryRow(title: String, amount: Double, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title).font(.subheadline).foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(format(amount)).font(.subheadline).bold().foregroundColor(AppColors.textPrimary)
        }
    }
    
    private var stackedBar: some View {
        GeometryReader { geometry in
            let total = max(calculator.periodIncome, 1)
            let scale = geometry.size.width / total
            
            HStack(spacing: 0) {
                barSegment(width: calculator.totalPlanned * scale, color: AppColors.danger)
                barSegment(width: calculator.totalRegular * scale, color: AppColors.warning)
                barSegment(width: calculator.walletTarget * scale, color: AppColors.success)
                if emergencyFundEnabled {
                    barSegment(width: calculator.emergencyAmount * scale, color: Color.blue)
                }
                barSegment(width: calculator.totalGoals * scale, color: AppColors.primary)
                if calculator.unexpectedAmount > 0 {
                    barSegment(width: calculator.unexpectedAmount * scale, color: Color.gray)
                }
            }
        }
        .frame(height: 12)
        .cornerRadius(4)
        .padding(.horizontal)
    }
    
    private func barSegment(width: Double, color: Color) -> some View {
        Rectangle().fill(color).frame(width: max(0, width))
    }
    
    private var detailsTable: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Planned Categories
            if !calculator.plannedCategoryExpenses.isEmpty {
                sectionHeader("Запланированные (с датой)", color: AppColors.danger, edit: true)
                ForEach(calculator.plannedCategoryExpenses, id: \.name) { item in
                    HStack {
                        Text(item.name).font(.subheadline).foregroundColor(AppColors.textSecondary)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(format(item.amount)).bold()
                            Text("\(item.day) число").font(.caption2).foregroundColor(.gray)
                        }
                    }
                    .padding(.leading, 12)
                }
            }
            
            // Planned Credits
            if !calculator.creditExpenses.isEmpty {
                sectionHeader("Кредиты", color: AppColors.danger)
                ForEach(calculator.creditExpenses, id: \.name) { item in
                    HStack {
                        Text(item.name).font(.subheadline).foregroundColor(AppColors.textSecondary)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(format(item.amount)).bold()
                            Text("\(item.day) число").font(.caption2).foregroundColor(.gray)
                        }
                    }
                    .padding(.leading, 12)
                }
            }
            
            // Regular
            if !calculator.regularExpenses.isEmpty {
                sectionHeader("Регулярные (пропорционально)", color: AppColors.warning, edit: true)
                ForEach(calculator.regularExpenses, id: \.name) { item in
                    tableRow(item.name, item.amount)
                }
            }
            
            // Wallet
            sectionHeader("Кошелёк (на жизнь)", color: AppColors.success)
            tableRow("Повседневные траты", calculator.walletTarget)
            
            // Emergency
            if emergencyFundEnabled && calculator.emergencyAmount > 0 {
                sectionHeader("Подушка", color: Color.blue)
                tableRow("Подушка безопасности", calculator.emergencyAmount)
            }
            
            // Goals
            if !calculator.goalsAllocations.isEmpty {
                sectionHeader("Цели", color: AppColors.primary)
                ForEach(calculator.goalsAllocations, id: \.goal.id) { item in
                    tableRow(item.goal.name, item.amount)
                }
            }
            
            // Unexpected / Remainder
            sectionHeader("Остаток", color: calculator.unexpectedAmount >= 0 ? Color.gray : AppColors.danger)
            tableRow("Неожиданные траты / Хотелки", calculator.unexpectedAmount)
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func sectionHeader(_ title: String, color: Color, edit: Bool = false) -> some View {
        HStack {
            Rectangle().fill(color).frame(width: 4, height: 20)
            Text(title).font(.headline).foregroundColor(AppColors.textPrimary)
            Spacer()
            if edit {
                Button("Изменить") { showingExpenseModal = true }
                    .font(.caption).foregroundColor(AppColors.primary)
            }
        }
    }
    
    private func tableRow(_ name: String, _ amount: Double) -> some View {
        HStack {
            Text(name).font(.subheadline).foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(format(amount)).font(.subheadline).bold().foregroundColor(AppColors.textPrimary)
        }
        .padding(.leading, 12)
    }
    
    private var bottomHint: some View {
        VStack(alignment: .leading) {
            if calculator.capacity <= 0 {
                Text("⚠️ В этом периоде не хватает \(format(calculator.deficit)) ₽. Цели/хотелки урезаны.")
                    .foregroundColor(AppColors.danger)
            } else if calculator.unexpectedAmount > 0 {
                Text("💡 \(format(calculator.unexpectedAmount)) можно пустить на кошелёк или хотелки.")
                    .foregroundColor(AppColors.textSecondary)
            } else {
                Text("💡 Всё учтено: мощности периода хватило на обязательные расходы и цели.")
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(calculator.capacity <= 0 ? AppColors.danger.opacity(0.1) : AppColors.surface)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func format(_ value: Double) -> String {
        AppUtils.numberFormatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
