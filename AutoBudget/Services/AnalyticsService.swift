import Foundation

struct MonthTotal: Identifiable, Hashable {
    let month: Date
    let total: Double
    var id: Date { month }
}

struct CategoryTotal: Identifiable, Hashable {
    let category: ExpenseCategory
    let total: Double
    let share: Double
    var id: ExpenseCategory { category }
}

struct YearTotal: Identifiable, Hashable {
    let year: Int
    let total: Double
    var id: Int { year }
}

struct FuelFill: Identifiable {
    let expense: Expense
    let liters: Double
    /// Пробег с предыдущей заправки, км
    let distance: Int?
    /// Расход на этом отрезке, л/100 км
    let consumption: Double?
    var id: UUID { expense.uid }
    var pricePerLiter: Double { expense.pricePerLiter ?? 0 }
}

struct FuelTypeStats: Identifiable {
    let type: FuelType
    let fillsCount: Int
    let liters: Double
    let averagePricePerLiter: Double?
    /// л/100 км на отрезках, заправленных этим топливом
    let consumption: Double?
    var id: FuelType { type }
}

struct FuelPricePoint: Identifiable {
    let id: UUID
    let date: Date
    let pricePerLiter: Double
    let type: FuelType
}

struct FuelStats {
    var consumption: Double?
    var averagePricePerLiter: Double?
    var costPer100Km: Double?
    var fillsCount = 0
    var lastFill: Expense?
    var byType: [FuelTypeStats] = []
    var pricePoints: [FuelPricePoint] = []
}

