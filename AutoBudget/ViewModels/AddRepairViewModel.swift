import Foundation
import Observation
import SwiftData

@Observable
final class AddRepairViewModel {
    private let existing: RepairRecord?

    var title: String
    var category: RepairCategory
    var date: Date
    var mileageText: String
    var worksDone: String
    var partsUsed: String
    var laborText: String
    var partsText: String
    var shop: String
    var comment: String
    var photoBefore: Data?
    var photoAfter: Data?

    /// Заменённые детали с отслеживанием ресурса
    private(set) var partDrafts: [PartDraft]
    /// Сохранённые детали, убранные из ремонта при редактировании
    private var removedParts: [Part] = []
    /// Деталь, открытая в форме (новая или существующая)
    var editingPart: PartDraft?

    var isEditing: Bool { existing != nil }

    init(repair: RepairRecord? = nil, currentMileage: Int = 0) {
        existing = repair
        title = repair?.title ?? ""
        category = repair?.category ?? .engine
        date = repair?.date ?? .now
        let mileage = repair?.mileage ?? currentMileage
        mileageText = mileage > 0 ? String(mileage) : ""
        worksDone = repair?.worksDone ?? ""
        partsUsed = repair?.partsUsed ?? ""
        laborText = repair.map { Formatters.integer.string(from: NSNumber(value: $0.laborCost)) ?? "" } ?? ""
        partsText = repair.map { Formatters.integer.string(from: NSNumber(value: $0.partsCost)) ?? "" } ?? ""
        shop = repair?.shop ?? ""
        comment = repair?.comment ?? ""
        photoBefore = repair?.photoBefore
        photoAfter = repair?.photoAfter
        partDrafts = repair?.sortedParts.map(PartDraft.init(part:)) ?? []
    }

    var laborCost: Double { Formatters.parseNumber(laborText) ?? 0 }
    var partsCost: Double { Formatters.parseNumber(partsText) ?? 0 }
    var total: Double { laborCost + partsCost }
    var mileage: Int { Int(Formatters.parseNumber(mileageText) ?? 0) }

    /// Сумма цен заменённых деталей — подсказка для поля «Стоимость запчастей»
    var partDraftsTotal: Double { partDrafts.reduce(0) { $0 + $1.price } }

    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Детали

    func newPartDraft() -> PartDraft { PartDraft(category: category) }

    func upsert(_ draft: PartDraft) {
        if let index = partDrafts.firstIndex(where: { $0.id == draft.id }) {
            partDrafts[index] = draft
        } else {
            partDrafts.append(draft)
        }
    }

    func remove(_ draft: PartDraft) {
        partDrafts.removeAll { $0.id == draft.id }
        if let part = draft.part { removedParts.append(part) }
    }

    // MARK: - Сохранение

    @MainActor
    func save(in context: ModelContext) {
        guard isValid else { return }
        let repair: RepairRecord
        if let existing {
            repair = existing
        } else {
            repair = RepairRecord(title: "", category: category, date: date, mileage: mileage)
            context.insert(repair)
        }
        repair.title = title.trimmingCharacters(in: .whitespaces)
        repair.category = category
        repair.date = date
        repair.mileage = mileage
        repair.worksDone = worksDone
        repair.partsUsed = partsUsed
        repair.laborCost = laborCost
        repair.partsCost = partsCost
        repair.shop = shop
        repair.comment = comment
        repair.photoBefore = photoBefore
        repair.photoAfter = photoAfter

        saveParts(drafts: partDrafts, for: repair, in: context)
        DataService.syncExpense(for: repair, in: context)
        DataService.updateMileage(to: mileage, in: context)
        try? context.save()
    }

    /// Детали наследуют дату и пробег ремонта; новые ставятся на учёт и заменяют предыдущие на той же позиции
    @MainActor
    private func saveParts(drafts: [PartDraft], for repair: RepairRecord, in context: ModelContext) {
        removedParts.forEach { DataService.delete($0, in: context) }
        removedParts.removeAll()

        for draft in drafts {
            let part = draft.part ?? Part(name: draft.name, category: draft.category)
            draft.apply(to: part)
            part.installDate = repair.date
            part.installMileage = repair.mileage
            if draft.part == nil {
                context.insert(part)
                part.repair = repair
                DataService.registerInstallation(of: part, in: context)
            } else {
                NotificationService.shared.schedule(part)
            }
        }
    }
}
