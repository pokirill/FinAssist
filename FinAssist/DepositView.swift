import SwiftUI

struct DepositView: View {
    @Binding var goal: Goal
    var onClose: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil
    @Environment(\.dismiss) var dismiss

    @State private var amount: String = ""
    @State private var date: Date = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Сумма накопления")) {
                    TextField("Сумма", text: $amount)
                        .keyboardType(.numberPad)
                        .onChange(of: amount) { newValue in
                            amount = formatInput(newValue)
                        }
                }
                Section(header: Text("Дата накопления")) {
                    DatePicker("Дата", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("Добавить накопление")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        addDeposit()
                        onSave?()
                        onClose?()
                        dismiss()
                    }
                    .disabled(parseInput(amount) <= 0)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        onClose?()
                        dismiss()
                    }
                }
            }
        }
    }

    func formatInput(_ input: String) -> String {
        let filtered = input.filter { "0123456789".contains($0) }
        guard let number = Int(filtered) else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: number)) ?? ""
    }

    func parseInput(_ input: String) -> Double {
        Double(input.replacingOccurrences(of: " ", with: "")) ?? 0
    }

    var isValid: Bool {
        parseInput(amount) > 0
    }

    private func addDeposit() {
        let deposit = Deposit(date: date, amount: parseInput(amount))
        goal.deposits.append(deposit)
        goal.currentAmount += deposit.amount
    }
}
