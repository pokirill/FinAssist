import Foundation

struct Wishlist: Identifiable, Codable {
    let id: UUID
    var name: String
    var targetAmount: Double
    var saved: Double
}
