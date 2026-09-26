import Foundation
import SwiftData

/// Операции, затрагивающие несколько моделей сразу
@MainActor
enum DataService {
    static func car(in context: ModelContext) -> Car? {
        var descriptor = FetchDescriptor<Car>(sortBy: [SortDescriptor(\.createdAt)])
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    // MARK: - Пробег

    /// Единая точка изменения пробега: обновляет автомобиль и отправляет уведомления о пересечённых порогах.
    /// - Parameter onlyIncrease: true — для записей расходов и ремонтов (старая запись не должна «откатить» пробег)
    static func updateMileage(to mileage: Int, in context: ModelContext, onlyIncrease: Bool = true) {
        guard let car = car(in: context), mileage > 0, mileage != car.mileage else { return }
        guard !onlyIncrease || mileage > car.mileage else { return }
        let oldMileage = car.mileage
        car.mileage = mileage
        NotificationService.shared.notifyMileageThresholds(trackedItems(in: context), from: oldMileage, to: mileage)
    }

    // MARK: - Ресурс

    static func activeParts(in context: ModelContext) -> [Part] {
        (try? context.fetch(FetchDescriptor<Part>(predicate: #Predicate { $0.isActive == true }))) ?? []
    }

    /// Всё, что отслеживается по ресурсу: регламентные работы и установленные детали
    static func trackedItems(in context: ModelContext) -> [any ServiceLifeTracked] {
        let reminders: [any ServiceLifeTracked] = (try? context.fetch(FetchDescriptor<Reminder>())) ?? []
        return reminders + activeParts(in: context)
    }

    /// Ставит новую деталь на учёт: ранее установленная деталь на той же позиции
    /// снимается с учёта и связывается с новой в историю замен.
    static func registerInstallation(of part: Part, in context: ModelContext) {
        let previous = activeParts(in: context)
            .filter { $0 !== part && $0.isSamePosition(as: part) && $0.installDate <= part.installDate }
            .max { $0.installDate < $1.installDate }
        if let previous {
            previous.markRemoved(date: part.installDate, mileage: part.installMileage)
            part.replaces = previous
            NotificationService.shared.cancel(previous)
        }
        NotificationService.shared.schedule(part)
    }

    /// Удаляет деталь; если она заменила другую — предыдущая снова становится активной
    static func delete(_ part: Part, in context: ModelContext) {
        if part.isActive, let previous = part.replaces {
            previous.restore()
            NotificationService.shared.schedule(previous)
        }
        NotificationService.shared.cancel(part)
        context.delete(part)
    }

    // MARK: - Ремонт ⇄ бюджет

    static func linkedExpense(for repair: RepairRecord, in context: ModelContext) -> Expense? {
        let id: UUID? = repair.uid
        let descriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.repairID == id })
        return try? context.fetch(descriptor).first
    }

    /// Каждый ремонт автоматически попадает в бюджет как расход (и обновляется вместе с ним)
    static func syncExpense(for repair: RepairRecord, in context: ModelContext) {
        let place = repair.shop
        let comment = [repair.worksDone, repair.comment].filter { !$0.isEmpty }.joined(separator: "\n")
        if let expense = linkedExpense(for: repair, in: context) {
            expense.title = repair.title
            expense.category = repair.category.expenseCategory
            expense.date = repair.date
            expense.amount = repair.totalCost
            expense.mileage = repair.mileage
            expense.place = place
            expense.comment = comment
        } else if repair.totalCost > 0 {
            context.insert(Expense(category: repair.category.expenseCategory,
                                   title: repair.title,
                                   date: repair.date,
                                   amount: repair.totalCost,
                                   mileage: repair.mileage,
                                   comment: comment,
                                   place: place,
                                   repairID: repair.uid))
        }
    }

    static func delete(_ repair: RepairRecord, in context: ModelContext) {
        repair.sortedParts.forEach { delete($0, in: context) }
        if let expense = linkedExpense(for: repair, in: context) {
            context.delete(expense)
        }
        context.delete(repair)
    }

    static func deleteAll(in context: ModelContext) {
        trackedItems(in: context).forEach(NotificationService.shared.cancel)
        try? context.delete(model: Part.self)
        try? context.delete(model: Expense.self)
        try? context.delete(model: RepairRecord.self)
        try? context.delete(model: Reminder.self)
        try? context.delete(model: Car.self)
        try? context.save()
    }
}
