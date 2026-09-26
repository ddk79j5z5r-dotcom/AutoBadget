import SwiftUI

// MARK: - Card

struct CardModifier: ViewModifier {
    var padding: CGFloat = Theme.padding
    var background: Color = Theme.card

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
    }
}

extension View {
    func card(padding: CGFloat = Theme.padding, background: Color = Theme.card) -> some View {
        modifier(CardModifier(padding: padding, background: background))
    }

    /// Единый стиль нижних шторок
    func autoSheetStyle() -> some View {
        self
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
            .presentationBackground(Theme.background)
    }

    /// Плавное появление элементов при загрузке экрана
    func appear(delay: Double = 0) -> some View {
        modifier(AppearModifier(delay: delay))
    }
}

struct AppearModifier: ViewModifier {
    let delay: Double
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 14)
            .onAppear {
                withAnimation(Theme.spring.delay(delay)) { visible = true }
            }
    }
}

// MARK: - Grid

/// Неленивая сетка для небольшого числа плиток.
/// LazyVGrid внутри анимированных контейнеров иногда не отрисовывает строки — здесь все ячейки строятся сразу.
struct TileGrid<Item: Identifiable, Cell: View>: View {
    let items: [Item]
    var columns: Int
    var spacing: CGFloat = 8
    @ViewBuilder let cell: (Item) -> Cell

    private var rows: [[Item]] {
        stride(from: 0, to: items.count, by: columns).map { Array(items[$0..<min($0 + columns, items.count)]) }
    }

    var body: some View {
        Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(row) { item in
                        cell(item).frame(maxWidth: .infinity)
                    }
                    // Пустые ячейки, чтобы неполный ряд не растягивался
                    ForEach(0..<(columns - row.count), id: \.self) { _ in
                        Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                    }
                }
            }
        }
    }
}

// MARK: - Buttons

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(Theme.snappy, value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var enabled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(enabled ? .black : Theme.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .fill(enabled ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Theme.cardElevated))
            )
            .shadow(color: enabled ? Theme.accent.opacity(0.35) : .clear, radius: 16, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Theme.snappy, value: configuration.isPressed)
    }
}

// MARK: - Badges

/// Иконка категории: цветная плашка с градиентом и белым глифом
struct CategoryIcon: View {
    let category: ExpenseCategory
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                    .fill(LinearGradient(colors: [category.color, category.color.opacity(0.7)],
                                         startPoint: .top, endPoint: .bottom))
            )
            .shadow(color: category.color.opacity(0.35), radius: 6, y: 2)
    }
}

struct SymbolBadge: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.16), in: RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
    }
}

struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15), in: Capsule())
    }
}

// MARK: - Headers & tiles

struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
    }
}

struct StatTile: View {
    let title: String
    let value: String
    var symbol: String?
    var tint: Color = Theme.accent
    var footnote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
            // Всегда резервируем строку, чтобы плитки в сетке были одной высоты
            Text(footnote ?? " ")
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
        }
        .card(padding: 14)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    var valueColor: Color = Theme.textPrimary

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 12)
            Text(value)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .font(.subheadline)
    }
}

// MARK: - Filters & search

struct FilterChip: View {
    let title: String
    var emoji: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let emoji { Text(emoji) }
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? .black : Theme.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(
                Capsule().fill(isSelected ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.card))
            )
            .overlay(Capsule().strokeBorder(isSelected ? .clear : Theme.stroke))
        }
        .buttonStyle(PressableStyle())
    }
}

struct SearchField: View {
    @Binding var text: String
    var prompt: String = "Поиск"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.textTertiary)
            TextField("", text: $text, prompt: Text(prompt).foregroundStyle(Theme.textTertiary))
                .foregroundStyle(Theme.textPrimary)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    withAnimation(Theme.snappy) { text = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous).strokeBorder(Theme.stroke))
    }
}

// MARK: - Progress

struct ProgressBar: View {
    let value: Double
    var tint: Color = Theme.accent
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(tint)
                    .frame(width: max(height, geo.size.width * min(max(value, 0), 1)))
            }
        }
        .frame(height: height)
        .animation(Theme.spring, value: value)
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.accent)
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Form building blocks (bottom sheets)

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textTertiary)
                .padding(.leading, 4)
            VStack(spacing: 0) { content }
                .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous).strokeBorder(Theme.stroke))
        }
    }
}

struct FormRow<Content: View>: View {
    let symbol: String
    var showDivider = true
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 24)
                content
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 54)
            if showDivider {
                Divider().overlay(Theme.stroke).padding(.leading, 52)
            }
        }
    }
}

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var axis: Axis = .horizontal

    var body: some View {
        TextField("", text: $text,
                  prompt: Text(placeholder).foregroundStyle(Theme.textTertiary),
                  axis: axis)
            .keyboardType(keyboard)
            .foregroundStyle(Theme.textPrimary)
            .lineLimit(axis == .vertical ? 2...6 : 1...1)
            .padding(.vertical, axis == .vertical ? 14 : 0)
    }
}

struct SheetHeader: View {
    let title: String
    var onClose: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Theme.cardElevated, in: Circle())
            }
            .accessibilityLabel("Закрыть")
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }
}

/// Тёмный фон экрана с лёгким бирюзовым свечением сверху
struct ScreenBackground: View {
    var body: some View {
        ZStack(alignment: .top) {
            Theme.background
            RadialGradient(colors: [Theme.accent.opacity(0.16), .clear],
                           center: .top, startRadius: 0, endRadius: 380)
                .frame(height: 420)
                .offset(y: -140)
        }
        .ignoresSafeArea()
    }
}
