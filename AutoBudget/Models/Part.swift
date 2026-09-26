import Foundation
import SwiftData

/// Установленная деталь с отслеживанием ресурса.
/// Создаётся из записи ремонта; категории совпадают с категориями ремонта (`RepairCategory`).
///
/// Текущий пробег, следующая замена по пробегу (`nextMileage`) и по дате (`nextDate`) не хранятся,
/// а вычисляются через `ServiceLifeTracked`: пробег принадлежит автомобилю, сохранённые копии устаревали бы.
@Model
final class Part {
    var uid: UUID = UUID()
    var name: String = ""
    var categoryRaw: String = RepairCategory.engine.rawValue
    var manufacturer: String = ""
    var articleNumber: String = ""
    var installDate: Date = Date.now
    var installMileage: Int = 0
    /// Ресурс по пробегу, км (0 — не учитывается)
    var serviceLifeKm: Int = 0
    /// Ресурс по времени, мес. (0 — не учитывается)
    var serviceLifeMonths: Int = 0
    var purchasePrice: Double = 0
    var notes: String = ""
    /// false — деталь снята (заменена новой) и хранится только в истории
    var isActive: Bool = true
    var removedDate: Date?
    var removedMileage: Int?

    /// Ремонт, в котором деталь установлена (обратная сторона — `RepairRecord.parts`)
    var repair: RepairRecord?

    /// Предыдущая деталь на этом месте — из цепочки строится история замен
    @Relationship(deleteRule: .nullify, inverse: \Part.replacedBy)
    var replaces: Part?
    var replacedBy: Part?

    init(name: String,
         category: RepairCategory,
         manufacturer: String = "",
         articleNumber: String = "",
         installDate: Date = .now,
         installMileage: Int = 0,
         serviceLifeKm: Int = 0,
         serviceLifeMonths: Int = 0,
         purchasePrice: Double = 0,
         notes: String = "") {
        self.uid = UUID()
        self.name = name
        self.categoryRaw = category.rawValue
        self.manufacturer = manufacturer
        self.articleNumber = articleNumber
        self.installDate = installDate
        self.installMileage = installMileage
        self.serviceLifeKm = serviceLifeKm
        self.serviceLifeMonths = serviceLifeMonths
        self.purchasePrice = purchasePrice
        self.notes = notes
    }

    var category: RepairCategory {
        get { RepairCategory(rawValue: categoryRaw) ?? .engine }
        set { categoryRaw = newValue.rawValue }
    }

    /// История замен на этом месте: от текущей детали к самой старой
    var replacementHistory: [Part] {
        var chain: [Part] = [self]
        var cursor = replaces
        while let part = cursor, !chain.contains(where: { $0 === part }) {
            chain.append(part)
            cursor = part.replaces
        }
        return chain
    }

    /// Сколько прослужила снятая деталь
    var servedKm: Int? { removedMileage.map { max(0, $0 - installMileage) } }

    /// Одна и та же позиция («Передние колодки» в «Тормозах») — для автоматической замены предыдущей детали
    func isSamePosition(as other: Part) -> Bool {
        category == other.category
            && name.trimmingCharacters(in: .whitespaces).lowercased()
                == other.name.trimmingCharacters(in: .whitespaces).lowercased()
    }

    func markRemoved(date: Date, mileage: Int) {
        isActive = false
        removedDate = date
        removedMileage = mileage
    }

    func restore() {
        isActive = true
        removedDate = nil
        removedMileage = nil
    }
}

extension Part: ServiceLifeTracked {
    var trackingTitle: String { name }
    var trackingSymbol: String { category.symbol }
    var baseMileage: Int { installMileage }
    var baseDate: Date { installDate }
    var lifeKm: Int { serviceLifeKm }
    var lifeMonths: Int { serviceLifeMonths }
    /// Для деталей предупреждаем за месяц до окончания срока службы
    var notifyDaysBefore: Int { 30 }
    var notificationsActive: Bool { isActive }
    var notificationID: String { "part-\(uid.uuidString)" }
    var overdueTitle: String { "Требуется замена" }
}
