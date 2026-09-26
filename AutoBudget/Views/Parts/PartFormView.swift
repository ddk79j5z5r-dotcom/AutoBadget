import SwiftUI

/// Bottom Sheet детали: новая деталь в ремонте или редактирование существующей
struct PartFormView: View {
    let onSave: (PartDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: PartDraft

    init(draft: PartDraft, onSave: @escaping (PartDraft) -> Void) {
        _draft = State(initialValue: draft)
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: draft.part == nil ? "Новая деталь" : "Деталь") { dismiss() }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if draft.part == nil { templates.padding(.bottom, 6) }

                    FieldRow(label: "Название") {
                        TextField("", text: $draft.name, prompt: Text("Передние колодки").foregroundStyle(Theme.textTertiary))
                            .multilineTextAlignment(.trailing)
                    }
                    FieldRow(label: "Категория") {
                        Picker("Категория", selection: $draft.category) {
                            ForEach(RepairCategory.allCases) { category in
                                Label(category.title, systemImage: category.symbol).tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.accent)
                    }
                    FieldRow(label: "Производитель") {
                        TextField("", text: $draft.manufacturer, prompt: Text("Akebono").foregroundStyle(Theme.textTertiary))
                            .multilineTextAlignment(.trailing)
                    }
                    FieldRow(label: "Артикул") {
                        TextField("", text: $draft.articleNumber, prompt: Text("AN-690WK").foregroundStyle(Theme.textTertiary))
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                    }

                    Text("Ресурс — укажите пробег, срок или оба значения")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.leading, 4)
                        .padding(.top, 6)
                    FieldRow(label: "По пробегу") {
                        TextField("", text: $draft.lifeKmText, prompt: Text("30000").foregroundStyle(Theme.textTertiary))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("км").foregroundStyle(Theme.textSecondary)
                    }
                    FieldRow(label: "По времени") {
                        TextField("", text: $draft.lifeMonthsText, prompt: Text("—").foregroundStyle(Theme.textTertiary))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("мес.").foregroundStyle(Theme.textSecondary)
                    }
                    FieldRow(label: "Цена") {
                        TextField("", text: $draft.priceText, prompt: Text("0").foregroundStyle(Theme.textTertiary))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("₽").foregroundStyle(Theme.textSecondary)
                    }

                    Text("Заметки")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.leading, 4)
                        .padding(.top, 6)
                    TextField("", text: $draft.notes,
                              prompt: Text("Например: оригинал, гарантия 1 год").foregroundStyle(Theme.textTertiary),
                              axis: .vertical)
                        .lineLimit(2...5)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(14)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous).strokeBorder(Theme.stroke))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            Button("Сохранить") {
                onSave(draft)
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle(enabled: draft.isValid))
            .disabled(!draft.isValid)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .background(Theme.background)
    }

    /// Типовые детали с рекомендуемым ресурсом
    private var templates: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ТИПОВЫЕ ДЕТАЛИ")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textTertiary)
                .padding(.leading, 4)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(PartTemplate.catalog) { template in
                        FilterChip(title: template.name, isSelected: draft.name == template.name) {
                            withAnimation(Theme.snappy) { draft.apply(template) }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }
}
