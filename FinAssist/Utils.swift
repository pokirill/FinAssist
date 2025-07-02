import Foundation

let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = " "
    formatter.maximumFractionDigits = 0
    return formatter
}()

func formatInput(_ value: String) -> String {
    let digits = value.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
    guard let number = Int(digits) else { return "" }
    return numberFormatter.string(from: NSNumber(value: number)) ?? ""
}
