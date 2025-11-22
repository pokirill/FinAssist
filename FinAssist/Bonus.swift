import Foundation

enum BonusType: String, Codable { case oneTime, recurring }
enum BonusPeriod: String, Codable, CaseIterable { case month, quarter, year }

struct Bonus: Identifiable, Codable {
    let id: UUID
    var name: String
    var amount: Double
    var type: BonusType
    var date: Date? // для разовой премии
    var period: BonusPeriod? // для регулярной премии
    var start: Date?
    var end: Date?
}
