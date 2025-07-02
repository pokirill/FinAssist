import Foundation

struct Deposit: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var amount: Double
    var note: String

    init(date: Date, amount: Double, note: String = "") {
        self.id = UUID()
        self.date = date
        self.amount = amount
        self.note = note
    }
}