/// Чистые функции расчёта статистики — легко тестировать и переиспользовать во ViewModel
enum AnalyticsService {
    static func total(_ expenses: [Expense]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    static func total(_ expenses: [Expense], inMonthOf date: Date) -> Double {
        let cal = Calendar.current
        return expenses
            .filter { cal.isDate($0.date, equalTo: date, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    /// Средние траты в месяц с момента первой записи
    static func averagePerMonth(_ expenses: [Expense], now: Date = .now) -> Double {
        guard let first = expenses.map(\.date).min() else { return 0 }
        let months = (Calendar.current.dateComponents([.month], from: first.startOfMonth, to: now.startOfMonth).month ?? 0) + 1
        return total(expenses) / Double(max(months, 1))
    }

    /// Суммы за последние `count` месяцев (включая текущий), пустые месяцы = 0
    static func monthly(_ expenses: [Expense], lastMonths count: Int, now: Date = .now) -> [MonthTotal] {
        let cal = Calendar.current
        let current = now.startOfMonth
        var buckets: [Date: Double] = [:]
        for e in expenses { buckets[e.date.startOfMonth, default: 0] += e.amount }
        return (0..<count).reversed().compactMap { offset in
            guard let month = cal.date(byAdding: .month, value: -offset, to: current) else { return nil }
            return MonthTotal(month: month, total: buckets[month] ?? 0)
        }
    }

    static func byCategory(_ expenses: [Expense], includeEmpty: Bool = false) -> [CategoryTotal] {
        let sum = total(expenses)
        var buckets: [ExpenseCategory: Double] = [:]
        for e in expenses { buckets[e.category, default: 0] += e.amount }
        return ExpenseCategory.allCases
            .map { CategoryTotal(category: $0, total: buckets[$0] ?? 0, share: sum > 0 ? (buckets[$0] ?? 0) / sum : 0) }
            .filter { includeEmpty || $0.total > 0 }
            .sorted { $0.total > $1.total }
    }

    static func byYear(_ expenses: [Expense]) -> [YearTotal] {
        var buckets: [Int: Double] = [:]
        for e in expenses { buckets[e.date.year, default: 0] += e.amount }
        return buckets.map { YearTotal(year: $0.key, total: $0.value) }.sorted { $0.year < $1.year }
    }

    /// Средний расход топлива, л/100 км.
    /// Метод «полного бака»: литры первой заправки не учитываются, дистанция — между первой и последней.
    static func averageFuelConsumption(_ expenses: [Expense]) -> Double? {
        let fills = expenses
            .filter { $0.category == .fuel && ($0.liters ?? 0) > 0 && $0.mileage > 0 }
            .sorted { $0.mileage < $1.mileage }
        guard fills.count >= 2, let first = fills.first, let last = fills.last else { return nil }
        let distance = Double(last.mileage - first.mileage)
        guard distance > 0 else { return nil }
        let liters = fills.dropFirst().reduce(0) { $0 + ($1.liters ?? 0) }
        return liters / distance * 100
    }

    /// Заправки с рассчитанным расходом на каждом отрезке (по возрастанию пробега)
    static func fuelFills(_ expenses: [Expense]) -> [FuelFill] {
        let fills = expenses
            .filter { $0.category == .fuel && ($0.liters ?? 0) > 0 }
            .sorted { ($0.mileage, $0.date) < ($1.mileage, $1.date) }
        var result: [FuelFill] = []
        var previousKm: Int?
        for e in fills {
            let liters = e.liters ?? 0
            var distance: Int?
            if let previousKm, e.mileage > previousKm { distance = e.mileage - previousKm }
            let consumption = distance.map { liters / Double($0) * 100 }
            result.append(FuelFill(expense: e, liters: liters, distance: distance, consumption: consumption))
            if e.mileage > 0 { previousKm = e.mileage }
        }
        return result
    }

    /// Сводная статистика по заправкам.
    /// Стоимость 100 км и расход по типам считаются по отрезкам между заправками (метод «полного бака»).
    static func fuelStats(_ expenses: [Expense]) -> FuelStats {
        let fills = fuelFills(expenses)
        guard !fills.isEmpty else { return FuelStats() }
        let segments = fills.filter { $0.distance != nil }
        let segmentKm = segments.reduce(0) { $0 + ($1.distance ?? 0) }
        let segmentCost = segments.reduce(0) { $0 + $1.expense.amount }

        let byType = Dictionary(grouping: fills) { $0.expense.fuelType ?? .other }
            .map { type, items -> FuelTypeStats in
                let liters = items.reduce(0) { $0 + $1.liters }
                let cost = items.reduce(0) { $0 + $1.expense.amount }
                let typeSegments = items.filter { $0.distance != nil }
                let typeKm = typeSegments.reduce(0) { $0 + ($1.distance ?? 0) }
                let typeLiters = typeSegments.reduce(0) { $0 + $1.liters }
                return FuelTypeStats(type: type,
                                     fillsCount: items.count,
                                     liters: liters,
                                     averagePricePerLiter: liters > 0 ? cost / liters : nil,
                                     consumption: typeKm > 0 ? typeLiters / Double(typeKm) * 100 : nil)
            }
            .sorted { $0.fillsCount > $1.fillsCount }

        return FuelStats(consumption: averageFuelConsumption(expenses),
                         averagePricePerLiter: fuelSpentPerLiter(expenses),
                         costPer100Km: segmentKm > 0 ? segmentCost / Double(segmentKm) * 100 : nil,
                         fillsCount: fills.count,
                         lastFill: fills.max { $0.expense.date < $1.expense.date }?.expense,
                         byType: byType,
                         pricePoints: fills
                            .sorted { $0.expense.date < $1.expense.date }
                            .map { FuelPricePoint(id: $0.id, date: $0.expense.date,
                                                  pricePerLiter: $0.pricePerLiter,
                                                  type: $0.expense.fuelType ?? .other) })
    }

    /// Пробег, пройденный за период по записям с указанным пробегом
    static func distance(_ expenses: [Expense]) -> Int? {
        let mileages = expenses.map(\.mileage).filter { $0 > 0 }
        guard let minKm = mileages.min(), let maxKm = mileages.max(), maxKm > minKm else { return nil }
        return maxKm - minKm
    }

    /// Средний пробег в день за последний год — для прогноза, когда наступит обслуживание по пробегу
    static func averageDailyKm(_ expenses: [Expense], now: Date = .now) -> Double? {
        guard let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) else { return nil }
        let points = expenses.filter { $0.mileage > 0 && $0.date >= yearAgo }
        guard let first = points.min(by: { $0.date < $1.date }),
              let last = points.max(by: { $0.date < $1.date }) else { return nil }
        let days = last.date.timeIntervalSince(first.date) / 86_400
        let km = Double(last.mileage - first.mileage)
        guard days >= 30, km > 0 else { return nil }
        return km / days
    }

    /// Стоимость 1 км: все траты за период, делённые на пройденный за этот период пробег
    static func costPerKm(_ expenses: [Expense]) -> Double? {
        distance(expenses).map { total(expenses) / Double($0) }
    }

    static func fuelSpentPerLiter(_ expenses: [Expense]) -> Double? {
        let fills = expenses.filter { $0.category == .fuel && ($0.liters ?? 0) > 0 }
        let liters = fills.reduce(0) { $0 + ($1.liters ?? 0) }
        guard liters > 0 else { return nil }
        return total(fills) / liters
    }
}
