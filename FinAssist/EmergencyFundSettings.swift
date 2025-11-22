import Foundation

struct EmergencyFundSettings: Codable {
    var isEnabled: Bool
    var months: Int // 3, 6, 9, или 12
    var skipCurrentPeriod: Bool // Не откладывать в этот период
    
    init(isEnabled: Bool = true, months: Int = 3, skipCurrentPeriod: Bool = false) {
        self.isEnabled = isEnabled
        self.months = months
        self.skipCurrentPeriod = skipCurrentPeriod
    }
}

