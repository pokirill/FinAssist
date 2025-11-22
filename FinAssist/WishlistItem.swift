import Foundation

struct WishlistItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var amount: Double
    var createdAt: Date
    var note: String?
    
    // Ориентировочная дата покупки (рассчитывается)
    var estimatedDate: Date?
    var saved: Double
    var forecastDate: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        createdAt: Date = Date(),
        note: String? = nil,
        saved: Double = 0,
        forecastDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.createdAt = createdAt
        self.note = note
        self.saved = saved
        self.forecastDate = forecastDate
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, amount, createdAt, note, estimatedDate, saved, forecastDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decode(Double.self, forKey: .amount)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        estimatedDate = try container.decodeIfPresent(Date.self, forKey: .estimatedDate)
        saved = try container.decodeIfPresent(Double.self, forKey: .saved) ?? 0
        forecastDate = try container.decodeIfPresent(Date.self, forKey: .forecastDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(amount, forKey: .amount)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(estimatedDate, forKey: .estimatedDate)
        try container.encode(saved, forKey: .saved)
        try container.encodeIfPresent(forecastDate, forKey: .forecastDate)
    }
}

