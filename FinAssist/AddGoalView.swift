import SwiftUI


struct AddGoalView: View {
    @Binding var goals: [Goal]
    var onSave: (() -> Void)? = nil
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var targetAmount: String = ""
    @State private var currentAmount: String = ""
    @State private var description: String = ""
    @State private var targetDate: Date = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Название цели")) {
                    TextField("Название", text: $name)
                }
                Section(header: Text("Целевая сумма")) {
                    TextField("Целевая сумма", text: $targetAmount)
                        .keyboardType(.decimalPad)
                }
                Section(header: Text("Уже накоплено")) {
                    TextField("Уже накоплено", text: $currentAmount)
                        .keyboardType(.decimalPad)
                }
                Section(header: Text("Желаемая дата")) {
                    DatePicker("Дата", selection: $targetDate, displayedComponents: .date)
                }
                Section(header: Text("Описание")) {
                    TextField("Описание", text: $description)
                }
            }
            .navigationTitle("Добавить цель")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        addGoal()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(targetAmount.replacingOccurrences(of: " ", with: "")) ?? 0 > 0
    }

    private func addGoal() {
        let newGoal = Goal(
            name: name,
            targetAmount: Double(targetAmount.replacingOccurrences(of: " ", with: "")) ?? 0,
            currentAmount: Double(currentAmount.replacingOccurrences(of: " ", with: "")) ?? 0,
            targetDate: targetDate,
            description: description
        )
        goals.append(newGoal)
        onSave?()
    }
} 
