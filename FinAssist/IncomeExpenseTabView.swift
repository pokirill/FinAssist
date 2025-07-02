import SwiftUI

enum IncomeExpenseSetupState: Identifiable {
    case chooseMethod
    case manual
    case onboarding

    var id: Int {
        switch self {
        case .chooseMethod: return 0
        case .manual: return 1
        case .onboarding: return 2
        }
    }
}

struct IncomeExpenseTabView: View {
    @AppStorage("monthlySaving") private var monthlySaving: Double = 0
    @AppStorage("savingDay") private var savingDay: Int = 10

    @State private var setupState: IncomeExpenseSetupState = .chooseMethod
    @State private var manualAmount: String = ""
    @State private var manualDay: Int = 10
    @State private var lastIncomeItems: [IncomeItem] = []
    @State private var lastExpenseItems: [ExpenseItem] = []

    var totalIncome: Double {
        lastIncomeItems.compactMap { Double($0.amount.replacingOccurrences(of: " ", with: "")) }.reduce(0, +)
    }
    var totalExpense: Double {
        lastExpenseItems.compactMap { Double($0.amount.replacingOccurrences(of: " ", with: "")) }.reduce(0, +)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if monthlySaving > 0 {
                                    Text("Ваша сумма накоплений: \(numberFormatter.string(from: NSNumber(value: monthlySaving)) ?? "0") ₽")
                                        .font(.title2)
                                        .foregroundColor(Color(hex: "#2563EB"))
                                        .padding(.top)
                                }
                if setupState == .chooseMethod {
                    Text("Как вы хотите задать сумму накоплений?")
                        .font(.title2).bold()
                        .padding(.top, 32)
                    VStack(spacing: 16) {
                        Button(action: {
                            manualAmount = monthlySaving > 0 ? numberFormatter.string(from: NSNumber(value: monthlySaving)) ?? "" : ""
                            manualDay = savingDay
                            setupState = .manual
                        }) {
                            Text("Я знаю, сколько могу откладывать")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#2563EB"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        Button(action: {
                            setupState = .onboarding
                        }) {
                            Text("Я не знаю — рассчитать автоматически")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#8B5CF6"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    if !lastExpenseItems.isEmpty && totalIncome > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Аналитика расходов")
                                .font(.headline)
                            ForEach(lastExpenseItems.filter { (Double($0.amount.replacingOccurrences(of: " ", with: "")) ?? 0) > 0 }) { expense in
                                let amount = Double(expense.amount.replacingOccurrences(of: " ", with: "")) ?? 0
                                let percent = amount / totalIncome
                                HStack {
                                    Text(expense.category)
                                    Spacer()
                                    Text("\(expense.amount) ₽")
                                    ProgressView(value: percent)
                                        .frame(width: 80)
                                }
                            }
                            Divider()
                            HStack {
                                Text("Всего расходов")
                                Spacer()
                                Text("\(numberFormatter.string(from: NSNumber(value: totalExpense)) ?? "0") ₽")
                            }
                            HStack {
                                Text("Остаток на накопления")
                                Spacer()
                                Text("\(numberFormatter.string(from: NSNumber(value: monthlySaving)) ?? "0") ₽")
                                    .foregroundColor(Color(hex: "#2563EB"))
                            }
                        }
                        .padding(.horizontal)
                    }
                } else if setupState == .manual {
                    VStack(spacing: 16) {
                        Text("Укажите сумму, которую вы готовы откладывать каждый месяц")
                            .font(.headline)
                        TextField("Сумма", text: Binding(
                            get: { manualAmount },
                            set: { newValue in
                                manualAmount = formatInput(newValue)
                            }
                        ))
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        HStack {
                            Text("День накопления:")
                            Picker("", selection: $manualDay) {
                                ForEach(1...28, id: \.self) { d in
                                    Text("\(d)")
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        Button("Сохранить") {
                            monthlySaving = Double(manualAmount.replacingOccurrences(of: " ", with: "")) ?? 0
                            savingDay = manualDay
                            setupState = .chooseMethod
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#2563EB"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        Button("Пересчитать через онбординг") {
                            setupState = .onboarding
                        }
                        .foregroundColor(Color(hex: "#8B5CF6"))
                        .padding(.top, 8)
                    }
                    .padding()
                } else if setupState == .onboarding {
                    OnboardingIncomeExpenseView { saving, day, incomes, expenses in
                        monthlySaving = saving
                        savingDay = day
                        lastIncomeItems = incomes
                        lastExpenseItems = expenses
                        setupState = .chooseMethod
                    }
                } else {
                    EmptyView()
                }
                Spacer()
            }
            .navigationTitle("Доходы и расходы")
        }
        .accentColor(Color(hex: "#2563EB"))
    }
}
