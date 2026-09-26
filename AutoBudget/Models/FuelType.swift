import Foundation

enum FuelType: String, Codable, CaseIterable, Identifiable, Hashable {
    case ai92
    case ai95
    case ai98
    case ai100
    case diesel
    case lpg
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ai92: "АИ-92"
        case .ai95: "АИ-95"
        case .ai98: "АИ-98"
        case .ai100: "АИ-100"
        case .diesel: "Дизель"
        case .lpg: "Газ (LPG)"
        case .other: "Другое"
        }
    }

    /// Короткая подпись для строк списка: «45 л · 95»
    var shortTitle: String {
        switch self {
        case .ai92: "92"
        case .ai95: "95"
        case .ai98: "98"
        case .ai100: "100"
        case .diesel: "ДТ"
        case .lpg: "Газ"
        case .other: "Другое"
        }
    }
}
