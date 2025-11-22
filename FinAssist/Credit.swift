import Foundation

struct Credit: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var monthlyAmount: Double
    var day: Int // дата списания (1..31)
    var endDate: Date? // дата окончания (необязательно)
    
    init(id: UUID = UUID(), name: String = "Кредит", monthlyAmount: Double, day: Int, endDate: Date? = nil) {
        self.id = id
        self.name = name
        self.monthlyAmount = monthlyAmount
        self.day = day
        self.endDate = endDate
    }
}
