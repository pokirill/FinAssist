import SwiftUI

struct AppColors {
    // Акцентные цвета (одинаковые для светлой и темной темы)
    static let primary = Color(hex: "#2563EB")
    static let accent = Color(hex: "#3B82F6")
    static let success = Color(hex: "#10B981")
    static let danger = Color(hex: "#EF4444")
    static let warning = Color(hex: "#F59E0B")
    
    // Адаптивные цвета для светлой/темной темы
    static let background = Color(uiColor: UIColor.systemGroupedBackground)
    static let surface = Color(uiColor: UIColor.secondarySystemGroupedBackground)
    static let textPrimary = Color(uiColor: UIColor.label)
    static let textSecondary = Color(uiColor: UIColor.secondaryLabel)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Общие утилиты для форматирования
struct AppUtils {
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter
    }()
    
    static func formatInput(_ value: String) -> String {
        let digits = value.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        guard let number = Int(digits) else { return "" }
        return numberFormatter.string(from: NSNumber(value: number)) ?? ""
    }
}
