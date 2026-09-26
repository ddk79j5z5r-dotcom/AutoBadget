import Foundation
import Observation
import SwiftData

@Observable
final class RemindersViewModel {
    var editingReminder: Reminder?
    var showAdd = false

    func sorted(_ reminders: [Reminder], mileage: Int) -> [Reminder] {
        reminders.sorted { $0.progress(currentMileage: mileage) > $1.progress(currentMileage: mileage) }
    }

    @MainActor
    func markDone(_ reminder: Reminder, mileage: Int, context: ModelContext) {
        reminder.markDone(mileage: mileage)
        NotificationService.shared.schedule(reminder)
        try? context.save()
    }

    @MainActor
    func toggleNotifications(_ reminder: Reminder, context: ModelContext) {
        reminder.notificationsEnabled.toggle()
        NotificationService.shared.schedule(reminder)
        try? context.save()
    }
}

@Observable
final class ReminderEditViewModel {
    private let existing: Reminder?

    var kind: ReminderKind {
        didSet {
            if title.isEmpty || title == oldValue.title { title = kind.title }
            intervalKmText = kind.defaultIntervalKm.map(String.init) ?? ""
            intervalMonthsText = kind.defaultIntervalMonths.map(String.init) ?? ""
        }
    }
    var title: String
    var intervalKmText: String
    var intervalMonthsText: String
    var lastDate: Date
    var lastMileageText: String
    var notificationsEnabled: Bool
    var notifyDaysBefore: Int

    var isEditing: Bool { existing != nil }

    init(reminder: Reminder? = nil, currentMileage: Int) {
        existing = reminder
        let k = reminder?.kind ?? .custom
        kind = k
        title = reminder?.title ?? k.title
        intervalKmText = (reminder?.intervalKm ?? k.defaultIntervalKm ?? 0).nonZeroString
        intervalMonthsText = (reminder?.intervalMonths ?? k.defaultIntervalMonths ?? 0).nonZeroString
        lastDate = reminder?.lastDate ?? .now
        lastMileageText = String(reminder?.lastMileage ?? currentMileage)
        notificationsEnabled = reminder?.notificationsEnabled ?? true
        notifyDaysBefore = reminder?.notifyDaysBefore ?? 7
    }

    var intervalKm: Int { Int(Formatters.parseNumber(intervalKmText) ?? 0) }
    var intervalMonths: Int { Int(Formatters.parseNumber(intervalMonthsText) ?? 0) }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && (intervalKm > 0 || intervalMonths > 0)
    }

    @MainActor
    func save(in context: ModelContext) {
        guard isValid else { return }
        let reminder = existing ?? Reminder(kind: kind, lastDate: lastDate, lastMileage: 0)
        if existing == nil { context.insert(reminder) }
        reminder.kind = kind
        reminder.title = title.trimmingCharacters(in: .whitespaces)
        reminder.intervalKm = intervalKm
        reminder.intervalMonths = intervalMonths
        reminder.lastDate = lastDate
        reminder.lastMileage = Int(Formatters.parseNumber(lastMileageText) ?? 0)
        reminder.notificationsEnabled = notificationsEnabled
        reminder.notifyDaysBefore = notifyDaysBefore
        NotificationService.shared.schedule(reminder)
        try? context.save()
    }

    @MainActor
    func delete(in context: ModelContext) {
        guard let existing else { return }
        NotificationService.shared.cancel(existing)
        context.delete(existing)
        try? context.save()
    }
}

private extension Int {
    var nonZeroString: String { self > 0 ? String(self) : "" }
}
