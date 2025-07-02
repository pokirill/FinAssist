import SwiftUI

struct IncomeExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var income: Double
    @Binding var expense: Double
    @Binding var savingDay: Int

    @State private var incomeText: String = ""
    @State private var expenseText: String = ""

    var maxDayInMonth: Int {
        let calendar = Calendar.current
        let date = Date()
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }

    var body: some View {
        NavigationView {
            Form {
                Picker("День накопления", selection: $savingDay) {
                    ForEach(1...maxDayInMonth, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                TextField("Месячный доход", text: $incomeText)
                    .keyboardType(.numberPad)
                    .onChange(of: incomeText) { newValue in
                        incomeText = formatInput(newValue)
                    }
                TextField("Месячные расходы", text: $expenseText)
                    .keyboardType(.numberPad)
                    .onChange(of: expenseText) { newValue in
                        expenseText = formatInput(newValue)
                    }
            }
            .navigationTitle("Доходы и расходы")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        income = Double(incomeText.replacingOccurrences(of: " ", with: "")) ?? 0
                        expense = Double(expenseText.replacingOccurrences(of: " ", with: "")) ?? 0
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                incomeText = income == 0 ? "" : numberFormatter.string(from: NSNumber(value: income)) ?? ""
                expenseText = expense == 0 ? "" : numberFormatter.string(from: NSNumber(value: expense)) ?? ""
            }
        }
    }
}
