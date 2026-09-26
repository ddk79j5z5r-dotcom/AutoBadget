import Foundation
import SwiftData

@Model
final class Expense {
    var uid: UUID
    var categoryRaw: String
    var title: String
    var date: Date
    var amount: Double
    var mileage: Int
    var comment: String
    var place: String
    /// Объём заправки в литрах — используется для расчёта среднего расхода топлива
    var liters: Double?
    /// Тип топлива — только для заправок; nil у расходов других категорий
    var fuelTypeRaw: String?
    /// Если расход создан из записи ремонта — ссылка на неё
    var repairID: UUID?

    init(category: ExpenseCategory,
         title: String,
         date: Date,
         amount: Double,
         mileage: Int,
         comment: String = "",
         place: String = "",
         liters: Double? = nil,
         fuelType: FuelType? = nil,
         repairID: UUID? = nil) {
        self.uid = UUID()
        self.categoryRaw = category.rawValue
        self.title = title
        self.date = date
        self.amount = amount
        self.mileage = mileage
        self.comment = comment
        self.place = place
        self.liters = liters
        self.fuelTypeRaw = fuelType?.rawValue
        self.repairID = repairID
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .fuel }
        set { categoryRaw = newValue.rawValue }
    }

    var fuelType: FuelType? {
        get { fuelTypeRaw.flatMap(FuelType.init(rawValue:)) }
        set { fuelTypeRaw = newValue?.rawValue }
    }

    /// Цена литра выводится из суммы и объёма — хранить её отдельно значит рисковать рассинхроном
    var pricePerLiter: Double? {
        guard let liters, liters > 0 else { return nil }
        return amount / liters
    }
}
