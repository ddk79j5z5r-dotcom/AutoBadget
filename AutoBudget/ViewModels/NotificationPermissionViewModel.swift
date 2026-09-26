import Foundation
import Observation
import SwiftData
import UserNotifications

/// Разрешение на уведомления — общий баннер экранов «Напоминания» и «Детали»
@Observable
final class NotificationPermissionViewModel {
    /// nil — статус ещё не получен, баннер не показываем
    var authorization: UNAuthorizationStatus?

    var needsPermission: Bool {
        authorization == .notDetermined || authorization == .denied
    }

    var isDenied: Bool { authorization == .denied }

    @MainActor
    func refresh() async {
        authorization = await NotificationService.shared.authorizationStatus()
    }

    @MainActor
    func enable(context: ModelContext) async {
        await NotificationService.shared.requestAuthorization()
        await refresh()
        if authorization == .authorized {
            NotificationService.shared.rescheduleAll(DataService.trackedItems(in: context))
        }
    }
}
