import SwiftData
import SwiftUI

@main
struct AutoBudgetApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Car.self, Expense.self, RepairRecord.self, Reminder.self, Part.self)
        } catch {
            fatalError("Не удалось создать хранилище SwiftData: \(error)")
        }
        Self.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
                .environment(\.locale, Formatters.locale)
        }
        .modelContainer(container)
    }

    private static func configureAppearance() {
        let accent = UIColor(Theme.accent)
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = {
            let a = UINavigationBarAppearance()
            a.configureWithDefaultBackground()
            a.backgroundEffect = UIBlurEffect(style: .systemChromeMaterialDark)
            a.titleTextAttributes = [.foregroundColor: UIColor.white]
            a.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            return a
        }()
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UISegmentedControl.appearance().selectedSegmentTintColor = accent
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
    }
}
