import SwiftUI

struct IncomeModalView: View {
    @Binding var income: Income
    var onSave: (() -> Void)?
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 0
    @State private var salaryAmount = ""
    @State private var advanceDate = 15
    @State private var advancePercentage: Double = 30
    @State private var salaryDate = 30
    @State private var salaryPercentage: Double = 70
    @State private var bonuses: [Bonus] = []
    
    private let steps = ["Зарплата", "Премии", "Завершение"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Прогресс бар
                    HStack {
                        ForEach(0..<steps.count, id: \.self) { index in
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
                        salaryStep
                            .tag(0)
                        
                        bonusesStep
                            .tag(1)
                        
                        completionStep
                            .tag(2)
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
                        
                        Button(currentStep == steps.count - 1 ? "Завершить" : "Далее") {
                            if currentStep == steps.count - 1 {
                                saveIncome()
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
            .navigationTitle("Доходы")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadExistingData()
        }
    }
    
    // Загрузка существующих данных
    private func loadExistingData() {
        if let salary = income.salary {
            salaryAmount = AppUtils.numberFormatter.string(from: NSNumber(value: salary.monthlyAmount)) ?? ""
            advanceDate = salary.advanceDate
            advancePercentage = salary.advancePercentage
            salaryDate = salary.salaryDate
            salaryPercentage = salary.salaryPercentage
        }
        bonuses = income.bonuses
    }
    
    // Шаг зарплаты
    private var salaryStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Сумма зарплаты
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ежемесячный оклад на руки")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    TextField("Сумма", text: $salaryAmount)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: salaryAmount) { newValue in
                            salaryAmount = AppUtils.formatInput(newValue)
                        }
                    
                    Text("Укажите сумму «на руки», кратно 1000 рублей")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Даты выплат
                HStack(spacing: 16) {
                    // Дата аванса
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Дата аванса")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Picker("Дата аванса", selection: $advanceDate) {
                            ForEach(1...28, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 100)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Дата зарплаты
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Дата зарплаты")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Picker("Дата зарплаты", selection: $salaryDate) {
                            ForEach(1...28, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 100)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Доли выплат
                VStack(spacing: 16) {
                    Text("Распределение выплат")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    // Аванс
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Аванс")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(Int(advancePercentage))%")
                                    .font(.title3).bold()
                                    .foregroundColor(AppColors.primary)
                                let totalAmount = Double(salaryAmount.replacingOccurrences(of: " ", with: "")) ?? 0
                                let advanceAmount = totalAmount * advancePercentage / 100.0
                                Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: advanceAmount)) ?? "0") ₽")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        
                        Slider(value: $advancePercentage, in: 0...100, step: 5)
                            .accentColor(AppColors.primary)
                            .onChange(of: advancePercentage) { newValue in
                                // Синхронизируем с зарплатой
                                salaryPercentage = 100 - newValue
                            }
                    }
                    
                    // Зарплата
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Зарплата")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(Int(salaryPercentage))%")
                                    .font(.title3).bold()
                                    .foregroundColor(AppColors.primary)
                                let totalAmount = Double(salaryAmount.replacingOccurrences(of: " ", with: "")) ?? 0
                                let salaryAmountValue = totalAmount * salaryPercentage / 100.0
                                Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: salaryAmountValue)) ?? "0") ₽")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        
                        Slider(value: $salaryPercentage, in: 0...100, step: 5)
                            .accentColor(AppColors.primary)
                            .onChange(of: salaryPercentage) { newValue in
                                // Синхронизируем с авансом
                                advancePercentage = 100 - newValue
                            }
                    }
                    
                    // Индикатор общей суммы
                    HStack {
                        Text("Общая сумма: \(AppUtils.numberFormatter.string(from: NSNumber(value: Double(salaryAmount.replacingOccurrences(of: " ", with: "")) ?? 0)) ?? "0") ₽")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text("100%")
                            .font(.caption)
                            .foregroundColor(AppColors.success)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(AppColors.surface)
                .cornerRadius(12)
            }
            .padding()
        }
    }
    
    // Шаг премий
    private var bonusesStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Планируемые премии")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Добавьте премии, если они у вас есть")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                ForEach(bonuses.indices, id: \.self) { index in
                    BonusCard(bonus: $bonuses[index], onDelete: {
                        bonuses.remove(at: index)
                    })
                }
                
                Button(action: {
                    bonuses.append(Bonus(id: UUID(), name: "", amount: 0, type: .oneTime, date: nil, period: nil, start: nil, end: nil))
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Добавить премию")
                    }
                    .foregroundColor(AppColors.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.surface)
                    .cornerRadius(12)
                }
            }
            .padding()
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
                
                Text("Данные о доходах заполнены!")
                    .font(.title2)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Теперь вы можете перейти к заполнению расходов для получения точной аналитики")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return !salaryAmount.isEmpty && Double(salaryAmount.replacingOccurrences(of: " ", with: "")) ?? 0 > 0
        case 1:
            return true // Премии необязательны
        case 2:
            return true
        default:
            return false
        }
    }
    
    private func saveIncome() {
        let salary = Salary(
            monthlyAmount: Double(salaryAmount.replacingOccurrences(of: " ", with: "")) ?? 0,
            advanceDate: advanceDate,
            advancePercentage: advancePercentage,
            salaryDate: salaryDate,
            salaryPercentage: salaryPercentage
        )
        
        income.salary = salary
        income.bonuses = bonuses
        
        // Создаем payouts на основе аванса и зарплаты
        var payouts: [Payout] = []
        if advancePercentage > 0 {
            payouts.append(Payout(day: advanceDate, share: advancePercentage / 100.0))
        }
        if salaryPercentage > 0 {
            payouts.append(Payout(day: salaryDate, share: salaryPercentage / 100.0))
        }
        income.payouts = payouts
        
        onSave?()
    }
}

// Карточка премии
struct BonusCard: View {
    @Binding var bonus: Bonus
    var onDelete: () -> Void
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(bonus.name.isEmpty ? "Новая премия" : bonus.name)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(AppColors.danger)
                }
            }
            
            if !showingDetails {
                Button("Заполнить детали") {
                    showingDetails = true
                }
                .foregroundColor(AppColors.primary)
            } else {
                BonusDetailsView(bonus: $bonus)
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(12)
    }
}

// Детали премии
struct BonusDetailsView: View {
    @Binding var bonus: Bonus
    @State private var name = ""
    @State private var amount = ""
    @State private var isRegular = false
    @State private var date = Date()
    @State private var period = BonusPeriod.month
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Название премии", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: name) { bonus.name = $0 }
            
            TextField("Сумма", text: $amount)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: amount) {
                    amount = AppUtils.formatInput($0)
                    bonus.amount = Double(amount.replacingOccurrences(of: " ", with: "")) ?? 0
                }
            
            Toggle("Регулярная премия", isOn: $isRegular)
                .onChange(of: isRegular) { bonus.type = isRegular ? .recurring : .oneTime }
            
            if isRegular {
                Picker("Период", selection: $period) {
                    ForEach(BonusPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: period) { bonus.period = $0 }
            } else {
                DatePicker("Дата", selection: $date, displayedComponents: .date)
                    .onChange(of: date) { bonus.date = $0 }
            }
        }
        .onAppear {
            name = bonus.name
            amount = AppUtils.numberFormatter.string(from: NSNumber(value: bonus.amount)) ?? ""
            isRegular = bonus.type == .recurring
            if let bonusDate = bonus.date {
                date = bonusDate
            }
            if let bonusPeriod = bonus.period {
                period = bonusPeriod
            }
        }
    }
}
