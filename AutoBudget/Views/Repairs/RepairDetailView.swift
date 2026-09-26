import SwiftData
import SwiftUI

struct RepairDetailView: View {
    let repair: RepairRecord

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Car.createdAt) private var cars: [Car]
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var fullscreenPhoto: PhotoItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                costCard
                if !repair.worksDone.isEmpty {
                    textCard(title: "Выполненные работы", symbol: "wrench.adjustable.fill", text: repair.worksDone)
                }
                if !repair.sortedParts.isEmpty {
                    partsCard
                }
                if !repair.partsUsed.isEmpty {
                    textCard(title: "Использованные запчасти", symbol: "shippingbox.fill", text: repair.partsUsed)
                }
                infoCard
                if repair.photoBefore != nil || repair.photoAfter != nil {
                    photosCard
                }
                if !repair.comment.isEmpty {
                    textCard(title: "Комментарий", symbol: "text.bubble.fill", text: repair.comment)
                }
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
                    Button { showEdit = true } label: { Label("Изменить", systemImage: "pencil") }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            AddRepairView(repair: repair).autoSheetStyle()
        }
        .fullScreenCover(item: $fullscreenPhoto) { item in
            PhotoViewer(item: item)
        }
        .confirmationDialog("Удалить запись о ремонте?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                DataService.delete(repair, in: context)
                try? context.save()
                dismiss()
            }
        } message: {
            Text("Связанный расход и заменённые детали тоже будут удалены.")
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            SymbolBadge(symbol: repair.category.symbol, color: repair.category.color, size: 64)
            Text(repair.title)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                StatusPill(text: repair.category.title, color: repair.category.color)
                StatusPill(text: repair.date.ruShort, color: Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var costCard: some View {
        VStack(spacing: 10) {
            InfoRow(title: "Работы", value: repair.laborCost.rub)
            InfoRow(title: "Запчасти", value: repair.partsCost.rub)
            Divider().overlay(Theme.stroke)
            HStack {
                Text("Итого").font(.headline).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(repair.totalCost.rub)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.accent)
            }
        }
        .card()
    }

    /// Заменённые детали — каждая открывается в экране ресурса
    private var partsCard: some View {
        let mileage = cars.first?.mileage ?? 0
        return VStack(alignment: .leading, spacing: 4) {
            Label("Заменённые детали", systemImage: "gearshape.2.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .padding(.bottom, 4)
            ForEach(repair.sortedParts) { part in
                NavigationLink(value: part) {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(part.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(part.isActive
                                 ? part.remainingDescription(currentMileage: mileage).capitalizedFirst
                                 : "Заменена · прослужила \(part.servedKm?.km ?? "—")")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        if part.isActive {
                            let status = part.status(currentMileage: mileage)
                            StatusPill(text: part.statusTitle(currentMileage: mileage), color: status.color)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .card()
    }

    private var infoCard: some View {
        VStack(spacing: 10) {
            InfoRow(title: "Дата", value: repair.date.ruShort)
            InfoRow(title: "Пробег", value: repair.mileage.km)
            if !repair.shop.isEmpty {
                InfoRow(title: "СТО / исполнитель", value: repair.shop)
            }
        }
        .card()
    }

    private func textCard(title: String, symbol: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
            Text(text)
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card()
    }

    private var photosCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Фото", systemImage: "photo.on.rectangle.angled")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
            HStack(spacing: 10) {
                photo(repair.photoBefore, label: "До ремонта")
                photo(repair.photoAfter, label: "После ремонта")
            }
        }
        .card()
    }

    @ViewBuilder
    private func photo(_ data: Data?, label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let data, let image = UIImage(data: data) {
                Button { fullscreenPhoto = PhotoItem(image: image, title: label) } label: {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 130)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous))
                }
                .buttonStyle(PressableStyle())
            } else {
                RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous)
                    .fill(Theme.cardElevated)
                    .frame(height: 130)
                    .overlay(Image(systemName: "photo").foregroundStyle(Theme.textTertiary))
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PhotoItem: Identifiable {
    let id = UUID()
    let image: UIImage
    let title: String
}

struct PhotoViewer: View {
    let item: PhotoItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            Image(uiImage: item.image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding()
        }
        .overlay(alignment: .bottom) {
            Text(item.title)
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
        }
    }
}
