import Foundation

/// Состояние ресурса детали или регламентной работы
enum ServiceStatus: Int, Comparable {
    case ok
    /// Осталось меньше порога предупреждения (по умолчанию 5 000 км или 30 дней)
    case warning
    /// Осталось меньше критического порога (1 000 км или 7 дней)
    case critical
    /// Ресурс исчерпан
    case overdue

    static func < (lhs: ServiceStatus, rhs: ServiceStatus) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .ok: "В норме"
        case .warning: "Скоро"
        case .critical: "Срочно"
        case .overdue: "Просрочено"
        }
    }
}

/// Общая логика ресурса: интервал по пробегу и/или по времени от точки отсчёта.
/// Реализуют `Reminder` (регламентные работы, документы) и `Part` (установленные детали).
protocol ServiceLifeTracked: AnyObject {
    var trackingTitle: String { get }
    var trackingSymbol: String { get }
    /// Пробег, от которого отсчитывается ресурс
    var baseMileage: Int { get }
    /// Дата, от которой отсчитывается ресурс
    var baseDate: Date { get }
    /// Ресурс по пробегу, км (0 — не учитывается)
    var lifeKm: Int { get }
    /// Ресурс по времени, мес. (0 — не учитывается)
    var lifeMonths: Int { get }
    /// За сколько дней до срока присылать уведомление
    var notifyDaysBefore: Int { get }
    var notificationsActive: Bool { get }
    /// Стабильный идентификатор для локальных уведомлений
    var notificationID: String { get }
    /// Подпись статуса `.overdue` («Просрочено» / «Требуется замена»)
    var overdueTitle: String { get }
}

extension ServiceLifeTracked {
    static var warningDays: Int { 30 }
    static var criticalDays: Int { 7 }

    var nextMileage: Int? { lifeKm > 0 ? baseMileage + lifeKm : nil }

    var nextDate: Date? {
        lifeMonths > 0 ? Calendar.current.date(byAdding: .month, value: lifeMonths, to: baseDate) : nil
    }

    /// Порог «Скоро»: 5 000 км, но не больше четверти ресурса (для коротких интервалов вроде замены масла)
    var warningKm: Int { min(5_000, max(lifeKm / 4, 1)) }

    /// Порог «Срочно»: 1 000 км, но не больше десятой части ресурса
    var criticalKm: Int { min(1_000, max(lifeKm / 10, 1)) }

    func traveledKm(currentMileage: Int) -> Int { max(0, currentMileage - baseMileage) }

    func remainingKm(currentMileage: Int) -> Int? {
        nextMileage.map { $0 - currentMileage }
    }

    func remainingDays(from now: Date = .now) -> Int? {
        guard let nextDate else { return nil }
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: now), to: cal.startOfDay(for: nextDate)).day
    }

    /// Износ 0…1+ — берётся худший из двух критериев
    func progress(currentMileage: Int, now: Date = .now) -> Double {
        var values: [Double] = []
        if lifeKm > 0 {
            values.append(Double(currentMileage - baseMileage) / Double(lifeKm))
        }
        if let nextDate {
            let total = nextDate.timeIntervalSince(baseDate)
            if total > 0 { values.append(now.timeIntervalSince(baseDate) / total) }
        }
        return max(0, values.max() ?? 0)
    }

    func status(currentMileage: Int, now: Date = .now) -> ServiceStatus {
        let km = remainingKm(currentMileage: currentMileage)
        let days = remainingDays(from: now)
        if (km ?? 1) <= 0 || (days ?? 1) <= 0 { return .overdue }
        if (km ?? .max) < criticalKm || (days ?? .max) < Self.criticalDays { return .critical }
        if (km ?? .max) < warningKm || (days ?? .max) < Self.warningDays { return .warning }
        return .ok
    }

    func statusTitle(currentMileage: Int, now: Date = .now) -> String {
        let status = status(currentMileage: currentMileage, now: now)
        return status == .overdue ? overdueTitle : status.title
    }
}
