import SwiftUI

struct DepositView: View {
    @Binding var goal: Goal
    var onClose: () -> Void
    var onSave: () -> Void
    
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Информация о цели
                        VStack(alignment: .leading, spacing: 12) {
                            Text(goal.name)
                                .font(.title2).bold()
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Цель: \(AppUtils.numberFormatter.string(from: NSNumber(value: goal.targetAmount)) ?? "0") ₽")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text("Накоплено: \(AppUtils.numberFormatter.string(from: NSNumber(value: goal.currentAmount)) ?? "0") ₽")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            
                            if goal.currentAmount < goal.targetAmount {
                                Text("Осталось до цели: \(AppUtils.numberFormatter.string(from: NSNumber(value: max(goal.targetAmount - goal.currentAmount, 0))) ?? "0") ₽")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                        .padding()
                        .background(AppColors.surface)
                        .cornerRadius(12)
                        
                        // Форма добавления накопления
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Сумма накопления")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                TextField("Сумма", text: $amount)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: amount) { newValue in
                                        amount = AppUtils.formatInput(newValue)
                                    }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Дата")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                DatePicker("Дата", selection: $date, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Заметка (необязательно)")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                TextField("Заметка", text: $note, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .lineLimit(2...4)
                            }
                        }
                        .padding()
                        .background(AppColors.surface)
                        .cornerRadius(12)
                        
                        // Кнопка добавления
                        Button(action: addDeposit) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Добавить накопление")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppColors.primary)
                            .cornerRadius(12)
                        }
                        .disabled(amount.isEmpty || Double(amount.replacingOccurrences(of: " ", with: "")) ?? 0 <= 0)
                        
                        // Список предыдущих накоплений
                        if !goal.deposits.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Предыдущие накопления")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                ForEach(goal.deposits.sorted(by: { $0.date > $1.date })) { deposit in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("+\(AppUtils.numberFormatter.string(from: NSNumber(value: deposit.amount)) ?? "0") ₽")
                                                .font(.subheadline).bold()
                                                .foregroundColor(AppColors.success)
                                            
                                            if !deposit.note.isEmpty {
                                                Text(deposit.note)
                                                    .font(.caption)
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Text(AppUtils.dateFormatter.string(from: deposit.date))
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    .padding()
                                    .background(AppColors.background)
                                    .cornerRadius(8)
                                }
                            }
                            .padding()
                            .background(AppColors.surface)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Добавить накопление")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") {
                        onClose()
                    }
                }
            }
        }
    }
    
    private func addDeposit() {
        guard let depositAmount = Double(amount.replacingOccurrences(of: " ", with: "")) else { return }
        
        let deposit = Deposit(
            date: date,
            amount: depositAmount,
            note: note.trimmingCharacters(in: .whitespaces)
        )
        
        goal.deposits.append(deposit)
        goal.currentAmount += depositAmount
        
        onSave()
        
        // Очищаем форму
        amount = ""
        note = ""
        date = Date()
    }
} 
