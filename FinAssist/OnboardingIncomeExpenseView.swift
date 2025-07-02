import SwiftUI

struct OnboardingIncomeExpenseView: View {
    var onFinish: (Double, Int, [IncomeItem], [ExpenseItem]) -> Void

    @State private var step: Int = 1

    let incomeCategories = ["Зарплата", "Пассивный доход", "Подработка", "Другое"]
    let expenseCategories = ["Жильё", "Еда", "Транспорт/Топливо", "Связь", "Подписки", "Развлечения/хобби", "Здоровье/Бьюти", "Кредиты", "Другое"]
    let periods = ["Месяц", "Неделя", "Год"]
    let weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    @State private var incomes: [String: IncomeItem] = [:]
    @State private var expenses: [String: ExpenseItem] = [:]
    @State private var customIncomeName: String = ""
    @State private var customExpenseName: String = ""
    @State private var savingDay: Int = 10

    var canContinue: Bool {
        if step == 1 {
            return incomes.values.contains { !($0.amount.isEmpty) && (Double($0.amount.replacingOccurrences(of: " ", with: "")) ?? 0) > 0 }
        } else {
            return expenses.values.contains { !($0.amount.isEmpty) && (Double($0.amount.replacingOccurrences(of: " ", with: "")) ?? 0) > 0 }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ProgressView(value: Double(step), total: 3)
                    .accentColor(Color(hex: "#2563EB"))
                    .padding(.top, 16)
                    .padding(.horizontal)

                if step == 1 {
                    Text("Укажите ваши доходы")
                        .font(.title2).bold()
                        .padding(.top, 16)
                    Text("Период и дата нужны для точного прогноза накоплений.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(incomeCategories, id: \.self) { cat in
                                HStack {
                                    if cat == "Другое" {
                                        TextField("Другое", text: $customIncomeName)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .frame(width: 120)
                                    } else {
                                        Text(cat)
                                            .frame(width: 120, alignment: .leading)
                                    }
                                    TextField("Сумма", text: Binding(
                                        get: { incomes[cat]?.amount ?? "" },
                                        set: { newValue in
                                            let formatted = formatInput(newValue)
                                            if incomes[cat] == nil {
                                                incomes[cat] = IncomeItem(name: cat, amount: formatted, period: "Месяц")
                                            } else {
                                                incomes[cat]?.amount = formatted
                                            }
                                        }
                                    ))
                                    .keyboardType(.numberPad)
                                    .frame(width: 100)
                                    Picker("", selection: Binding(
                                        get: { incomes[cat]?.period ?? "Месяц" },
                                        set: { newValue in
                                            if incomes[cat] == nil {
                                                incomes[cat] = IncomeItem(name: cat, amount: "", period: newValue)
                                            } else {
                                                incomes[cat]?.period = newValue
                                            }
                                        }
                                    )) {
                                        ForEach(periods, id: \.self) { p in
                                            Text(p)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    // Выбор дня
                                    if incomes[cat]?.period == "Месяц" {
                                        Picker("День", selection: Binding(
                                            get: { incomes[cat]?.dayOfMonth ?? 1 },
                                            set: { newValue in
                                                if incomes[cat] == nil {
                                                    incomes[cat] = IncomeItem(name: cat, amount: "", period: "Месяц", dayOfMonth: newValue)
                                                } else {
                                                    incomes[cat]?.dayOfMonth = newValue
                                                }
                                            }
                                        )) {
                                            ForEach(1...28, id: \.self) { d in Text("\(d)") }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .frame(width: 70)
                                    } else if incomes[cat]?.period == "Неделя" {
                                        Picker("День", selection: Binding(
                                            get: { incomes[cat]?.weekday ?? "Пн" },
                                            set: { newValue in
                                                if incomes[cat] == nil {
                                                    incomes[cat] = IncomeItem(name: cat, amount: "", period: "Неделя", weekday: newValue)
                                                } else {
                                                    incomes[cat]?.weekday = newValue
                                                }
                                            }
                                        )) {
                                            ForEach(weekdays, id: \.self) { w in Text(w) }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .frame(width: 70)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                } else if step == 2 {
                    Text("Укажите ваши расходы")
                        .font(.title2).bold()
                        .padding(.top, 16)
                    Text("Период и дата нужны для точного прогноза накоплений.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(expenseCategories, id: \.self) { cat in
                                HStack {
                                    if cat == "Другое" {
                                        TextField("Другое", text: $customExpenseName)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .frame(width: 120)
                                    } else {
                                        Text(cat)
                                            .frame(width: 120, alignment: .leading)
                                    }
                                    TextField("Сумма", text: Binding(
                                        get: { expenses[cat]?.amount ?? "" },
                                        set: { newValue in
                                            let formatted = formatInput(newValue)
                                            if expenses[cat] == nil {
                                                expenses[cat] = ExpenseItem(category: cat, amount: formatted, period: "Месяц")
                                            } else {
                                                expenses[cat]?.amount = formatted
                                            }
                                        }
                                    ))
                                    .keyboardType(.numberPad)
                                    .frame(width: 100)
                                    Picker("", selection: Binding(
                                        get: { expenses[cat]?.period ?? "Месяц" },
                                        set: { newValue in
                                            if expenses[cat] == nil {
                                                expenses[cat] = ExpenseItem(category: cat, amount: "", period: newValue)
                                            } else {
                                                expenses[cat]?.period = newValue
                                            }
                                        }
                                    )) {
                                        ForEach(periods, id: \.self) { p in
                                            Text(p)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    // Выбор дня
                                    if expenses[cat]?.period == "Месяц" {
                                        Picker("День", selection: Binding(
                                            get: { expenses[cat]?.dayOfMonth ?? 1 },
                                            set: { newValue in
                                                if expenses[cat] == nil {
                                                    expenses[cat] = ExpenseItem(category: cat, amount: "", period: "Месяц", dayOfMonth: newValue)
                                                } else {
                                                    expenses[cat]?.dayOfMonth = newValue
                                                }
                                            }
                                        )) {
                                            ForEach(1...28, id: \.self) { d in Text("\(d)") }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .frame(width: 70)
                                    } else if expenses[cat]?.period == "Неделя" {
                                        Picker("День", selection: Binding(
                                            get: { expenses[cat]?.weekday ?? "Пн" },
                                            set: { newValue in
                                                if expenses[cat] == nil {
                                                    expenses[cat] = ExpenseItem(category: cat, amount: "", period: "Неделя", weekday: newValue)
                                                } else {
                                                    expenses[cat]?.weekday = newValue
                                                }
                                            }
                                        )) {
                                            ForEach(weekdays, id: \.self) { w in Text(w) }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .frame(width: 70)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Финальный шаг — расчет
                    let totalIncome = incomes.values.compactMap { Double($0.amount.replacingOccurrences(of: " ", with: "")) }.reduce(0, +)
                    let totalExpense = expenses.values.compactMap { Double($0.amount.replacingOccurrences(of: " ", with: "")) }.reduce(0, +)
                    let saving = max(totalIncome - totalExpense, 0)
                    VStack(spacing: 16) {
                        Text("Рассчитано!")
                            .font(.title2).bold()
                        Text("Вы можете откладывать примерно")
                        Text("\(numberFormatter.string(from: NSNumber(value: saving)) ?? "0") ₽ в месяц")
                            .font(.title)
                            .foregroundColor(Color(hex: "#2563EB"))
                        HStack {
                            Text("День накопления:")
                            Picker("", selection: $savingDay) {
                                ForEach(1...28, id: \.self) { d in
                                    Text("\(d)")
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .padding(.top, 8)
                        Button("Сохранить и продолжить") {
                            onFinish(saving, savingDay, Array(incomes.values), Array(expenses.values))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#2563EB"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.top, 16)
                    }
                    .padding()
                }

                Spacer()

                HStack(spacing: 16) {
                    if step > 1 && step < 3 {
                        Button("Назад") { step -= 1 }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#E0E7EF"))
                            .foregroundColor(Color(hex: "#2563EB"))
                            .cornerRadius(12)
                    }
                    if step < 3 {
                        Button(step == 2 ? "Рассчитать" : "Далее") {
                            step += 1
                        }
                        .disabled(!canContinue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canContinue ? Color(hex: "#2563EB") : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("Доходы и расходы")
        }
        .accentColor(Color(hex: "#2563EB"))
    }
}
