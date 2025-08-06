import SwiftUI


struct EditGoalView: View {
    @Environment(\.dismiss) var dismiss
    @State var goal: Goal
    var onSave: ((Goal) -> Void)? = nil

    @State private var name: String
    @State private var targetAmount: String
    @State private var currentAmount: String
    @State private var targetDate: Date
    @State private var description: String

    init(goal: Goal, onSave: ((Goal) -> Void)? = nil) {
        self._goal = State(initialValue: goal)
        self.onSave = onSave
        self._name = State(initialValue: goal.name)
        self._targetAmount = State(initialValue: numberFormatter.string(from: NSNumber(value: goal.targetAmount)) ?? "")
        self._currentAmount = State(initialValue: numberFormatter.string(from: NSNumber(value: goal.currentAmount)) ?? "")
        self._targetDate = State(initialValue: goal.targetDate)
        self._description = State(initialValue: goal.description)
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(targetAmount.replacingOccurrences(of: " ", with: "")) ?? 0 > 0
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Название цели").foregroundColor(Color(hex: "#2563EB"))) {
                    TextField("Название", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                Section(header: Text("Целевая сумма").foregroundColor(Color(hex: "#2563EB"))) {
                    TextField("Целевая сумма", text: $targetAmount)
                        .keyboardType(.numberPad)
                        .onChange(of: targetAmount) { newValue in
                            targetAmount = formatInput(newValue)
                        }
                }
                Section(header: Text("Уже накоплено").foregroundColor(Color(hex: "#2563EB"))) {
                    TextField("Уже накоплено", text: $currentAmount)
                        .keyboardType(.numberPad)
                        .onChange(of: currentAmount) { newValue in
                            currentAmount = formatInput(newValue)
                        }
                }
                Section(header: Text("Желаемая дата").foregroundColor(Color(hex: "#2563EB"))) {
                    DatePicker("Дата", selection: $targetDate, displayedComponents: .date)
                        .accentColor(Color(hex: "#2563EB"))
                }
                Section(header: Text("Описание").foregroundColor(Color(hex: "#2563EB"))) {
                    TextField("Описание", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .navigationTitle("Редактировать цель")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        goal.name = name
                        goal.targetAmount = Double(targetAmount.replacingOccurrences(of: " ", with: "")) ?? 0
                        goal.currentAmount = Double(currentAmount.replacingOccurrences(of: " ", with: "")) ?? 0
                        goal.targetDate = targetDate
                        goal.description = description
                        onSave?(goal)
                        dismiss()
                    }
                    .disabled(!isValid)
                    .foregroundColor(isValid ? Color(hex: "#2563EB") : .gray)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
        .accentColor(Color(hex: "#2563EB"))
    }
} 
