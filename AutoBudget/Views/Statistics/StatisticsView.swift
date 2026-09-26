import Charts
import SwiftData
import SwiftUI

struct StatisticsView: View {
    @Query(sort: \Expense.date) private var expenses: [Expense]
    @State private var vm = StatisticsViewModel()

    var body: some View {
        let metrics = vm.metrics(expenses)
        let categories = vm.categories(expenses)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    PeriodPicker(selection: $vm.period)
                    donutCard(categories: categories, total: metrics.total)
                    categoryBreakdown(categories)
                    metricsGrid(metrics)
                    FuelStatsSection(stats: vm.fuelStats(expenses),
                                     consumptionSeries: vm.fuelSeries(expenses),
                                     trend: vm.fuelTrend(expenses))
                    chartsCard(categories: categories)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(ScreenBackground())
            .navigationTitle("Статистика")
            .navigationDestination(for: DashboardRoute.self) { route in
                switch route {
                case .fuel: FuelView()
                case .reminders: RemindersView()
                case .parts: PartsView()
                }
            }
            .navigationDestination(for: Part.self) { PartDetailView(part: $0) }
            .navigationDestination(for: RepairRecord.self) { RepairDetailView(repair: $0) }
        }
    }

    // MARK: Donut + legend

    private func donutCard(categories: [CategoryTotal], total: Double) -> some View {
        let selected = categories.first { $0.category == vm.selectedCategory }
        return HStack(spacing: 18) {
            ZStack {
                Chart(categories) { item in
                    SectorMark(angle: .value("Сумма", item.total),
                               innerRadius: .ratio(0.72),
                               outerRadius: .ratio(vm.selectedCategory == item.category ? 1 : 0.93),
                               angularInset: 1.5)
                        .cornerRadius(4)
                        .foregroundStyle(item.category.color)
                        .opacity(vm.selectedCategory == nil || vm.selectedCategory == item.category ? 1 : 0.3)
                }
                .animation(Theme.spring, value: vm.selectedCategory)

                VStack(spacing: 2) {
                    Text((selected?.total ?? total).rub)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(selected?.category.title ?? "Всего")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                .frame(width: 92)
            }
            .frame(width: 150, height: 150)

            VStack(alignment: .leading, spacing: 9) {
                if categories.isEmpty {
                    Text("Нет расходов за период")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                ForEach(categories.prefix(6)) { item in
                    Button {
                        withAnimation(Theme.spring) {
                            vm.selectedCategory = vm.selectedCategory == item.category ? nil : item.category
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Circle().fill(item.category.color).frame(width: 8, height: 8)
                            Text(item.category.title)
                                .foregroundStyle(vm.selectedCategory == item.category ? Theme.textPrimary : Theme.textSecondary)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            Text("\(Int((item.share * 100).rounded()))%")
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .font(.caption.weight(.medium))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .card(padding: 18)
    }

    // MARK: Breakdown

    private func categoryBreakdown(_ data: [CategoryTotal]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Расходы по категориям")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            if data.isEmpty {
                EmptyStateView(symbol: "chart.pie", title: "Нет данных", message: "За выбранный период расходов нет")
            }
            ForEach(data) { item in
                HStack(spacing: 12) {
                    CategoryIcon(category: item.category, size: 32)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.category.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(item.total.rub)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(Int((item.share * 100).rounded()))%")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.textTertiary)
                                .frame(width: 36, alignment: .trailing)
                        }
                        ProgressBar(value: item.share, tint: item.category.color, height: 4)
                    }
                }
            }
        }
        .card()
    }

    // MARK: Metrics

    private func metricsGrid(_ m: StatsMetrics) -> some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                StatTile(title: "Общие расходы", value: m.total.rub, symbol: "rublesign.circle.fill",
                         footnote: "\(m.operationsCount) \(Plural.form(m.operationsCount, "операция", "операции", "операций"))")
                StatTile(title: "В среднем в месяц", value: m.averagePerMonth.rub, symbol: "calendar",
                         tint: ExpenseCategory.maintenance.color)
            }
            GridRow {
                StatTile(title: "Стоимость 1 км",
                         value: m.costPerKm.map { "\($0.oneDecimal) ₽" } ?? "—",
                         symbol: "road.lanes", tint: ExpenseCategory.tires.color,
                         footnote: "Все расходы / пробег")
                StatTile(title: "Пробег за период",
                         value: m.distanceKm?.km ?? "—",
                         symbol: "gauge.with.dots.needle.67percent", tint: ExpenseCategory.insurance.color,
                         footnote: "По записям с пробегом")
            }
        }
    }

    // MARK: Charts

    private func chartsCard(categories: [CategoryTotal]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Графики")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Picker("График", selection: $vm.chart.animation(Theme.spring)) {
                ForEach(StatsChart.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)

            Group {
                switch vm.chart {
                case .months:
                    MonthlyBarChart(data: vm.monthly(expenses))
                case .categories:
                    categoryBarChart(categories)
                case .years:
                    yearChart(vm.yearly(expenses))
                }
            }
            .frame(height: 230)
            .transition(.opacity)
        }
        .card()
    }

    private func categoryBarChart(_ data: [CategoryTotal]) -> some View {
        Chart(data) { item in
            BarMark(x: .value("Сумма", item.total),
                    y: .value("Категория", item.category.title))
                .foregroundStyle(item.category.color.gradient)
                .cornerRadius(6)
                .annotation(position: .trailing) {
                    Text(item.total.rubShort)
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel().foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func yearChart(_ data: [YearTotal]) -> some View {
        Chart(data) { item in
            BarMark(x: .value("Год", String(item.year)),
                    y: .value("Сумма", item.total),
                    width: .ratio(0.5))
                .foregroundStyle(LinearGradient(colors: [Theme.accent, Theme.accent.opacity(0.25)],
                                                startPoint: .top, endPoint: .bottom))
                .cornerRadius(8)
                .annotation(position: .top) {
                    Text(item.total.rubShort)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3])).foregroundStyle(Theme.stroke)
                AxisValueLabel {
                    if let v = value.as(Double.self) { Text(v.rubShort).foregroundStyle(Theme.textTertiary) }
                }
            }
        }
        .chartXAxis {
            AxisMarks { _ in AxisValueLabel().foregroundStyle(Theme.textSecondary) }
        }
    }
}
