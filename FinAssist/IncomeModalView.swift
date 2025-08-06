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
            VStack(spacing: 0) {
                // Прогресс бар
                HStack {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Rectangle()
                            .fill(index <= currentStep ? AppColors.primary : AppColors.primary.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Контент
                TabView(selection: $currentStep) {
                    salaryStep.tag(0)
                    bonusesStep.tag(1)
                    completionStep.tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Навигация
                HStack {
                    if currentStep > 0 {
                        Button("Назад") {
                            currentStep -= 1
                        }
                        .foregroundColor(AppColors.primary)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == steps.count - 1 ? "Завершить" : "Далее") {
                        if currentStep == steps.count - 1 {
                            saveIncome()
                            dismiss()
                        } else {
                            currentStep += 1
                        }
                    }
                    .foregroundColor(AppColors.primary)
                }
                .padding()
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
    
    private var salaryStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                TextField("Ежемесячный оклад", text: $salaryAmount)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: salaryAmount) { newValue in
                        salaryAmount = formatInput(newValue)
                    }
                
                Text("Дата аванса: \(advanceDate)")
                Slider(value: Binding(get: { Double(advanceDate) }, set: { advanceDate = Int($0) }), in: 1...28, step: 1)
                
                Text("Доля аванса: \(Int(advancePercentage))%")
                Slider(value: $advancePercentage, in: 0...100, step: 5)
                
                Text("Дата зарплаты: \(salaryDate)")
                Slider(value: Binding(get: { Double(salaryDate) }, set: { salaryDate = Int($0) }), in: 1...28, step: 1)
                
                Text("Доля зарплаты: \(Int(salaryPercentage))%")
                Slider(value: $salaryPercentage, in: 0...100, step: 5)
            }
            .padding()
        }
    }
    
    private var bonusesStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Премии (необязательно)")
                    .font(.headline)
                
                Button("Добавить премию") {
                    bonuses.append(Bonus(name: "Премия", amount: 0, isRegular: false))
                }
                .foregroundColor(AppColors.primary)
            }
            .padding()
        }
    }
    
    private var completionStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.success)
            Text("Данные о доходах заполнены!")
                .font(.title2)
            Spacer()
        }
    }
    
    private func loadExistingData() {
        if let salary = income.salary {
            salaryAmount = numberFormatter.string(from: NSNumber(value: salary.monthlyAmount)) ?? ""
            advanceDate = salary.advanceDate
            advancePercentage = salary.advancePercentage
            salaryDate = salary.salaryDate
            salaryPercentage = salary.salaryPercentage
        }
        bonuses = income.bonuses
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
        
        onSave?()
    }
}
