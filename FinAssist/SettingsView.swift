import SwiftUI

struct SettingsView: View {
    @AppStorage("emergencyFundEnabled") private var emergencyFundEnabled: Bool = true
    @AppStorage("emergencyFundMonths") private var emergencyFundMonths: Int = 3
    @AppStorage("emergencyFundSkipPeriod") private var emergencyFundSkipPeriod: Bool = false
    
    @Environment(\.dismiss) var dismiss
    
    let monthsOptions = [3, 6, 9, 12]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                List {
                    Section {
                        Toggle("Откладывать на подушку", isOn: $emergencyFundEnabled)
                            .tint(AppColors.primary)
                        
                        if emergencyFundEnabled {
                            Picker("На сколько месяцев копим подушку", selection: $emergencyFundMonths) {
                                ForEach(monthsOptions, id: \.self) { months in
                                    Text("\(months) мес.").tag(months)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Toggle("В этот период не откладывать в подушку", isOn: $emergencyFundSkipPeriod)
                                .tint(AppColors.warning)
                        }
                    } header: {
                        Text("Подушка безопасности")
                    } footer: {
                        if emergencyFundEnabled {
                            Text("Подушка создается автоматически как критичная цель. Целевая сумма = средний месячный доход × \(emergencyFundMonths) мес.")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        } else {
                            Text("При выключении подушки накопленная сумма станет свободной и распределится по другим целям")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

