import SwiftUI

struct AddGoalView: View {
    @Binding var goals: [Goal]
    var onSave: (() -> Void)? = nil
    @Environment(\.dismiss) var dismiss
    @State private var goalType: GoalType = .regular
    @State private var name: String = ""
    @State private var targetAmount: String = ""
    @State private var currentAmount: String = ""
    @State private var description: String = ""
    @State private var targetDate: Date = Date()
    @State private var priority: GoalPriority = .important
    @State private var showWishlistAlert = false
    
    @AppStorage("wishlistItems") private var wishlistItemsData: Data = Data()

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
                        // Выбор типа цели
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Тип цели")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Picker("Тип цели", selection: $goalType) {
                                Text("Обычная цель").tag(GoalType.regular)
                                Text("Путешествие").tag(GoalType.travel)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(goalType == .travel ? "Куда едем?" : "Название цели")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField(goalType == .travel ? "Например: Париж, Бали, Турция" : "Название", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(goalType == .travel ? "Общая сумма на поездку" : "Целевая сумма")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Сумма", text: $targetAmount)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: targetAmount) { newValue in
                                    targetAmount = AppUtils.formatInput(newValue)
                                }
                            
                            if goalType == .travel {
                                Text("💡 Сумма будет автоматически разделена: билеты, жилье, развлечения")
                                    .font(.caption)
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                        
                        if goalType == .regular {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Текущая сумма (если уже накопили)")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                TextField("Сумма", text: $currentAmount)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: currentAmount) { newValue in
                                        currentAmount = AppUtils.formatInput(newValue)
                                    }
                            }
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
                            Text(goalType == .travel ? "Дата поездки" : (priority != .niceToHave ? "Желаемая дата" : ""))
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            if goalType == .travel || priority != .niceToHave {
                                DatePicker("Дата", selection: $targetDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                            }
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
            .navigationTitle("Новая цель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Добавить") {
                        // Если приоритет "Желаемая", предлагаем создать хотелку
                        if priority == .niceToHave {
                            showWishlistAlert = true
                        } else {
                            addGoal()
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Может быть, это хотелка?", isPresented: $showWishlistAlert) {
                Button("Добавить как хотелку") {
                    addAsWishlist()
                    dismiss()
                }
                Button("Оставить целью") {
                    addGoal()
                    dismiss()
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("Цель без строгой даты больше похожа на хотелку. Хотите добавить в раздел \"Хотелки\"?")
            }
        }
    }
    
    private func addGoal() {
        let totalAmount = Double(targetAmount.replacingOccurrences(of: " ", with: "")) ?? 0
        
        if goalType == .travel {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            let amountPerPart = totalAmount / 3.0
            
            func clampedDate(offset: Int) -> Date {
                let candidate = calendar.date(byAdding: .day, value: offset, to: targetDate) ?? targetDate
                return candidate < today ? today : candidate
            }
            
            let ticketsDate = clampedDate(offset: -90)
            let accommodationDate = clampedDate(offset: -30)
            let entertainmentDate = clampedDate(offset: 0)
            
            let subgoals = [
                TravelSubgoal(name: "tickets", amount: amountPerPart, targetDate: ticketsDate),
                TravelSubgoal(name: "accommodation", amount: amountPerPart, targetDate: accommodationDate),
                TravelSubgoal(name: "entertainment", amount: amountPerPart, targetDate: entertainmentDate)
            ]
            
            let newGoal = Goal(
                name: name.trimmingCharacters(in: .whitespaces),
                targetAmount: totalAmount,
                currentAmount: 0,
                targetDate: ticketsDate, // Самая ранняя дата (билеты)
                description: description.trimmingCharacters(in: .whitespaces),
                priority: priority,
                type: .travel,
                travelSubgoals: subgoals
            )
            
            goals.append(newGoal)
            onSave?()
        } else {
            // Обычная цель
            let finalTargetDate = priority == .niceToHave ? Calendar.current.date(byAdding: .year, value: 10, to: Date()) ?? Date() : targetDate
            
            let newGoal = Goal(
                name: name.trimmingCharacters(in: .whitespaces),
                targetAmount: totalAmount,
                currentAmount: Double(currentAmount.replacingOccurrences(of: " ", with: "")) ?? 0,
                targetDate: finalTargetDate,
                description: description.trimmingCharacters(in: .whitespaces),
                priority: priority,
                type: .regular
            )
            
            goals.append(newGoal)
            onSave?()
        }
    }
    
    private func addAsWishlist() {
        let newItem = WishlistItem(
            name: name.trimmingCharacters(in: .whitespaces),
            amount: Double(targetAmount.replacingOccurrences(of: " ", with: "")) ?? 0,
            note: description.trimmingCharacters(in: .whitespaces)
        )
        
        var items: [WishlistItem] = []
        if let decoded = try? JSONDecoder().decode([WishlistItem].self, from: wishlistItemsData) {
            items = decoded
        }
        items.append(newItem)
        
        if let encoded = try? JSONEncoder().encode(items) {
            wishlistItemsData = encoded
        }
    }
} 
