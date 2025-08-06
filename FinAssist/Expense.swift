import Foundation

struct Expense: Codable, Identifiable {
    let id: UUID
    var rent: Double
    var loans: Double
    var utilities: Double
    var groceries: Double
    var communication: Double
    var subscriptions: Double
    var transport: Double
    var hobbies: Double
    var entertainment: Double
    var beauty: Double
    var additional: [AdditionalExpense]
    
    var totalMonthlyExpense: Double {
        return rent + loans + utilities + groceries + communication +
               subscriptions + transport + hobbies + entertainment + beauty +
               additional.reduce(0) { $0 + $1.amount }
    }
    
    init() {
        self.id = UUID()
        self.rent = 0
        self.loans = 0
        self.utilities = 0
        self.groceries = 0
        self.communication = 0
        self.subscriptions = 0
        self.transport = 0
        self.hobbies = 0
        self.entertainment = 0
        self.beauty = 0
        self.additional = []
    }
}

struct AdditionalExpense: Codable, Identifiable {
    let id: UUID
    var name: String
    var amount: Double
    var comment: String
    
    init(name: String, amount: Double, comment: String = "") {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.comment = comment
    }
}

enum ExpenseCategory: String, CaseIterable {
    case rent = "Аренда хатки"
    case loans = "Ипотеки/Кредиты"
    case utilities = "Коммуналка"
    case groceries = "Продукты"
    case communication = "Мобильная и домашняя связь"
    case subscriptions = "Подписки и прочее"
    case transport = "Транспорт, топливо и штрафы"
    case hobbies = "Хобби/тренировки"
    case entertainment = "Рестораны и развлечения"
    case beauty = "Бьюти и здоровье"
    case additional = "Дополнительно"
}
