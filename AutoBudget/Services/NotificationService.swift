import Foundation
import UserNotifications

/// Локальные уведомления по регламентным работам и ресурсу деталей.
/// Поддерживаются три сценария:
/// - по времени — календарное уведомление за `notifyDaysBefore` дней до срока;
/// - по пробегу — при обновлении пробега, когда остаток пересекает порог «Скоро», «Срочно» или ноль;
/// - по ресурсу детали — детали реализуют тот же `ServiceLifeTracked`, поэтому работают оба сценария выше.
@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    // MARK: - По времени

    /// Планирует уведомление за `notifyDaysBefore` дней до срока (в 10:00)
    func schedule(_ item: any ServiceLifeTracked) {
        cancel(item)
        guard item.notificationsActive, let due = item.nextDate else { return }

        let cal = Calendar.current
        var fireDate = cal.date(byAdding: .day, value: -item.notifyDaysBefore, to: due) ?? due
        fireDate = cal.date(bySettingHour: 10, minute: 0, second: 0, of: fireDate) ?? fireDate
        if fireDate <= .now {
            // Срок уже близко — напомним в день окончания, если он ещё не прошёл
            guard let dueMorning = cal.date(bySettingHour: 10, minute: 0, second: 0, of: due), dueMorning > .now else { return }
            fireDate = dueMorning
        }

        let daysLeft = cal.dateComponents([.day], from: cal.startOfDay(for: fireDate), to: cal.startOfDay(for: due)).day ?? 0
        let content = UNMutableNotificationContent()
        content.title = "AutoBudget · \(item.trackingTitle)"
        content.body = daysLeft > 0
            ? "Через \(Plural.days(daysLeft)) истекает срок: \(item.trackingTitle.lowercased()). Срок — \(due.ruShort)."
            : "Сегодня истекает срок: \(item.trackingTitle.lowercased())."
        content.sound = .default

        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: item.notificationID, content: content, trigger: trigger))
    }

    func cancel(_ item: any ServiceLifeTracked) {
        center.removePendingNotificationRequests(withIdentifiers: [item.notificationID])
    }

    func rescheduleAll(_ items: [any ServiceLifeTracked]) {
        items.forEach(schedule)
    }

    // MARK: - По пробегу

    /// Уведомляет, если после изменения пробега остаток ресурса пересёк порог.
    /// Повторно при следующих обновлениях пробега не срабатывает — только в момент пересечения.
    func notifyMileageThresholds(_ items: [any ServiceLifeTracked], from oldMileage: Int, to newMileage: Int) {
        guard newMileage > oldMileage else { return }
        for item in items where item.notificationsActive {
            guard let before = item.remainingKm(currentMileage: oldMileage),
                  let after = item.remainingKm(currentMileage: newMileage) else { continue }
            // Самый строгий из пересечённых порогов
            guard let crossed = [0, item.criticalKm, item.warningKm].first(where: { before > $0 && after <= $0 }) else { continue }

            let content = UNMutableNotificationContent()
            content.title = "AutoBudget · \(item.trackingTitle)"
            content.body = crossed == 0
                ? "\(item.overdueTitle): \(item.trackingTitle.lowercased()). Ресурс исчерпан."
                : "Через \(after.km) потребуется: \(item.trackingTitle.lowercased())."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
            center.add(UNNotificationRequest(identifier: "mileage-\(item.notificationID)",
                                             content: content, trigger: trigger))
        }
    }
}
