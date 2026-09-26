import Foundation
import Observation

struct DashboardSummary {
    var total: Double = 0
    var thisMonth: Double = 0
    var lastMonth: Double = 0
    var averagePerMonth: Double = 0

    /// Изменение текущего месяца относительно прошлого, %
    var deltaVsLastMonth: Double? {
        guard lastMonth > 0 else { return nil }
        return (thisMonth - lastMonth) / lastMonth * 100
    }
}

@Observable
final class DashboardViewModel {
    var chartMonths = 12

    func summary(for expenses: [Expense], now: Date = .now) -> DashboardSummary {
        let lastMonthDate = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        return DashboardSummary(total: AnalyticsService.total(expenses),
                                thisMonth: AnalyticsService.total(expenses, inMonthOf: now),
                                lastMonth: AnalyticsService.total(expenses, inMonthOf: lastMonthDate),
                                // Среднее за последний год: давние редкие записи не должны «размазывать» показатель
                                averagePerMonth: AnalyticsService.averagePerMonth(StatsPeriod.twelveMonths.filter(expenses, now: now), now: now))
    }

    /// Все 8 категорий в фиксированном порядке — для сетки карточек
    func categoryCards(for expenses: [Expense]) -> [CategoryTotal] {
        let totals = Dictionary(uniqueKeysWithValues: AnalyticsService.byCategory(expenses, includeEmpty: true).map { ($0.category, $0) })
        return ExpenseCategory.allCases.compactMap { totals[$0] }
    }

    func monthly(for expenses: [Expense]) -> [MonthTotal] {
        AnalyticsService.monthly(expenses, lastMonths: chartMonths)
    }

    /// Данные для мини-графика в карточке итога
    func sparkline(for expenses: [Expense]) -> [MonthTotal] {
        AnalyticsService.monthly(expenses, lastMonths: 8)
    }

    /// «Скоро потребуется обслуживание» — не больше 5 ближайших событий из напоминаний и деталей
    func upcoming(reminders: [Reminder], parts: [Part], expenses: [Expense], mileage: Int) -> [UpcomingService] {
        MaintenanceService.upcoming(reminders: reminders,
                                    parts: parts,
                                    currentMileage: mileage,
                                    dailyKm: AnalyticsService.averageDailyKm(expenses),
                                    limit: 5)
    }

    func recent(_ expenses: [Expense], limit: Int = 5) -> [Expense] {
        Array(expenses.sorted { $0.date > $1.date }.prefix(limit))
    }
}
