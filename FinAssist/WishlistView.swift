import SwiftUI

struct WishlistView: View {
    @AppStorage("wishlistItems") private var wishlistItemsData: Data = Data()
    @State private var wishlistItems: [WishlistItem] = []
    @State private var showingAddWishlist = false
    @State private var editingItem: WishlistItem? = nil
    
    // Данные для расчета ориентировочных дат
    @AppStorage("totalMonthlyIncome") private var totalMonthlyIncome: Double = 0
    @AppStorage("totalMonthlyExpense") private var totalMonthlyExpense: Double = 0
    @AppStorage("goalsData") private var goalsData: Data = Data()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Описание раздела
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💭 Хотелки")
                            .font(.title2).bold()
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Здесь можно хранить вещи, которые хочется купить. Мы покажем, когда это можно сделать без вреда основным целям и подушке.")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(AppColors.surface)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 8)
                    
                    // Список хотелок
                    if wishlistItems.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "star.circle")
                                .font(.system(size: 60))
                                .foregroundColor(AppColors.textSecondary.opacity(0.5))
                            
                            Text("Пока нет хотелок")
                                .font(.headline)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text("Добавьте первую хотелку, чтобы узнать, когда сможете её купить")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(wishlistItems) { item in
                                wishlistCard(item)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingItem = item
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                wishlistItems.removeAll { $0.id == item.id }
                                            }
                                        } label: {
                                            Label("Удалить", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            editingItem = item
                                        } label: {
                                            Label("Изменить", systemImage: "pencil")
                                        }
                                        .tint(AppColors.primary)
                                    }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
                
                // Кнопка добавления
                VStack {
                    Spacer()
                    Button(action: {
                        showingAddWishlist = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Добавить хотелку")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.primary)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddWishlist) {
                AddWishlistView(wishlistItems: $wishlistItems)
            }
            .sheet(item: $editingItem) { item in
                EditWishlistView(wishlistItems: $wishlistItems, item: item)
            }
            .onAppear {
                loadWishlistItems()
                calculateEstimatedDates()
            }
            .onChange(of: wishlistItems) { _ in
                saveWishlistItems()
                calculateEstimatedDates()
            }
        }
    }
    
    @ViewBuilder
    private func wishlistCard(_ item: WishlistItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("\(AppUtils.numberFormatter.string(from: NSNumber(value: item.amount)) ?? "0") ₽")
                        .font(.title3).bold()
                        .foregroundColor(AppColors.primary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Ориентировочная дата
            if let estimatedDate = item.estimatedDate {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(AppColors.accent)
                    Text("Примерно с \(AppUtils.dateFormatter.string(from: estimatedDate)) можно купить")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(AppColors.warning)
                    Text("Пока не получается выделить деньги на хотелки")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            if let note = item.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(12)
    }
    
    private func loadWishlistItems() {
        if let decoded = try? JSONDecoder().decode([WishlistItem].self, from: wishlistItemsData) {
            wishlistItems = decoded
        }
    }
    
    private func saveWishlistItems() {
        if let encoded = try? JSONEncoder().encode(wishlistItems) {
            wishlistItemsData = encoded
        }
    }
    
    private func calculateEstimatedDates() {
        // Загружаем цели для расчета
        let goals: [Goal]
        if let decoded = try? JSONDecoder().decode([Goal].self, from: goalsData) {
            goals = decoded
        } else {
            goals = []
        }
        
        // Рассчитываем свободные деньги после всех обязательств
        let freePerMonth = totalMonthlyIncome - totalMonthlyExpense
        
        // Вычитаем деньги, выделенные на цели
        let totalGoalsPerMonth = goals.reduce(0.0) { sum, goal in
            sum + (goal.actualPerMonth ?? 0)
        }
        
        let remainingPerMonth = freePerMonth - totalGoalsPerMonth
        
        // Обновляем ориентировочные даты для хотелок
        for i in 0..<wishlistItems.count {
            if remainingPerMonth > 0 {
                let monthsNeeded = ceil(wishlistItems[i].amount / remainingPerMonth)
                let calendar = Calendar.current
                wishlistItems[i].estimatedDate = calendar.date(byAdding: .month, value: Int(monthsNeeded), to: Date())
            } else {
                wishlistItems[i].estimatedDate = nil
            }
        }
    }
}

