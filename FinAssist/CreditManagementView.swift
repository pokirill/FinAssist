import SwiftUI

struct CreditManagementView: View {
    @Binding var credits: [Credit]
    @Environment(\.dismiss) var dismiss
    @State private var showingAddCredit = false
    @State private var editingCredit: Credit? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Описание
                VStack(alignment: .leading, spacing: 8) {
                    Text("💳 Кредиты и займы")
                        .font(.title2).bold()
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Укажите ваши кредиты. Если у кредита есть дата окончания, прогноз станет точнее.")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(AppColors.surface)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 8)
                
                // Список кредитов или пустое состояние
                if credits.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "creditcard.circle")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.textSecondary.opacity(0.5))
                        
                        Text("Нет добавленных кредитов")
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("Нажмите \"+\" чтобы добавить кредит или займ")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(credits) { credit in
                            creditCard(credit)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingCredit = credit
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            credits.removeAll { $0.id == credit.id }
                                        }
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        editingCredit = credit
                                    } label: {
                                        Label("Изменить", systemImage: "pencil")
                                    }
                                    .tint(AppColors.primary)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Кредиты")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddCredit = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddCredit) {
                AddCreditView(credits: $credits)
            }
            .sheet(item: $editingCredit) { credit in
                EditCreditView(credits: $credits, credit: credit)
            }
            .onChange(of: credits) { _ in
                updateTotalExpense()
            }
        }
    }
    
    private func updateTotalExpense() {
        // Обновляем totalMonthlyExpense с учетом кредитов
        let expenseData = UserDefaults.standard.data(forKey: "user_expense")
        if let expenseData = expenseData,
           let expense = try? JSONDecoder().decode(Expense.self, from: expenseData) {
            
            let totalCreditPayments = credits.reduce(0.0) { sum, credit in
                if credit.endDate == nil || credit.endDate! > Date() {
                    return sum + credit.monthlyAmount
                }
                return sum
            }
            let totalExpenseWithCredits = expense.totalMonthlyExpense + totalCreditPayments
            UserDefaults.standard.set(totalExpenseWithCredits, forKey: "totalMonthlyExpense")
        }
    }
    
    @ViewBuilder
    private func creditCard(_ credit: Credit) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(credit.name)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: credit.monthlyAmount)) ?? "0") ₽/мес")
                        .font(.title3).bold()
                        .foregroundColor(AppColors.danger)
                }
                
                Spacer()
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("День списания:")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text("\(credit.day) число")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                if let endDate = credit.endDate {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Окончание:")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(AppUtils.dateFormatter.string(from: endDate))
                            .font(.subheadline)
                            .foregroundColor(AppColors.success)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Окончание:")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text("Бессрочный")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(12)
    }
}

struct AddCreditView: View {
    @Binding var credits: [Credit]
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var monthlyAmountText: String = ""
    @State private var day: Int = 15
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Описание
                        VStack(alignment: .leading, spacing: 8) {
                            Text("💡 Добавление кредита и его сроков поможет увеличить точность расчетов в плане")
                                .font(.subheadline)
                                .foregroundColor(AppColors.accent)
                                .padding()
                                .background(AppColors.accent.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        // Название
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Название")
                                .font(.subheadline).bold()
                                .foregroundColor(AppColors.textSecondary)
                            
                            TextField("Например: Ипотека, Автокредит", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(AppColors.surface)
                                .cornerRadius(8)
                        }
                        
                        // Ежемесячный платеж
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ежемесячный платеж")
                                .font(.subheadline).bold()
                                .foregroundColor(AppColors.textSecondary)
                            
                            HStack {
                                TextField("0", text: $monthlyAmountText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .background(AppColors.surface)
                                    .cornerRadius(8)
                                    .onChange(of: monthlyAmountText) { newValue in
                                        monthlyAmountText = AppUtils.formatInput(newValue)
                                    }
                                
                                Text("₽")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        
                        // День списания
                        VStack(alignment: .leading, spacing: 8) {
                            Text("День списания")
                                .font(.subheadline).bold()
                                .foregroundColor(AppColors.textSecondary)
                            
                            Picker("День", selection: $day) {
                                ForEach(1...28, id: \.self) { d in
                                    Text("\(d)").tag(d)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(height: 120)
                            .background(AppColors.surface)
                            .cornerRadius(8)
                        }
                        
                        // Дата окончания
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $hasEndDate) {
                                Text("Указать дату окончания")
                                    .font(.subheadline).bold()
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            if hasEndDate {
                                DatePicker("Дата окончания", selection: $endDate, displayedComponents: .date)
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .background(AppColors.surface)
                                    .cornerRadius(8)
                                
                                Text("💡 Если указать дату окончания кредита, прогноз станет точнее")
                                    .font(.caption)
                                    .foregroundColor(AppColors.accent)
                                    .padding(.top, 4)
                            }
                        }
                        
                        Spacer()
                        
                        // Кнопка добавления
                        Button(action: addCredit) {
                            Text("Добавить кредит")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isValid ? AppColors.primary : AppColors.textSecondary.opacity(0.3))
                                .cornerRadius(12)
                        }
                        .disabled(!isValid)
                    }
                    .padding()
                }
            }
            .navigationTitle("Новый кредит")
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
    
    private var isValid: Bool {
        !name.isEmpty && Double(monthlyAmountText.replacingOccurrences(of: " ", with: "")) ?? 0 > 0
    }
    
    private func addCredit() {
        guard isValid, let amount = Double(monthlyAmountText.replacingOccurrences(of: " ", with: "")) else { return }
        
        let newCredit = Credit(
            name: name,
            monthlyAmount: amount,
            day: day,
            endDate: hasEndDate ? endDate : nil
        )
        
        credits.append(newCredit)
        dismiss()
    }
}

