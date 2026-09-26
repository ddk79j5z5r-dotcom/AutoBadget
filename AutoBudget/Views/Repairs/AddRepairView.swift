import PhotosUI
import SwiftData
import SwiftUI

struct AddRepairView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var vm: AddRepairViewModel
    @State private var beforeItem: PhotosPickerItem?
    @State private var afterItem: PhotosPickerItem?

    init(repair: RepairRecord? = nil, currentMileage: Int = 0) {
        _vm = State(initialValue: AddRepairViewModel(repair: repair, currentMileage: currentMileage))
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: vm.isEditing ? "Редактирование" : "Новый ремонт") { dismiss() }

            ScrollView {
                VStack(spacing: 20) {
                    FormSection(title: "Что сделано") {
                        FormRow(symbol: "wrench.and.screwdriver.fill", showDivider: false) {
                            AppTextField(placeholder: "Например: Замена топливного насоса", text: $vm.title)
                        }
                    }
                    categoryPicker
                    FormSection(title: "Когда") {
                        FormRow(symbol: "calendar") {
                            DatePicker("Дата ремонта", selection: $vm.date, displayedComponents: .date)
                                .foregroundStyle(Theme.textPrimary)
                        }
                        FormRow(symbol: "gauge.with.dots.needle.50percent", showDivider: false) {
                            AppTextField(placeholder: "Пробег на момент ремонта", text: $vm.mileageText, keyboard: .numberPad)
                            Text("км").foregroundStyle(Theme.textTertiary)
                        }
                    }
                    FormSection(title: "Работы и запчасти") {
                        FormRow(symbol: "list.bullet.clipboard") {
                            AppTextField(placeholder: "Выполненные работы", text: $vm.worksDone, axis: .vertical)
                        }
                        FormRow(symbol: "shippingbox", showDivider: false) {
                            AppTextField(placeholder: "Использованные запчасти и материалы", text: $vm.partsUsed, axis: .vertical)
                        }
                    }
                    replacedPartsSection
                    costSection
                    FormSection(title: "Исполнитель") {
                        FormRow(symbol: "building.2") {
                            AppTextField(placeholder: "СТО или мастер", text: $vm.shop)
                        }
                        FormRow(symbol: "text.bubble", showDivider: false) {
                            AppTextField(placeholder: "Комментарий", text: $vm.comment, axis: .vertical)
                        }
                    }
                    photosSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            Button("Сохранить") {
                vm.save(in: context)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle(enabled: vm.isValid))
            .disabled(!vm.isValid)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 8)
        }
        .background(Theme.background)
        .sheet(item: $vm.editingPart) { draft in
            PartFormView(draft: draft) { vm.upsert($0) }
                .autoSheetStyle()
        }
        .onChange(of: beforeItem) { _, item in
            Task { if let data = await ImageService.loadJPEG(from: item) { vm.photoBefore = data } }
        }
        .onChange(of: afterItem) { _, item in
            Task { if let data = await ImageService.loadJPEG(from: item) { vm.photoAfter = data } }
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("КАТЕГОРИЯ")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textTertiary)
                .padding(.leading, 4)
            TileGrid(items: RepairCategory.allCases, columns: 4, spacing: 10) { category in
                    let selected = vm.category == category
                    Button {
                        withAnimation(Theme.snappy) { vm.category = category }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: category.symbol)
                                .font(.title3)
                                .foregroundStyle(category.color)
                            Text(category.title)
                                .font(.caption2.weight(.medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .foregroundStyle(selected ? Theme.textPrimary : Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 68)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selected ? category.color.opacity(0.2) : Theme.card))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(selected ? category.color : Theme.stroke, lineWidth: selected ? 1.5 : 1))
                    }
                    .buttonStyle(PressableStyle())
            }
        }
    }

    // MARK: Заменённые детали

    private var replacedPartsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ЗАМЕНЁННЫЕ ДЕТАЛИ")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textTertiary)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                ForEach(vm.partDrafts) { draft in
                    HStack(spacing: 12) {
                        Image(systemName: draft.category.symbol)
                            .font(.body.weight(.medium))
                            .foregroundStyle(draft.category.color)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(draft.name)
                                .foregroundStyle(Theme.textPrimary)
                            Text([draft.manufacturer, "ресурс \(draft.resourceDescription)"]
                                .filter { !$0.isEmpty }
                                .joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Spacer()
                        if draft.price > 0 {
                            Text(draft.price.rub)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Button {
                            withAnimation(Theme.spring) { vm.remove(draft) }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(Theme.danger)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Убрать деталь")
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 58)
                    .contentShape(Rectangle())
                    .onTapGesture { vm.editingPart = draft }
                    Divider().overlay(Theme.stroke).padding(.leading, 52)
                }
                Button {
                    vm.editingPart = vm.newPartDraft()
                } label: {
                    Label("Добавить деталь", systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                }
                .buttonStyle(.plain)
            }
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous).strokeBorder(Theme.stroke))
            Text("Для каждой детали будет отслеживаться ресурс. Ранее установленная деталь с тем же названием снимается с учёта и попадает в историю замен.")
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
                .padding(.horizontal, 4)
        }
        .animation(Theme.spring, value: vm.partDrafts.map(\.id))
    }

    private var costSection: some View {
        FormSection(title: "Стоимость") {
            FormRow(symbol: "person.fill.checkmark") {
                AppTextField(placeholder: "Стоимость работ", text: $vm.laborText, keyboard: .decimalPad)
                Text("₽").foregroundStyle(Theme.textTertiary)
            }
            FormRow(symbol: "shippingbox.fill") {
                AppTextField(placeholder: "Стоимость запчастей", text: $vm.partsText, keyboard: .decimalPad)
                if vm.partDraftsTotal > 0 && vm.partsCost == 0 {
                    // Подсказка: подставить сумму цен заменённых деталей
                    Button("= \(vm.partDraftsTotal.rub)") {
                        vm.partsText = Formatters.integer.string(from: NSNumber(value: vm.partDraftsTotal)) ?? ""
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                }
                Text("₽").foregroundStyle(Theme.textTertiary)
            }
            FormRow(symbol: "sum", showDivider: false) {
                Text("Общая стоимость")
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(vm.total.rub)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.accent)
                    .contentTransition(.numericText())
                    .animation(Theme.snappy, value: vm.total)
            }
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ФОТО")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textTertiary)
                .padding(.leading, 4)
            HStack(spacing: 12) {
                photoPicker(title: "До ремонта", data: vm.photoBefore, selection: $beforeItem) { vm.photoBefore = nil }
                photoPicker(title: "После ремонта", data: vm.photoAfter, selection: $afterItem) { vm.photoAfter = nil }
            }
        }
    }

    private func photoPicker(title: String, data: Data?, selection: Binding<PhotosPickerItem?>,
                             onRemove: @escaping () -> Void) -> some View {
        PhotosPicker(selection: selection, matching: .images) {
            ZStack {
                if let data, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.accent)
                        Text(title)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .strokeBorder(data == nil ? Theme.accent.opacity(0.35) : Theme.stroke,
                                  style: StrokeStyle(lineWidth: 1, dash: data == nil ? [6, 4] : []))
            )
        }
        .overlay(alignment: .topTrailing) {
            if data != nil {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.6))
                }
                .padding(6)
            }
        }
    }
}
