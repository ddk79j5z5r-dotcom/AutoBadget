import SwiftData
import SwiftUI

/// Просьба включить уведомления — на экранах «Напоминания» и «Детали».
/// Скрывается, когда разрешение уже выдано.
struct NotificationPermissionBanner: View {
    let message: String

    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var vm = NotificationPermissionViewModel()

    var body: some View {
        Group {
            if vm.needsPermission {
                HStack(spacing: 14) {
                    SymbolBadge(symbol: "bell.badge.fill", color: Theme.warning)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Включите уведомления")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Text(vm.isDenied ? "Уведомления запрещены. Разрешите их в Настройках iOS." : message)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Button(vm.isDenied ? "Открыть" : "Включить") {
                        if vm.isDenied {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        } else {
                            Task { await vm.enable(context: context) }
                        }
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.accent, in: Capsule())
                }
                .card()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(Theme.spring, value: vm.needsPermission)
        .task { await vm.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await vm.refresh() } }
        }
    }
}
