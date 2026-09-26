import Foundation

/// Ближайшее событие обслуживания: регламентная работа или замена детали
struct UpcomingService: Identifiable {
    enum Source {
        case reminder(Reminder)
        case part(Part)
    }

    let source: Source
    let status: ServiceStatus
    let progress: Double
    let remainingKm: Int?
    let remainingDays: Int?
    /// Средний пробег в день, по которому километры переводятся в дни
    let dailyKm: Double
    /// Оценка, через сколько дней наступит событие — общая шкала для сортировки км и дат
    var estimatedDays: Double {
        let byKm = remainingKm.map { Double($0) / dailyKm } ?? .infinity
        let byDays = remainingDays.map(Double.init) ?? .infinity
        return min(byKm, byDays)
    }

    var item: any ServiceLifeTracked {
        switch source {
        case .reminder(let reminder): reminder
        case .part(let part): part
        }
    }

    var id: String { item.notificationID }
    var title: String { item.trackingTitle }
    var symbol: String { item.trackingSymbol }

    /// «Через 2 000 км», «Через 20 дней» или «Требуется замена» — по более срочному критерию
    var headline: String {
        if status == .overdue { return item.overdueTitle }
        if let remainingKm, let remainingDays {
            let kmIsSooner = Double(remainingKm) / dailyKm <= Double(remainingDays)
            return kmIsSooner ? "Через \(remainingKm.km)" : "Через \(Plural.days(remainingDays))"
        }
        if let remainingKm { return "Через \(remainingKm.km)" }
        if let remainingDays { return "Через \(Plural.days(remainingDays))" }
        return status.title
    }
}

/// Сводит напоминания и детали в единый список ближайшего обслуживания
enum MaintenanceService {
    /// Если истории пробега недостаточно, считаем ~40 км в день (≈ 14 600 км в год)
    static let fallbackDailyKm: Double = 40

    static func upcoming(reminders: [Reminder],
                         parts: [Part],
                         currentMileage: Int,
                         dailyKm: Double?,
                         limit: Int = 5,
                         now: Date = .now) -> [UpcomingService] {
        let pace = max(dailyKm ?? fallbackDailyKm, 1)
        let sources = reminders.map(UpcomingService.Source.reminder)
            + parts.filter(\.isActive).map(UpcomingService.Source.part)

        let items = sources.map { source -> UpcomingService in
            let item: any ServiceLifeTracked = switch source {
            case .reminder(let reminder): reminder
            case .part(let part): part
            }
            return UpcomingService(source: source,
                                   status: item.status(currentMileage: currentMileage, now: now),
                                   progress: item.progress(currentMileage: currentMileage, now: now),
                                   remainingKm: item.remainingKm(currentMileage: currentMileage),
                                   remainingDays: item.remainingDays(from: now),
                                   dailyKm: pace)
        }
        return Array(items.sorted { $0.estimatedDays < $1.estimatedDays }.prefix(limit))
    }
}
