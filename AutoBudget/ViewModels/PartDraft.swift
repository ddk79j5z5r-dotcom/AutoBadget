import Foundation

/// Состояние формы детали. Живёт до сохранения ремонта:
/// модели `Part` создаются только в момент сохранения, чтобы отмена формы ничего не оставляла в базе.
struct PartDraft: Identifiable {
    let id = UUID()
    /// Уже сохранённая деталь — при редактировании
    let part: Part?

    var name: String
    var category: RepairCategory
    var manufacturer: String
    var articleNumber: String
    var lifeKmText: String
    var lifeMonthsText: String
    var priceText: String
    var notes: String

    init(category: RepairCategory) {
        part = nil
        name = ""
        self.category = category
        manufacturer = ""
        articleNumber = ""
        lifeKmText = ""
        lifeMonthsText = ""
        priceText = ""
        notes = ""
    }

    init(part: Part) {
        self.part = part
        name = part.name
        category = part.category
        manufacturer = part.manufacturer
        articleNumber = part.articleNumber
        lifeKmText = part.serviceLifeKm > 0 ? String(part.serviceLifeKm) : ""
        lifeMonthsText = part.serviceLifeMonths > 0 ? String(part.serviceLifeMonths) : ""
        priceText = part.purchasePrice > 0 ? Formatters.integer.string(from: NSNumber(value: part.purchasePrice)) ?? "" : ""
        notes = part.notes
    }

    var lifeKm: Int { Int(Formatters.parseNumber(lifeKmText) ?? 0) }
    var lifeMonths: Int { Int(Formatters.parseNumber(lifeMonthsText) ?? 0) }
    var price: Double { Formatters.parseNumber(priceText) ?? 0 }

    /// Без ресурса деталь нечего отслеживать
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (lifeKm > 0 || lifeMonths > 0)
    }

    var resourceDescription: String { Formatters.resource(km: lifeKm, months: lifeMonths) }

    mutating func apply(_ template: PartTemplate) {
        name = template.name
        category = template.category
        lifeKmText = template.lifeKm > 0 ? String(template.lifeKm) : ""
        lifeMonthsText = template.lifeMonths > 0 ? String(template.lifeMonths) : ""
    }

    func apply(to part: Part) {
        part.name = name.trimmingCharacters(in: .whitespaces)
        part.category = category
        part.manufacturer = manufacturer.trimmingCharacters(in: .whitespaces)
        part.articleNumber = articleNumber.trimmingCharacters(in: .whitespaces)
        part.serviceLifeKm = lifeKm
        part.serviceLifeMonths = lifeMonths
        part.purchasePrice = price
        part.notes = notes
    }
}
