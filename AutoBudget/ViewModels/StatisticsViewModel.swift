import Foundation
import Observation

enum StatsPeriod: String, CaseIterable, Identifiable {
    case threeMonths, sixMonths, twelveMonths, allTime
    var id: String { rawValue }
    var title: String {
        switch self {
        case .threeMonths: "3 месяца"
        case .sixMonths: "6 месяцев"
        case .twelveMonths: "12 месяцев"
        case .allTime: "Всё время"
        }
    }

    var shortTitle: String {
        switch self {
        case .threeMonths: "3 мес."
        case .sixMonths: "6 мес."
        case .twelveMonths: "12 мес."
        case .allTime: "Всё"
        }
    }

    /// nil — вся история
    var months: Int? {
        switch self {
        case .threeMonths: 3
        case .sixMonths: 6
        case .twelveMonths: 12
        case .allTime: nil
        }
    }

    /// Начало периода (первое число месяца)
    func start(now: Date = .now) -> Date? {
        months.flatMap { Calendar.current.date(byAdding: .month, value: -($0 - 1), to: now.startOfMonth) }
    }

    func filter(_ expenses: [Expense], now: Date = .now) -> [Expense] {
        guard let start = start(now: now) else { return expenses }
        return expenses.filter { $0.date >= start }
    }

    /// Такой же по длине предыдущий период — для сравнения «↑/↓ %»
    func previous(_ expenses: [Expense], now: Date = .now) -> [Expense]? {
        guard let months, let start = start(now: now),
              let prevStart = Calendar.current.date(byAdding: .month, value: -months, to: start) else { return nil }
        return expenses.filter { $0.date >= prevStart && $0.date < start }
    }
}

enum StatsChart: String, CaseIterable, Identifiable {
    case months, categories, years
    var id: String { rawValue }
    var title: String {
        switch self {
        case .months: "По месяцам"
        case .categories: "По категориям"
        case .years: "По годам"
        }
    }
}

struct StatsMetrics {
    var total: Double = 0
    var averagePerMonth: Double = 0
    var costPerKm: Double?
    var distanceKm: Int?
    var operationsCount = 0
}

@Observable
final class StatisticsViewModel {
    var period: StatsPeriod = .threeMonths
    var chart: StatsChart = .months
    var selectedCategory: ExpenseCategory?

    func filtered(_ expenses: [Expense], now: Date = .now) -> [Expense] {
        period.filter(expenses, now: now)
    }

    /// Изменение среднего расхода топлива к предыдущему периоду, %
    func fuelTrend(_ expenses: [Expense]) -> Double? {
        guard let prev = period.previous(expenses),
              let current = AnalyticsService.averageFuelConsumption(filtered(expenses)),
              let before = AnalyticsService.averageFuelConsumption(prev), before > 0 else { return nil }
        return (current - before) / before * 100
    }

    /// Расход по каждой заправке за период — для линейного графика
    func fuelSeries(_ expenses: [Expense]) -> [FuelFill] {
        AnalyticsService.fuelFills(filtered(expenses)).filter { $0.consumption != nil }
    }

    func metrics(_ expenses: [Expense]) -> StatsMetrics {
        let items = filtered(expenses)
        return StatsMetrics(total: AnalyticsService.total(items),
                            averagePerMonth: AnalyticsService.averagePerMonth(items),
                            costPerKm: AnalyticsService.costPerKm(items),
                            distanceKm: AnalyticsService.distance(items),
                            operationsCount: items.count)
    }

    func fuelStats(_ expenses: [Expense]) -> FuelStats {
        AnalyticsService.fuelStats(filtered(expenses))
    }

    func categories(_ expenses: [Expense]) -> [CategoryTotal] {
        AnalyticsService.byCategory(filtered(expenses))
    }

    func monthly(_ expenses: [Expense]) -> [MonthTotal] {
        let items = filtered(expenses)
        let months: Int
        if let m = period.months {
            months = m
        } else {
            let first = items.map(\.date).min() ?? .now
            months = (Calendar.current.dateComponents([.month], from: first.startOfMonth, to: Date.now.startOfMonth).month ?? 0) + 1
        }
        return AnalyticsService.monthly(items, lastMonths: max(months, 1))
    }

    /// По годам всегда показываем всю историю
    func yearly(_ expenses: [Expense]) -> [YearTotal] {
        AnalyticsService.byYear(expenses)
    }
}
