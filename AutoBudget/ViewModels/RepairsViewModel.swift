import Foundation
import Observation
import SwiftData

struct RepairStats {
    var total: Double = 0
    var count = 0
    var average: Double = 0
    var mostExpensive: RepairRecord?
    var last: RepairRecord?
}

struct TimelineYear: Identifiable {
    let year: Int
    let repairs: [RepairRecord]
    var id: Int { year }
    var total: Double { repairs.reduce(0) { $0 + $1.totalCost } }
}

@Observable
final class RepairsViewModel {
    var selectedCategory: RepairCategory?
    var searchText = ""
    var showAddRepair = false

    func filtered(_ repairs: [RepairRecord]) -> [RepairRecord] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return repairs
            .filter { selectedCategory == nil || $0.category == selectedCategory }
            .filter { r in
                guard !query.isEmpty else { return true }
                return r.title.lowercased().contains(query)
                    || r.worksDone.lowercased().contains(query)
                    || r.partsUsed.lowercased().contains(query)
                    || r.shop.lowercased().contains(query)
            }
            .sorted { $0.date > $1.date }
    }

    func stats(_ repairs: [RepairRecord]) -> RepairStats {
        let total = repairs.reduce(0) { $0 + $1.totalCost }
        return RepairStats(total: total,
                           count: repairs.count,
                           average: repairs.isEmpty ? 0 : total / Double(repairs.count),
                           mostExpensive: repairs.max { $0.totalCost < $1.totalCost },
                           last: repairs.max { $0.date < $1.date })
    }

    /// Общая временная шкала эксплуатации: годы по убыванию, внутри — по дате
    static func timeline(_ repairs: [RepairRecord]) -> [TimelineYear] {
        Dictionary(grouping: repairs) { $0.date.year }
            .map { TimelineYear(year: $0.key, repairs: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.year > $1.year }
    }

    @MainActor
    func delete(_ repair: RepairRecord, context: ModelContext) {
        DataService.delete(repair, in: context)
        try? context.save()
    }
}
