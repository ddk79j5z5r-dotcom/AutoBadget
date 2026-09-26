import SwiftData
import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case dashboard, expenses, statistics, garage

    var title: String {
        switch self {
        case .dashboard: "Главная"
        case .expenses: "Расходы"
        case .statistics: "Статистика"
        case .garage: "Гараж"
        }
    }

    var symbol: String {
        switch self {
        case .dashboard: "house.fill"
        case .expenses: "list.bullet.rectangle.portrait"
        case .statistics: "chart.bar.fill"
        case .garage: "car.fill"
        }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Car.createdAt) private var cars: [Car]
    @State private var selection: AppTab = .dashboard
    @State private var showAddExpense = false

    var body: some View {
        // Все вкладки живут одновременно — сохраняются стеки навигации и позиции прокрутки
        ZStack {
            tab(.dashboard) { DashboardView(selectedTab: $selection) }
            tab(.expenses) { ExpensesView() }
            tab(.statistics) { StatisticsView() }
            tab(.garage) { CarView() }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppTabBar(selection: $selection) { showAddExpense = true }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView(currentMileage: cars.first?.mileage ?? 0)
                .autoSheetStyle()
        }
        .task {
            DemoDataService.seedIfNeeded(context)
            if await NotificationService.shared.authorizationStatus() == .authorized {
                NotificationService.shared.rescheduleAll(DataService.trackedItems(in: context))
            }
        }
    }

    private func tab<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        let active = selection == tab
        return content()
            .opacity(active ? 1 : 0)
            .allowsHitTesting(active)
            .accessibilityHidden(!active)
    }
}

/// Нижняя панель как в референсе: 4 вкладки и круглая кнопка «+» по центру
struct AppTabBar: View {
    @Binding var selection: AppTab
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            item(.dashboard)
            item(.expenses)
            addButton
            item(.statistics)
            item(.garage)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .background {
            Theme.background.opacity(0.92)
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) { Divider().overlay(Theme.stroke) }
                .ignoresSafeArea()
        }
    }

    private func item(_ tab: AppTab) -> some View {
        let active = selection == tab
        return Button {
            if !active { UISelectionFeedbackGenerator().selectionChanged() }
            withAnimation(Theme.snappy) { selection = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 19, weight: .semibold))
                    .scaleEffect(active ? 1.08 : 1)
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(active ? Theme.accent : Theme.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    private var addButton: some View {
        Button(action: onAdd) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 50, height: 50)
                .background(Theme.cardElevated, in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
                .shadow(color: .black.opacity(0.5), radius: 8, y: 3)
        }
        .buttonStyle(PressableStyle())
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Добавить расход")
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Car.self, Expense.self, RepairRecord.self, Reminder.self, Part.self], inMemory: true)
        .preferredColorScheme(.dark)
}
