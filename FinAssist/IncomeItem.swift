import Foundation

struct IncomeItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var customName: String
    var amount: String
    var period: String
    var dayOfMonth: Int
    var weekday: String

    init(name: String, customName: String = "", amount: String = "", period: String = "Месяц", dayOfMonth: Int = 1, weekday: String = "Пн") {
        self.id = UUID()
        self.name = name
        self.customName = customName
        self.amount = amount
        self.period = period
        self.dayOfMonth = dayOfMonth
        self.weekday = weekday
    }
}
