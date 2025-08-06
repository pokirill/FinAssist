import SwiftUI

struct DepositView: View {
    @Binding var goal: Goal
    var onClose: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil
    @Environment(\.dismiss) var dismiss
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var note: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Сумма пополнения")) {
                    TextField("Сумма", text: $amount)
                        .keyboardType(.numberPad)
                        .onChange(of: amount) { newValue in
                            amount = formatInput(newValue)
                        }
                    Text("Осталось до цели: \(numberFormatter.string(from: NSNumber(value: max(goal.targetAmount - goal.currentAmount, 0))) ?? "0") ₽")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Section(header: Text("Дата")) {
                    DatePicker("Дата пополнения", selection: $date, displayedComponents: .date)
                }
                Section(header: Text("Комментарий (необязательно)")) {
                    TextField("Комментарий", text: $note)
                }
                if !goal.deposits.isEmpty {
                    Section(header: Text("История пополнений")) {
                        ForEach(goal.deposits.sorted { $0.date > $1.date }) { deposit in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("+\(numberFormatter.string(from: NSNumber(value: deposit.amount)) ?? "0") ₽")
                                    .bold()
                                Text(dateFormatter.string(from: deposit.date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if !deposit.note.isEmpty {
                                    Text(deposit.note)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .onDelete { indices in
                            goal.deposits.remove(atOffsets: indices)
                        }
                    }
                }
            }
            .navigationTitle("Пополнение цели")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        let depositAmount = Double(amount.replacingOccurrences(of: " ", with: "")) ?? 0
                        guard depositAmount > 0 else { return }
                        let deposit = Deposit(date: date, amount: depositAmount, note: note)
                        goal.deposits.append(deposit)
                        goal.currentAmount += depositAmount
                        amount = ""
                        note = ""
                        onSave?()
                        dismiss()
                    }
                    .disabled(amount.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        onClose?()
                        dismiss()
                    }
                }
            }
        }
    }
}
