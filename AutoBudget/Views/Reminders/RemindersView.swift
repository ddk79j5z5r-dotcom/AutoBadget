import SwiftData
import SwiftUI

struct RemindersView: View {
    @Environment(\.modelContext) private var context
    @Query private var reminders: [Reminder]
    @Query(sort: \Car.createdAt) private var cars: [Car]
    @State private var vm = RemindersViewModel()

    private var mileage: Int { cars.first?.mileage ?? 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                NotificationPermissionBanner(message: "Мы заранее напомним об ОСАГО, техосмотре и регламентных работах.")
                statusSummary
                ForEach(vm.sorted(reminders, mileage: mileage)) { reminder in
                    ReminderCard(reminder: reminder, mileage: mileage, vm: vm)
                        .onTapGesture { vm.editingReminder = reminder }
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
                if reminders.isEmpty {
                    EmptyStateView(symbol: "bell.slash", title: "Нет напоминаний", message: "Добавьте первое кнопкой «+»")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .animation(Theme.spring, value: reminders.count)
        }
        .scrollIndicators(.hidden)
        .background(ScreenBackground())
        .navigationTitle("Напоминания")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { vm.showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $vm.showAdd) {
            ReminderEditView(currentMileage: mileage).autoSheetStyle()
        }
        .sheet(item: $vm.editingReminder) { reminder in
            ReminderEditView(reminder: reminder, currentMileage: mileage).autoSheetStyle()
        }
    }

    private var statusSummary: some View {
        let statuses = reminders.map { $0.status(currentMileage: mileage) }
        return HStack(spacing: 10) {
            summaryTile(count: statuses.filter { $0 == .overdue }.count, status: .overdue)
            summaryTile(count: statuses.filter { $0 == .warning || $0 == .critical }.count, status: .warning)
            summaryTile(count: statuses.filter { $0 == .ok }.count, status: .ok)
        }
    }

    private func summaryTile(count: Int, status: ServiceStatus) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(status.color)
            Text(status.title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .card(padding: 12)
    }
}

private struct ReminderCard: View {
    let reminder: Reminder
    let mileage: Int
    let vm: RemindersViewModel
    @Environment(\.modelContext) private var context

    var body: some View {
        let status = reminder.status(currentMileage: mileage)
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                SymbolBadge(symbol: reminder.kind.symbol, color: status.color)
                VStack(alignment: .leading, spacing: 3) {
                    Text(reminder.title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(reminder.remainingDescription(currentMileage: mileage).capitalizedFirst)
                        .font(.caption)
                        .foregroundStyle(status.color)
                }
                Spacer()
                StatusPill(text: reminder.statusTitle(currentMileage: mileage), color: status.color)
            }

            ProgressBar(value: reminder.progress(currentMileage: mileage), tint: status.color, height: 8)

            VStack(spacing: 6) {
                InfoRow(title: "Последний раз", value: "\(reminder.lastDate.ruShort) · \(reminder.lastMileage.km)")
                InfoRow(title: "Следующий", value: reminder.nextServiceDescription)
                InfoRow(title: "Интервал", value: reminder.resourceDescription)
            }
            .font(.caption)

            HStack(spacing: 10) {
                Button {
                    withAnimation(Theme.spring) { vm.markDone(reminder, mileage: mileage, context: context) }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } label: {
                    Label("Выполнено", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(PressableStyle())

                Button {
                    withAnimation(Theme.snappy) { vm.toggleNotifications(reminder, context: context) }
                } label: {
                    Image(systemName: reminder.notificationsEnabled ? "bell.fill" : "bell.slash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(reminder.notificationsEnabled ? Theme.accent : Theme.textTertiary)
                        .frame(width: 48, height: 40)
                        .background(Theme.cardElevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(reminder.notificationsEnabled ? "Выключить уведомления" : "Включить уведомления")
            }
        }
        .card()
        .contentShape(Rectangle())
    }
}
