import Foundation

struct ExpenseItem: Identifiable, Codable, Equatable {
    let id: UUID
    var category: String
    var customCategory: String
    var amount: String
    var period: String
    var dayOfMonth: Int
    var weekday: String

    init(category: String, customCategory: String = "", amount: String = "", period: String = "Месяц", dayOfMonth: Int = 1, weekday: String = "Пн") {
        self.id = UUID()
        self.category = category
        self.customCategory = customCategory
        self.amount = amount
        self.period = period
        self.dayOfMonth = dayOfMonth
        self.weekday = weekday
    }
}
