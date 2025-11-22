import Foundation

enum EventType: String, Codable {
    case income, bonus, expense, credit, goal, wishlist
}

struct Event: Codable {
    var date: Date
    var type: EventType
    var amount: Double
    var sourceId: UUID
    var description: String?
}
