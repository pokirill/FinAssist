import SwiftUI

struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var goals: [Goal]
    var onSave: (() -> Void)? = nil

    @State private var name: String = ""
    @State private var targetAmount: String = ""
    @State private var currentAmount: String = ""
    @State private var description: String = ""
    @State private var targetDate: Date = Date()

    var body: some View {
        NavigationView {
            Form {
                TextField("Название цели", text: $name)
                TextField("Целевая сумма", text: $targetAmount)
                    .keyboardType(.numberPad)
                    .onChange(of: targetAmount) { newValue in
                        targetAmount = formatInput(newValue)
                    }
                TextField("Уже накоплено (необязательно)", text: $currentAmount)
                    .keyboardType(.numberPad)
                    .onChange(of: currentAmount) { newValue in
                        currentAmount = formatInput(newValue)
                    }
                DatePicker("Желаемая дата", selection: $targetDate, displayedComponents: .date)
                TextField("Описание (необязательно)", text: $description)
            }
            .navigationTitle("Новая цель")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        let goal = Goal(
                            name: name,
                            targetAmount: parseInput(targetAmount),
                            currentAmount: parseInput(currentAmount),
                            targetDate: targetDate,
                            description: description
                        )
                        goals.append(goal)
                        onSave?()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || parseInput(targetAmount) <= 0)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }

    // Форматирование с разделителями тысяч и только цифры
    func formatInput(_ input: String) -> String {
        let filtered = input.filter { "0123456789".contains($0) }
        guard let number = Int(filtered) else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: number)) ?? ""
    }

    // Преобразование строки в Double без пробелов
    func parseInput(_ input: String) -> Double {
        Double(input.replacingOccurrences(of: " ", with: "")) ?? 0
    }
}
