import SwiftData
import SwiftUI

struct PartDetailView: View {
    let part: Part

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Car.createdAt) private var cars: [Car]
    @State private var vm = PartsViewModel()
    @State private var editingDraft: PartDraft?
    @State private var showDeleteConfirm = false

    private var mileage: Int { cars.first?.mileage ?? 0 }

    var body: some View {
        let status = part.status(currentMileage: mileage)

        ScrollView {
            VStack(spacing: 16) {
                header(status: status)
                resourceCard(status: status)
                infoCard
                if !part.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Заметки", systemImage: "text.bubble.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                        Text(part.notes)
                            .foregroundStyle(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .card()
                }
                if let repair = part.repair { repairLink(repair) }
                historyCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(ScreenBackground())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { editingDraft = PartDraft(part: part) } label: { Label("Изменить", systemImage: "pencil") }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $editingDraft) { draft in
            PartFormView(draft: draft) { vm.update(part, with: $0, context: context) }
                .autoSheetStyle()
        }
        .confirmationDialog("Удалить деталь?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                vm.delete(part, context: context)
                dismiss()
            }
        } message: {
            Text(part.replaces != nil && part.isActive
                 ? "Предыдущая деталь на этой позиции снова станет активной."
                 : "Деталь будет удалена из ремонта и истории.")
        }
    }

    // MARK: Header

    private func header(status: ServiceStatus) -> some View {
        VStack(spacing: 10) {
            SymbolBadge(symbol: part.category.symbol, color: status.color, size: 64)
            Text(part.name)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                StatusPill(text: part.category.title, color: part.category.color)
                if part.isActive {
                    StatusPill(text: part.statusTitle(currentMileage: mileage), color: status.color)
                } else {
                    StatusPill(text: "Снята", color: Theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: Resource

    private func resourceCard(status: ServiceStatus) -> some View {
        // Для снятой детали ресурс считается на момент снятия
        let atMileage = part.removedMileage ?? mileage
        let atDate = part.removedDate ?? .now
        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(part.isActive ? "Остаток ресурса" : "Прослужила")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Text(part.isActive ? remainingHeadline(status: status) : (part.servedKm?.km ?? "—"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(part.isActive ? status.color : Theme.textPrimary)
                    .contentTransition(.numericText())
            }
            ProgressBar(value: part.progress(currentMileage: atMileage, now: atDate),
                        tint: part.isActive ? status.color : Theme.textTertiary,
                        height: 10)
            HStack {
                metric("Пройдено", part.traveledKm(currentMileage: atMileage).km)
                Spacer()
                metric("Ресурс", part.resourceDescription, alignment: .trailing)
            }
        }
        .card(padding: 18)
    }

    private func remainingHeadline(status: ServiceStatus) -> String {
        if status == .overdue { return part.overdueTitle }
        if let km = part.remainingKm(currentMileage: mileage) { return km.km }
        if let days = part.remainingDays() { return Plural.days(days) }
        return "—"
    }

    private func metric(_ title: String, _ value: String, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    // MARK: Info

    private var infoCard: some View {
        VStack(spacing: 10) {
            InfoRow(title: "Производитель", value: part.manufacturer.isEmpty ? "—" : part.manufacturer)
            InfoRow(title: "Артикул", value: part.articleNumber.isEmpty ? "—" : part.articleNumber)
            Divider().overlay(Theme.stroke)
            InfoRow(title: "Дата установки", value: part.installDate.ruShort)
            InfoRow(title: "Пробег установки", value: part.installMileage.km)
            InfoRow(title: "Ресурс", value: part.resourceDescription)
            if part.isActive {
                InfoRow(title: "Текущий пробег", value: mileage.km)
                InfoRow(title: "Остаток", value: remainingHeadline(status: part.status(currentMileage: mileage)))
                InfoRow(title: "Следующая замена", value: part.nextServiceDescription)
            } else if let removedDate = part.removedDate {
                InfoRow(title: "Снята", value: "\(removedDate.ruShort) · \((part.removedMileage ?? 0).km)")
            }
            if part.purchasePrice > 0 {
                Divider().overlay(Theme.stroke)
                InfoRow(title: "Цена", value: part.purchasePrice.rub)
            }
        }
        .card()
    }

    // MARK: Repair

    private func repairLink(_ repair: RepairRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Связанный ремонт")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            NavigationLink(value: repair) {
                HStack(spacing: 12) {
                    SymbolBadge(symbol: repair.category.symbol, color: repair.category.color, size: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(repair.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(repair.date.ruShort) · \(repair.shop.isEmpty ? repair.mileage.km : repair.shop)")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Text(repair.totalCost.rub)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.textTertiary)
                }
                .card(padding: 14)
            }
            .buttonStyle(PressableStyle())
        }
    }

    // MARK: History

    private var historyCard: some View {
        let history = part.replacementHistory
        return VStack(alignment: .leading, spacing: 10) {
            Text("История замен")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            VStack(spacing: 0) {
                ForEach(Array(history.enumerated()), id: \.element.persistentModelID) { index, item in
                    Group {
                        if item === part {
                            historyRow(item, isCurrent: true)
                        } else {
                            NavigationLink(value: item) { historyRow(item, isCurrent: false) }
                                .buttonStyle(.plain)
                        }
                    }
                    if index < history.count - 1 {
                        Divider().overlay(Theme.stroke).padding(.leading, 30)
                    }
                }
                if history.count == 1 {
                    Text("Это первая деталь на этой позиции. При следующей замене здесь появится история.")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, 6)
                }
            }
            .card()
        }
    }

    private func historyRow(_ item: Part, isCurrent: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(item.isActive ? Theme.accent : Theme.textTertiary)
                .frame(width: 10, height: 10)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(item.installDate.ruShort) · \(item.installMileage.km)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text([item.manufacturer, item.articleNumber].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Text(item.isActive ? "Установлена сейчас" : "Прослужила \(item.servedKm?.km ?? "—")")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(item.isActive ? Theme.accent : Theme.textTertiary)
            }
            Spacer()
            if !isCurrent {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
