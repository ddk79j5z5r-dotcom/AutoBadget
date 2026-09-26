import Charts
import SwiftData
import SwiftUI

/// Экран «Заправки»: литры, средний расход, график и история заправок
struct FuelView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var period: StatsPeriod = .threeMonths
    @State private var editingExpense: Expense?

    var body: some View {
        let inPeriod = period.filter(expenses)
        let fills = AnalyticsService.fuelFills(inPeriod)
        let liters = fills.reduce(0) { $0 + $1.liters }
        let consumption = AnalyticsService.averageFuelConsumption(inPeriod)
        let allFills = AnalyticsService.fuelFills(expenses).reversed()

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PeriodPicker(selection: $period, options: [.threeMonths, .sixMonths, .twelveMonths])

                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 0) {
                        summaryColumn(title: "Общий расход топлива",
                                      value: Formatters.integer.string(from: NSNumber(value: liters)) ?? "0",
                                      unit: "л",
                                      footnote: "за \(period.title.lowercased())")
                        Rectangle().fill(Theme.stroke).frame(width: 1, height: 64)
                            .padding(.horizontal, 14)
                        summaryColumn(title: "Средний расход",
                                      value: consumption?.oneDecimal ?? "—",
                                      unit: "л/100 км",
                                      footnote: AnalyticsService.fuelSpentPerLiter(inPeriod).map { "\($0.oneDecimal) ₽ за литр" } ?? " ")
                    }
                    litersChart(inPeriod)
                        .frame(height: 150)
                }
                .card(padding: 18)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Последние заправки")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.bottom, 6)
                    if allFills.isEmpty {
                        EmptyStateView(symbol: "fuelpump", title: "Нет заправок",
                                       message: "Добавьте расход «Топливо» с объёмом в литрах")
                    }
                    ForEach(Array(allFills.prefix(30))) { fill in
                        Button { editingExpense = fill.expense } label: { FuelRow(fill: fill) }
                            .buttonStyle(.plain)
                        Divider().overlay(Theme.stroke).padding(.leading, 52)
                    }
                }
                .card()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(ScreenBackground())
        .navigationTitle("Заправки")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingExpense) { AddExpenseView(expense: $0).autoSheetStyle() }
    }

    private func summaryColumn(title: String, value: String, unit: String, footnote: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            Text(footnote)
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func litersChart(_ items: [Expense]) -> some View {
        let months = period.months ?? 12
        let data = (0..<months).reversed().compactMap { offset -> (Date, Double)? in
            guard let month = Calendar.current.date(byAdding: .month, value: -offset, to: Date.now.startOfMonth) else { return nil }
            let liters = items
                .filter { $0.category == .fuel && Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }
                .reduce(0) { $0 + ($1.liters ?? 0) }
            return (month, liters)
        }
        return Chart(data, id: \.0) { item in
            BarMark(x: .value("Месяц", item.0, unit: .month),
                    y: .value("Литры", item.1),
                    width: .ratio(0.55))
                .cornerRadius(5)
                .foregroundStyle(LinearGradient(colors: [ExpenseCategory.fuel.color, ExpenseCategory.fuel.color.opacity(0.25)],
                                                startPoint: .top, endPoint: .bottom))
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .animation(Theme.spring, value: period)
    }
}

private struct FuelRow: View {
    let fill: FuelFill

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: .fuel, size: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(fill.expense.date.ruShort)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(details)
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(fill.distance.map { $0.km } ?? "—")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                if let c = fill.consumption {
                    Text("\(c.oneDecimal) л/100")
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    /// «45 л · 95 · 62,4 ₽/л · Лукойл»
    private var details: String {
        var parts = ["\(Int(fill.liters.rounded())) л"]
        if let fuelType = fill.expense.fuelType { parts.append(fuelType.shortTitle) }
        parts.append("\(fill.pricePerLiter.oneDecimal) ₽/л")
        if !fill.expense.place.isEmpty { parts.append(fill.expense.place) }
        return parts.joined(separator: " · ")
    }
}

/// Сегментный переключатель периода в стиле референса
struct PeriodPicker: View {
    @Binding var selection: StatsPeriod
    var options: [StatsPeriod] = StatsPeriod.allCases
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options) { option in
                let active = option == selection
                Button {
                    withAnimation(Theme.spring) { selection = option }
                } label: {
                    Text(option.title)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(active ? Theme.textPrimary : Theme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background {
                            if active {
                                Capsule()
                                    .fill(Theme.cardElevated)
                                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.1)))
                                    .matchedGeometryEffect(id: "period", in: ns)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.card, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.stroke))
    }
}
