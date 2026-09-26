import Foundation
import Observation
import SwiftData

@Observable
final class AddExpenseViewModel {
    private let existing: Expense?

    var category: ExpenseCategory {
        didSet {
            // Подставляем название по умолчанию, если пользователь его не менял
            if title.isEmpty || title == oldValue.defaultTitle {
                title = category.defaultTitle
            }
        }
    }
    var title: String
    var date: Date
    var amountText: String
    var mileageText: String
    var comment: String
    /// Место покупки; для заправки — название АЗС
    var place: String

    // MARK: Заправка
    var fuelType: FuelType
    var litersText: String {
        didSet { recalculateAmount() }
    }
    var pricePerLiterText: String {
        didSet { recalculateAmount() }
    }

    var isEditing: Bool { existing != nil }
    var isLinkedToRepair: Bool { existing?.repairID != nil }
    var isFuel: Bool { category == .fuel }

    init(expense: Expense? = nil, preset: ExpenseCategory? = nil, currentMileage: Int = 0) {
        existing = expense
        let cat = expense?.category ?? preset ?? .fuel
        category = cat
        title = expense?.title ?? cat.defaultTitle
        date = expense?.date ?? .now
        amountText = expense.map { Formatters.integer.string(from: NSNumber(value: $0.amount)) ?? "" } ?? ""
        let mileage = expense?.mileage ?? currentMileage
        mileageText = mileage > 0 ? String(mileage) : ""
        comment = expense?.comment ?? ""
        place = expense?.place ?? ""
        fuelType = expense?.fuelType ?? .ai95
        litersText = expense?.liters.map { $0.oneDecimal } ?? ""
        pricePerLiterText = expense?.pricePerLiter.map { String(format: "%.2f", $0).replacingOccurrences(of: ".", with: ",") } ?? ""
    }

    var amount: Double? { Formatters.parseNumber(amountText) }
    var mileage: Int { Int(Formatters.parseNumber(mileageText) ?? 0) }
    var liters: Double? { isFuel ? Formatters.parseNumber(litersText) : nil }
    var pricePerLiter: Double? { isFuel ? Formatters.parseNumber(pricePerLiterText) : nil }

    var isValid: Bool {
        (amount ?? 0) > 0 && !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Литры × цена за литр → сумма. Сумму можно поправить вручную (скидки, округление на АЗС).
    private func recalculateAmount() {
        guard let liters, let pricePerLiter, liters > 0, pricePerLiter > 0 else { return }
        amountText = Formatters.integer.string(from: NSNumber(value: (liters * pricePerLiter).rounded())) ?? amountText
    }

    @MainActor
    func save(in context: ModelContext) {
        guard let amount, isValid else { return }
        let cleanTitle = title.trimmingCharacters(in: .whitespaces)
        let expense: Expense
        if let existing {
            expense = existing
        } else {
            expense = Expense(category: category, title: cleanTitle, date: date, amount: amount, mileage: mileage)
            context.insert(expense)
        }
        expense.category = category
        expense.title = cleanTitle
        expense.date = date
        expense.amount = amount
        expense.mileage = mileage
        expense.comment = comment
        expense.place = place
        expense.liters = liters
        expense.fuelType = isFuel ? fuelType : nil

        DataService.updateMileage(to: mileage, in: context)
        try? context.save()
    }

    @MainActor
    func delete(in context: ModelContext) {
        guard let existing else { return }
        context.delete(existing)
        try? context.save()
    }
}
