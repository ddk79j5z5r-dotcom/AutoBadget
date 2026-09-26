import Foundation
import Observation
import SwiftData

struct ServiceOverview {
    var lastService: RepairRecord?
    /// Ближайшее плановое ТО: деталь категории «Плановое ТО» или напоминание о масле/фильтрах
    var nextService: UpcomingService?
    var lastRepair: RepairRecord?
    var nearestWorks: [UpcomingService] = []
}

@Observable
final class CarViewModel {
    var showEditCar = false
    var showMileageUpdate = false
    var showResetConfirm = false
    var mileageDraft = ""

    func overview(repairs: [RepairRecord],
                  reminders: [Reminder],
                  parts: [Part],
                  expenses: [Expense],
                  mileage: Int) -> ServiceOverview {
        let sorted = repairs.sorted { $0.date > $1.date }
        let upcoming = MaintenanceService.upcoming(reminders: reminders,
                                                   parts: parts,
                                                   currentMileage: mileage,
                                                   dailyKm: AnalyticsService.averageDailyKm(expenses),
                                                   limit: .max)
        let nextService = upcoming.first { item in
            switch item.source {
            case .part(let part): part.category == .service
            case .reminder(let reminder): [.oil, .filters].contains(reminder.kind)
            }
        }
        return ServiceOverview(lastService: sorted.first { $0.category == .service },
                               nextService: nextService,
                               lastRepair: sorted.first { $0.category != .service },
                               nearestWorks: Array(upcoming.prefix(3)))
    }

    func serviceHistory(_ repairs: [RepairRecord]) -> [RepairRecord] {
        repairs.filter { $0.category == .service }.sorted { $0.date > $1.date }
    }

    /// Ручная корректировка пробега — в отличие от записей расходов, может и уменьшить его
    @MainActor
    func applyMileage(context: ModelContext) {
        guard let value = Formatters.parseNumber(mileageDraft), value > 0 else { return }
        DataService.updateMileage(to: Int(value), in: context, onlyIncrease: false)
        try? context.save()
    }
}
