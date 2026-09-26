import Charts
import SwiftUI

/// Аналитика топлива на экране статистики: расход, цена литра, стоимость 100 км,
/// разбивка по типам топлива и график изменения цены
struct FuelStatsSection: View {
    let stats: FuelStats
    /// Точки расхода по заправкам для мини-графика
    let consumptionSeries: [FuelFill]
    /// Изменение расхода к предыдущему периоду, %
    let trend: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Топливо")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                NavigationLink(value: DashboardRoute.fuel) { AllLinkLabel() }
            }
            consumptionCard
            tiles
            if !stats.byType.isEmpty { byTypeCard }
            if stats.pricePoints.count >= 2 { priceChartCard }
        }
    }

    // MARK: Средний расход

    private var consumptionCard: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Средний расход топлива")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(stats.consumption?.oneDecimal ?? "—")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("л/100 км")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
                if let trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend > 0 ? "arrow.up" : "arrow.down")
                        Text("\(abs(trend).oneDecimal)% к прошлому периоду")
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(trend > 0 ? Theme.warning : Theme.accent)
                }
            }
            Spacer(minLength: 0)
            Chart(consumptionSeries) { fill in
                LineMark(x: .value("Дата", fill.expense.date),
                         y: .value("л/100", fill.consumption ?? 0))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .foregroundStyle(Theme.accent)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(width: 140, height: 64)
        }
        .card(padding: 18)
    }

    // MARK: Показатели

    private var tiles: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                StatTile(title: "Средняя цена литра",
                         value: stats.averagePricePerLiter.map { "\($0.oneDecimal) ₽" } ?? "—",
                         symbol: "rublesign.circle.fill", tint: ExpenseCategory.fuel.color)
                StatTile(title: "Стоимость 100 км",
                         value: stats.costPer100Km.map { $0.rub } ?? "—",
                         symbol: "road.lanes", tint: ExpenseCategory.tires.color)
            }
            GridRow {
                StatTile(title: "Заправок",
                         value: "\(stats.fillsCount)",
                         symbol: "fuelpump.fill", tint: ExpenseCategory.maintenance.color)
                StatTile(title: "Последняя заправка",
                         value: stats.lastFill.map { $0.amount.rub } ?? "—",
                         symbol: "clock.fill", tint: ExpenseCategory.taxes.color,
                         footnote: stats.lastFill.map(lastFillFootnote))
            }
        }
    }

    private func lastFillFootnote(_ fill: Expense) -> String {
        [fill.date.ruCompact,
         fill.liters.map { "\(Int($0.rounded())) л" },
         fill.fuelType?.title].compactMap { $0 }.joined(separator: " · ")
    }

    // MARK: По типам топлива

    private var byTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Расход по типу топлива")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            ForEach(stats.byType) { item in
                HStack(spacing: 12) {
                    Circle().fill(item.type.color).frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.type.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(item.fillsCount) \(Plural.form(item.fillsCount, "заправка", "заправки", "заправок")) · \(Int(item.liters.rounded())) л")
                            .font(.caption)
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.consumption.map { "\($0.oneDecimal) л/100" } ?? "—")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(item.averagePricePerLiter.map { "\($0.oneDecimal) ₽/л" } ?? "")
                            .font(.caption)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
        }
        .card()
    }

    // MARK: График цены

    private var priceChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Изменение цены топлива")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            Chart(stats.pricePoints) { point in
                LineMark(x: .value("Дата", point.date),
                         y: .value("₽/л", point.pricePerLiter),
                         series: .value("Топливо", point.type.title))
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    .foregroundStyle(by: .value("Топливо", point.type.title))
                PointMark(x: .value("Дата", point.date),
                          y: .value("₽/л", point.pricePerLiter))
                    .symbolSize(18)
                    .foregroundStyle(by: .value("Топливо", point.type.title))
            }
            .chartForegroundStyleScale(domain: stats.byType.map(\.type.title),
                                       range: stats.byType.map(\.type.color))
            .chartYScale(domain: .automatic(includesZero: false))
            .chartLegend(position: .bottom, alignment: .leading)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3])).foregroundStyle(Theme.stroke)
                    AxisValueLabel {
                        if let v = value.as(Double.self) { Text("\(Int(v)) ₽").foregroundStyle(Theme.textTertiary) }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated)).foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(height: 190)
        }
        .card()
    }
}
