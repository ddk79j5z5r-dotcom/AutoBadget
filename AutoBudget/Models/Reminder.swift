import Foundation
import SwiftData

enum ReminderKind: String, Codable, CaseIterable, Identifiable {
    case oil
    case filters
    case brakePads
    case timingBelt
    case osago
    case inspection
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oil: "Замена масла"
        case .filters: "Замена фильтров"
        case .brakePads: "Замена колодок"
        case .timingBelt: "Замена ремня ГРМ"
        case .osago: "ОСАГО"
        case .inspection: "Техосмотр"
        case .custom: "Своё напоминание"
        }
    }

    var symbol: String {
        switch self {
        case .oil: "drop.fill"
        case .filters: "aqi.medium"
        case .brakePads: "exclamationmark.brakesignal"
        case .timingBelt: "gearshape.2.fill"
        case .osago: "doc.text.fill"
        case .inspection: "checkmark.seal.fill"
        case .custom: "bell.fill"
        }
    }

    var defaultIntervalKm: Int? {
        switch self {
        case .oil: 7_500
        case .filters: 15_000
        case .brakePads: 30_000
        case .timingBelt: 100_000
        case .osago, .inspection, .custom: nil
        }
    }

    var defaultIntervalMonths: Int? {
        switch self {
        case .oil: 6
        case .filters: 12
        case .brakePads: nil
        case .timingBelt: 60
        case .osago: 12
        case .inspection: 24
        case .custom: 12
        }
    }
}

@Model
final class Reminder {
    var uid: UUID = UUID()
    var kindRaw: String = ReminderKind.custom.rawValue
    var title: String = ""
    /// Интервал по пробегу, км (0 — не учитывается)
    var intervalKm: Int = 0
    /// Интервал по времени, мес. (0 — не учитывается)
    var intervalMonths: Int = 0
    var lastDate: Date = Date.now
    var lastMileage: Int = 0
    var notificationsEnabled: Bool = true
    /// За сколько дней предупредить
    var notifyDaysBefore: Int = 7

    init(kind: ReminderKind,
         title: String? = nil,
         intervalKm: Int? = nil,
         intervalMonths: Int? = nil,
         lastDate: Date,
         lastMileage: Int,
         notificationsEnabled: Bool = true,
         notifyDaysBefore: Int = 7) {
        self.uid = UUID()
        self.kindRaw = kind.rawValue
        self.title = title ?? kind.title
        self.intervalKm = intervalKm ?? kind.defaultIntervalKm ?? 0
        self.intervalMonths = intervalMonths ?? kind.defaultIntervalMonths ?? 0
        self.lastDate = lastDate
        self.lastMileage = lastMileage
        self.notificationsEnabled = notificationsEnabled
        self.notifyDaysBefore = notifyDaysBefore
    }

    var kind: ReminderKind {
        get { ReminderKind(rawValue: kindRaw) ?? .custom }
        set { kindRaw = newValue.rawValue }
    }

    func markDone(mileage: Int, date: Date = .now) {
        lastMileage = mileage
        lastDate = date
    }
}

extension Reminder: ServiceLifeTracked {
    var trackingTitle: String { title }
    var trackingSymbol: String { kind.symbol }
    var baseMileage: Int { lastMileage }
    var baseDate: Date { lastDate }
    var lifeKm: Int { intervalKm }
    var lifeMonths: Int { intervalMonths }
    var notificationsActive: Bool { notificationsEnabled }
    var notificationID: String { "reminder-\(uid.uuidString)" }
    var overdueTitle: String { "Просрочено" }
}
