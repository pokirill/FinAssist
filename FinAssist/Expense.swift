import Foundation

struct Expense: Codable, Identifiable {
    let id: UUID
    // Универсальные поля для day-by-day-алгоритма
    var category: String? // для универсального расхода
    var monthlyAmount: Double? // для универсального расхода
    var day: Int? // для day-by-day-алгоритма
    var period: ExpensePeriod? // для day-by-day-алгоритма
    var end: Date? // для кредитов
    // Старые поля для обратной совместимости
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
    var marketplaces: Double
    var walletDaily: Double
    var additional: [AdditionalExpense]

    var rentDay: Int?
    var loansDay: Int?
    var utilitiesDay: Int?
    var groceriesDay: Int?
    var communicationDay: Int?
    var subscriptionsDay: Int?
    var transportDay: Int?
    var hobbiesDay: Int?
    var entertainmentDay: Int?
    var beautyDay: Int?
    var marketplacesDay: Int?

    var totalMonthlyExpense: Double {
        return rent + loans + utilities + groceries + communication +
               subscriptions + transport + hobbies + entertainment + beauty + marketplaces +
               walletDaily +
               additional.reduce(0) { $0 + $1.amount }
    }
    
    init() {
        self.id = UUID()
        self.category = nil
        self.monthlyAmount = nil
        self.day = nil
        self.period = nil
        self.end = nil
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
        self.marketplaces = 0
        self.walletDaily = 0
        self.additional = []
        self.rentDay = nil
        self.loansDay = nil
        self.utilitiesDay = nil
        self.groceriesDay = nil
        self.communicationDay = nil
        self.subscriptionsDay = nil
        self.transportDay = nil
        self.hobbiesDay = nil
        self.entertainmentDay = nil
        self.beautyDay = nil
        self.marketplacesDay = nil
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

enum ExpensePeriod: String, Codable { case month, quarter, year }

enum ExpenseCategory: String, CaseIterable {
    case rent = "Аренда жилья"
    case loans = "Оплата кредитов/ипотеки"
    case utilities = "Коммунальные платежи"
    case groceries = "Покупка продуктов"
    case communication = "Мобильная и домашняя связь"
    case subscriptions = "Подписки на сервисы"
    case transport = "Транспорт и топливо"
    case hobbies = "Хобби и тренировки"
    case entertainment = "Рестораны и развлечения"
    case beauty = "Бьюти и здоровье"
    case marketplaces = "Маркетплейсы (Ozon/WB/Яндекс)"
    case additional = "Дополнительно"
} 
