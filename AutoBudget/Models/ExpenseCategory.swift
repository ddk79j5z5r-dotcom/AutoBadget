import Foundation

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case fuel
    case maintenance
    case tires
    case tuning
    case insurance
    case taxes
    case repair
    case parts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fuel: "Топливо"
        case .maintenance: "Обслуживание"
        case .tires: "Шины"
        case .tuning: "Тюнинг"
        case .insurance: "Страховка"
        case .taxes: "Налоги"
        case .repair: "Ремонт"
        case .parts: "Запчасти"
        }
    }

    var emoji: String {
        switch self {
        case .fuel: "⛽"
        case .maintenance: "🔧"
        case .tires: "🛞"
        case .tuning: "🚗"
        case .insurance: "🧾"
        case .taxes: "📋"
        case .repair: "🛠"
        case .parts: "📦"
        }
    }

    /// Название по умолчанию для новой записи
    var defaultTitle: String {
        switch self {
        case .fuel: "Заправка"
        case .maintenance: "Обслуживание"
        case .tires: "Шиномонтаж"
        case .tuning: "Тюнинг"
        case .insurance: "ОСАГО"
        case .taxes: "Транспортный налог"
        case .repair: "Ремонт"
        case .parts: "Запчасти"
        }
    }

    /// Фильтры экрана «Расходы»
    static let filterOrder: [ExpenseCategory] = [.fuel, .repair, .parts, .tires, .tuning, .insurance, .maintenance, .taxes]
}
