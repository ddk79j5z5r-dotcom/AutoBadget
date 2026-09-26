import SwiftData
import SwiftUI

/// Bottom Sheet добавления / редактирования расхода
struct AddExpenseView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var vm: AddExpenseViewModel
    @State private var showDeleteConfirm = false
    @FocusState private var focus: Field?

    private enum Field { case amount, mileage, liters, price, title, place, comment }

    init(expense: Expense? = nil, preset: ExpenseCategory? = nil, currentMileage: Int = 0) {
        _vm = State(initialValue: AddExpenseViewModel(expense: expense, preset: preset, currentMileage: currentMileage))
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: vm.isEditing ? "Изменить расход" : "Добавить расход") { dismiss() }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    categoryGrid
                        .padding(.bottom, 8)

                    FieldRow(label: "Дата") {
                        DatePicker("", selection: $vm.date, displayedComponents: .date)
                            .labelsHidden()
                    }
                    if vm.isFuel {
                        fuelTypePicker
                        FieldRow(label: "Объём") {
                            TextField("", text: $vm.litersText, prompt: Text("0").foregroundStyle(Theme.textTertiary))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focus, equals: .liters)
                            Text("л").foregroundStyle(Theme.textSecondary)
                        }
                        FieldRow(label: "Цена за литр") {
                            TextField("", text: $vm.pricePerLiterText, prompt: Text("0").foregroundStyle(Theme.textTertiary))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focus, equals: .price)
                            Text("₽/л").foregroundStyle(Theme.textSecondary)
                        }
                    }
                    FieldRow(label: "Сумма") {
                        TextField("", text: $vm.amountText, prompt: Text("0").foregroundStyle(Theme.textTertiary))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .focused($focus, equals: .amount)
                        Text("₽").foregroundStyle(Theme.textSecondary)
                    }
                    FieldRow(label: "Пробег (км)") {
                        TextField("", text: $vm.mileageText, prompt: Text("0").foregroundStyle(Theme.textTertiary))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focus, equals: .mileage)
                    }
                    FieldRow(label: "Название") {
                        TextField("", text: $vm.title, prompt: Text("Название").foregroundStyle(Theme.textTertiary))
                            .multilineTextAlignment(.trailing)
                            .focused($focus, equals: .title)
                    }
                    FieldRow(label: vm.isFuel ? "АЗС" : "Место покупки") {
                        TextField("", text: $vm.place, prompt: Text(vm.isFuel ? "Лукойл, Shell…" : "Магазин, СТО").foregroundStyle(Theme.textTertiary))
                            .multilineTextAlignment(.trailing)
                            .focused($focus, equals: .place)
                    }

                    Text("Комментарий (необязательно)")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.leading, 4)
                        .padding(.top, 6)
                    TextField("", text: $vm.comment,
                              prompt: Text("Например: АЗС Лукойл, 95").foregroundStyle(Theme.textTertiary),
                              axis: .vertical)
                        .lineLimit(2...5)
                        .focused($focus, equals: .comment)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(14)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous).strokeBorder(Theme.stroke))

                    if vm.isEditing { deleteButton.padding(.top, 10) }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .animation(Theme.spring, value: vm.category)
            }
            .scrollDismissesKeyboard(.interactively)

            saveButton
        }
        .background(Theme.background)
        .task {
            // Фокус ставим после анимации появления шторки
            guard !vm.isEditing else { return }
            try? await Task.sleep(for: .milliseconds(450))
            focus = vm.isFuel ? .liters : .amount
        }
        .confirmationDialog("Удалить расход?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                vm.delete(in: context)
                dismiss()
            }
        }
    }

    // MARK: Category

    private var categoryGrid: some View {
        TileGrid(items: ExpenseCategory.allCases, columns: 4) { category in
                let selected = vm.category == category
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(Theme.snappy) { vm.category = category }
                } label: {
                    VStack(spacing: 8) {
                        CategoryIcon(category: category, size: 32)
                        Text(category.title)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(selected ? Theme.textPrimary : Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 78)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selected ? category.color.opacity(0.16) : Theme.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(selected ? category.color.opacity(0.9) : Theme.stroke, lineWidth: selected ? 1.5 : 1)
                    )
                }
                .buttonStyle(PressableStyle())
                .disabled(vm.isLinkedToRepair)
        }
    }

    private var fuelTypePicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(FuelType.allCases) { type in
                    FilterChip(title: type.title, isSelected: vm.fuelType == type) {
                        withAnimation(Theme.snappy) { vm.fuelType = type }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private var deleteButton: some View {
        Button(role: .destructive) { showDeleteConfirm = true } label: {
            Label("Удалить расход", systemImage: "trash")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.danger)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Theme.danger.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: Save

    private var saveButton: some View {
        Button {
            vm.save(in: context)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } label: {
            Text("Сохранить")
        }
        .buttonStyle(PrimaryButtonStyle(enabled: vm.isValid))
        .disabled(!vm.isValid)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Theme.background)
    }
}

/// Строка формы как в референсе: подпись слева, значение справа, отдельная скруглённая плашка
struct FieldRow<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize()
            Spacer(minLength: 8)
            content
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous).strokeBorder(Theme.stroke))
    }
}
