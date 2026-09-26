import Foundation
import Observation
import SwiftData

struct PartGroup: Identifiable {
    let category: RepairCategory
    let parts: [Part]
    var id: RepairCategory { category }
}

struct PartsSummary {
    var total = 0
    /// Ресурс исчерпан
    var replaceNow = 0
    /// «Скоро» и «Срочно»
    var attention = 0
}

@Observable
final class PartsViewModel {
    var searchText = ""

    /// Активные детали по категориям в порядке `RepairCategory`, внутри — самые изношенные сверху
    func groups(_ parts: [Part], mileage: Int) -> [PartGroup] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let active = parts.filter { part in
            part.isActive && (query.isEmpty
                || part.name.lowercased().contains(query)
                || part.manufacturer.lowercased().contains(query)
                || part.articleNumber.lowercased().contains(query))
        }
        let byCategory = Dictionary(grouping: active, by: \.category)
        return RepairCategory.allCases.compactMap { category in
            guard let items = byCategory[category], !items.isEmpty else { return nil }
            let sorted = items.sorted { $0.progress(currentMileage: mileage) > $1.progress(currentMileage: mileage) }
            return PartGroup(category: category, parts: sorted)
        }
    }

    func summary(_ parts: [Part], mileage: Int) -> PartsSummary {
        let statuses = parts.filter(\.isActive).map { $0.status(currentMileage: mileage) }
        return PartsSummary(total: statuses.count,
                            replaceNow: statuses.filter { $0 == .overdue }.count,
                            attention: statuses.filter { $0 == .warning || $0 == .critical }.count)
    }

    @MainActor
    func update(_ part: Part, with draft: PartDraft, context: ModelContext) {
        draft.apply(to: part)
        NotificationService.shared.schedule(part)
        try? context.save()
    }

    @MainActor
    func delete(_ part: Part, context: ModelContext) {
        DataService.delete(part, in: context)
        try? context.save()
    }
}
