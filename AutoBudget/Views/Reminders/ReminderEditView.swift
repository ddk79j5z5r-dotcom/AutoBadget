import SwiftData
import SwiftUI

struct ReminderEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var vm: ReminderEditViewModel
    @State private var showDeleteConfirm = false

    init(reminder: Reminder? = nil, currentMileage: Int) {
        _vm = State(initialValue: ReminderEditViewModel(reminder: reminder, currentMileage: currentMileage))
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: vm.isEditing ? "Напоминание" : "Новое напоминание") { dismiss() }
            ScrollView {
                VStack(spacing: 20) {
                    kindPicker
                    FormSection(title: "Название") {
                        FormRow(symbol: "textformat", showDivider: false) {
                            AppTextField(placeholder: "Название", text: $vm.title)
                        }
                    }
                    FormSection(title: "Интервал") {
                        FormRow(symbol: "road.lanes") {
                            AppTextField(placeholder: "Каждые … км", text: $vm.intervalKmText, keyboard: .numberPad)
                            Text("км").foregroundStyle(Theme.textTertiary)
                        }
                        FormRow(symbol: "calendar", showDivider: false) {
                            AppTextField(placeholder: "Каждые … месяцев", text: $vm.intervalMonthsText, keyboard: .numberPad)
                            Text("мес.").foregroundStyle(Theme.textTertiary)
                        }
                    }
                    FormSection(title: "Последнее выполнение") {
                        FormRow(symbol: "clock.arrow.circlepath") {
                            DatePicker("Дата", selection: $vm.lastDate, displayedComponents: .date)
                                .foregroundStyle(Theme.textPrimary)
                        }
                        FormRow(symbol: "gauge.with.dots.needle.50percent", showDivider: false) {
                            AppTextField(placeholder: "Пробег", text: $vm.lastMileageText, keyboard: .numberPad)
                            Text("км").foregroundStyle(Theme.textTertiary)
                        }
                    }
                    FormSection(title: "Уведомления") {
                        FormRow(symbol: "bell.fill") {
                            Toggle("Уведомлять", isOn: $vm.notificationsEnabled)
                                .foregroundStyle(Theme.textPrimary)
                                .tint(Theme.accent)
                        }
                        FormRow(symbol: "timer", showDivider: false) {
                            Stepper(value: $vm.notifyDaysBefore, in: 1...60) {
                                Text("За \(Plural.days(vm.notifyDaysBefore))")
                                    .foregroundStyle(Theme.textPrimary)
                            }
                        }
                        .disabled(!vm.notificationsEnabled)
                        .opacity(vm.notificationsEnabled ? 1 : 0.4)
                    }
                    if vm.isEditing {
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Label("Удалить напоминание", systemImage: "trash")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Theme.danger)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Theme.danger.opacity(0.12),
                                            in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            Button("Сохранить") {
                vm.save(in: context)
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle(enabled: vm.isValid))
            .disabled(!vm.isValid)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .background(Theme.background)
        .confirmationDialog("Удалить напоминание?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                vm.delete(in: context)
                dismiss()
            }
        }
    }

    private var kindPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(ReminderKind.allCases) { kind in
                    Button {
                        withAnimation(Theme.snappy) { vm.kind = kind }
                    } label: {
                        Label(kind.title, systemImage: kind.symbol)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(vm.kind == kind ? .black : Theme.textPrimary)
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .background(Capsule().fill(vm.kind == kind ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.card)))
                            .overlay(Capsule().strokeBorder(vm.kind == kind ? .clear : Theme.stroke))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}
