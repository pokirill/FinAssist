import SwiftUI

struct EditCreditView: View {
    @Binding var credits: [Credit]
    let credit: Credit
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
                            }
                        }
                        
                        Spacer()
                        
                        // Кнопка сохранения
                        Button(action: saveCredit) {
                            Text("Сохранить")
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
            .navigationTitle("Изменить кредит")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = credit.name
                monthlyAmountText = AppUtils.numberFormatter.string(from: NSNumber(value: credit.monthlyAmount)) ?? ""
                day = credit.day
                hasEndDate = credit.endDate != nil
                if let endDate = credit.endDate {
                    self.endDate = endDate
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && Double(monthlyAmountText.replacingOccurrences(of: " ", with: "")) ?? 0 > 0
    }
    
    private func saveCredit() {
        guard isValid, let amount = Double(monthlyAmountText.replacingOccurrences(of: " ", with: "")) else { return }
        
        if let index = credits.firstIndex(where: { $0.id == credit.id }) {
            credits[index].name = name
            credits[index].monthlyAmount = amount
            credits[index].day = day
            credits[index].endDate = hasEndDate ? endDate : nil
        }
        
        dismiss()
    }
}

