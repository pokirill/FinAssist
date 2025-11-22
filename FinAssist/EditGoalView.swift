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
    @State private var priority: GoalPriority

    init(goal: Goal, onSave: ((Goal) -> Void)? = nil) {
        self._goal = State(initialValue: goal)
        self.onSave = onSave
        self._name = State(initialValue: goal.name)
        self._targetAmount = State(initialValue: AppUtils.numberFormatter.string(from: NSNumber(value: goal.targetAmount)) ?? "")
        self._currentAmount = State(initialValue: AppUtils.numberFormatter.string(from: NSNumber(value: goal.currentAmount)) ?? "")
        self._targetDate = State(initialValue: goal.targetDate)
        self._description = State(initialValue: goal.description)
        self._priority = State(initialValue: goal.priority)
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(targetAmount.replacingOccurrences(of: " ", with: "")) ?? 0 > 0
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Название цели")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Название", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Целевая сумма")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Сумма", text: $targetAmount)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: targetAmount) { newValue in
                                    targetAmount = AppUtils.formatInput(newValue)
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Текущая сумма")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Сумма", text: $currentAmount)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: currentAmount) { newValue in
                                    currentAmount = AppUtils.formatInput(newValue)
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Желаемая дата")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            DatePicker("Дата", selection: $targetDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Приоритет")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Picker("Приоритет", selection: $priority) {
                                ForEach(GoalPriority.allCases, id: \.self) { priority in
                                    Text(priority.displayName).tag(priority)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Описание (необязательно)")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Описание", text: $description, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Редактировать цель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveGoal()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveGoal() {
        // Обновляем существующую цель, сохраняя id и другие данные
        var updatedGoal = goal
        updatedGoal.name = name.trimmingCharacters(in: .whitespaces)
        updatedGoal.targetAmount = Double(targetAmount.replacingOccurrences(of: " ", with: "")) ?? 0
        updatedGoal.currentAmount = Double(currentAmount.replacingOccurrences(of: " ", with: "")) ?? 0
        updatedGoal.targetDate = targetDate
        updatedGoal.description = description.trimmingCharacters(in: .whitespaces)
        updatedGoal.priority = priority
        // deposits и forecastDate уже сохранены в goal
        
        onSave?(updatedGoal)
    }
} 
