import SwiftUI

struct StepByStepOnboarding: View {
    @State private var currentStep = 0
    @State private var income: Income = Income()
    @State private var expense: Expense = Expense()
    @State private var goalName: String = ""
    @State private var goalAmount: String = ""
    @State private var goalDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    
    let generator = UINotificationFeedbackGenerator()
    var onComplete: ((Income, Expense, Goal?) -> Void)?
    
    private let totalSteps = 3
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Индикатор прогресса
                progressIndicator
                
                // Основной контент
                TabView(selection: $currentStep) {
                    // Шаг 1: Доходы
                    incomeStep
                        .tag(0)
                    
                    // Шаг 2: Расходы
                    expenseStep
                        .tag(1)
                    
                    // Шаг 3: Первая цель
                    goalStep
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Кнопки навигации
                navigationButtons
            }
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? AppColors.primary : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal)
            
            Text("Шаг \(currentStep + 1) из \(totalSteps)")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
    
    // MARK: - Income Step
    
    private var incomeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("💰 Доходы")
                        .font(.largeTitle).bold()
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Нужно, чтобы понять, сколько ты реально можешь откладывать")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.bottom, 8)
                
                // Поле зарплаты
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ежемесячная зарплата")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    TextField("Например: 150 000", text: Binding(
                        get: {
                            if let salary = income.salary, salary.monthlyAmount > 0 {
                                return AppUtils.numberFormatter.string(from: NSNumber(value: salary.monthlyAmount)) ?? ""
                            }
                            return ""
                        },
                        set: { newValue in
                            let amount = Double(newValue.replacingOccurrences(of: " ", with: "")) ?? 0
                            if income.salary == nil {
                                income.salary = Salary(monthlyAmount: amount, advanceDate: 10, advancePercentage: 40, salaryDate: 25, salaryPercentage: 60)
                            } else {
                                income.salary?.monthlyAmount = amount
                            }
                        }
                    ))
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: income.salary?.monthlyAmount ?? 0) { _ in
                        if var salary = income.salary {
                            let formatted = AppUtils.formatInput(String(Int(salary.monthlyAmount)))
                            salary.monthlyAmount = Double(formatted.replacingOccurrences(of: " ", with: "")) ?? 0
                            income.salary = salary
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Expense Step
    
    private var expenseStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("📊 Расходы")
                        .font(.largeTitle).bold()
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Поможет оценить, сколько уходит на обязательные траты")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.bottom, 8)
                
                Text("Укажи примерные ежемесячные расходы")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                // Основные категории расходов
                expenseField(title: "Жильё (аренда/ипотека)", binding: $expense.rent)
                expenseField(title: "Продукты", binding: $expense.groceries)
                expenseField(title: "Транспорт", binding: $expense.transport)
                expenseField(title: "Коммуналка", binding: $expense.utilities)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func expenseField(title: String, binding: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            TextField("0", text: Binding(
                get: {
                    binding.wrappedValue > 0 ? AppUtils.numberFormatter.string(from: NSNumber(value: binding.wrappedValue)) ?? "" : ""
                },
                set: { newValue in
                    binding.wrappedValue = Double(newValue.replacingOccurrences(of: " ", with: "")) ?? 0
                }
            ))
            .keyboardType(.numberPad)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onChange(of: binding.wrappedValue) { newValue in
                let formatted = AppUtils.formatInput(String(Int(newValue)))
                binding.wrappedValue = Double(formatted.replacingOccurrences(of: " ", with: "")) ?? 0
            }
        }
    }
    
    // MARK: - Goal Step
    
    private var goalStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🎯 Первая цель")
                        .font(.largeTitle).bold()
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Покажем реальные сроки и приоритеты")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Название цели")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    TextField("Например: Отпуск на море", text: $goalName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Сумма")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    TextField("Сумма", text: $goalAmount)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: goalAmount) { newValue in
                            goalAmount = AppUtils.formatInput(newValue)
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Желаемая дата")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    DatePicker("Дата", selection: $goalDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                }
                
                Text("💡 Можешь пропустить этот шаг и добавить цели позже")
                    .font(.caption)
                    .foregroundColor(AppColors.accent)
                    .padding(.top, 8)
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button(action: {
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    Text("Назад")
                        .font(.headline)
                        .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.surface)
                        .cornerRadius(12)
                }
            }
            
            Button(action: {
                // Haptic feedback
                generator.notificationOccurred(.success)
                
                if currentStep < totalSteps - 1 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    // Завершение онбординга
                    completeOnboarding()
                }
            }) {
                Text(currentStep < totalSteps - 1 ? "Далее" : "Посчитать план")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(canProceed ? AppColors.primary : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!canProceed)
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return (income.salary?.monthlyAmount ?? 0) > 0
        case 1:
            return expense.totalMonthlyExpense > 0
        case 2:
            return true // Последний шаг можно пропустить
        default:
            return false
        }
    }
    
    private func completeOnboarding() {
        // Haptic feedback при завершении
        let successGenerator = UINotificationFeedbackGenerator()
        successGenerator.notificationOccurred(.success)
        
        // Создаем цель, если указана
        var goal: Goal? = nil
        if !goalName.isEmpty, let amount = Double(goalAmount.replacingOccurrences(of: " ", with: "")), amount > 0 {
            goal = Goal(
                name: goalName,
                targetAmount: amount,
                currentAmount: 0,
                targetDate: goalDate,
                description: "",
                priority: .important,
                type: .regular
            )
        }
        
        onComplete?(income, expense, goal)
    }
}

