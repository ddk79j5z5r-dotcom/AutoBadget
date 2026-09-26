import Charts
import SwiftData
import SwiftUI

enum DashboardRoute: Hashable {
    case fuel
    case reminders
    case parts
}

struct DashboardView: View {
    @Binding var selectedTab: AppTab

    @Query(sort: \Car.createdAt) private var cars: [Car]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var reminders: [Reminder]
    @Query(filter: #Predicate<Part> { $0.isActive == true }) private var parts: [Part]
    @State private var vm = DashboardViewModel()
    @State private var editingExpense: Expense?

    private var car: Car? { cars.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let car {
                        CarHeader(car: car) { selectedTab = .garage }
                            .appear()
                    }
                    SummaryCard(summary: vm.summary(for: expenses),
                                spark: vm.sparkline(for: expenses))
                        .appear(delay: 0.05)
                    categoriesGrid
                        .appear(delay: 0.1)
                    recentCard
                        .appear(delay: 0.15)
                    MonthlyChartCard(data: vm.monthly(for: expenses))
                        .appear(delay: 0.2)
                    if let car {
                        let upcoming = vm.upcoming(reminders: reminders, parts: parts,
                                                   expenses: expenses, mileage: car.mileage)
                        if !upcoming.isEmpty {
                            maintenanceCard(upcoming)
                                .appear(delay: 0.25)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(ScreenBackground())
            .overlay(alignment: .top) {
                // Навбар скрыт — подложка под статус-бар, чтобы контент не заезжал под часы
                GeometryReader { geo in
                    Theme.background.opacity(0.85)
                        .background(.ultraThinMaterial)
                        .frame(height: geo.safeAreaInsets.top)
                        .ignoresSafeArea(edges: .top)
                }
                .allowsHitTesting(false)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ExpenseCategory.self) { category in
                CategoryExpensesView(category: category)
            }
            .navigationDestination(for: DashboardRoute.self) { route in
                switch route {
                case .fuel: FuelView()
                case .reminders: RemindersView()
                case .parts: PartsView()
                }
            }
            .navigationDestination(for: Part.self) { PartDetailView(part: $0) }
            .navigationDestination(for: RepairRecord.self) { RepairDetailView(repair: $0) }
            .sheet(item: $editingExpense) { expense in
                AddExpenseView(expense: expense).autoSheetStyle()
            }
        }
    }

    // MARK: Categories — 4 плитки в ряд, как в референсе

    private var categoriesGrid: some View {
        TileGrid(items: vm.categoryCards(for: expenses), columns: 4) { item in
                Group {
                    // Топливо ведёт на отдельный экран заправок
                    if item.category == .fuel {
                        NavigationLink(value: DashboardRoute.fuel) { CategoryTile(item: item) }
                    } else {
                        NavigationLink(value: item.category) { CategoryTile(item: item) }
                    }
                }
                .buttonStyle(PressableStyle())
        }
    }

    // MARK: Recent

    private var recentCard: some View {
        let items = vm.recent(expenses, limit: 4)
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Последние расходы")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    selectedTab = .expenses
                } label: {
                    AllLinkLabel()
                }
            }
            .padding(.bottom, 6)

            if items.isEmpty {
                EmptyStateView(symbol: "tray", title: "Пока пусто", message: "Добавьте первый расход кнопкой «+»")
            } else {
                ForEach(items) { expense in
                    Button { editingExpense = expense } label: { ExpenseRow(expense: expense) }
                        .buttonStyle(.plain)
                    if expense.persistentModelID != items.last?.persistentModelID {
                        Divider().overlay(Theme.stroke).padding(.leading, 52)
                    }
                }
            }
        }
        .card()
    }

    // MARK: Скоро потребуется обслуживание

    private func maintenanceCard(_ items: [UpcomingService]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Скоро потребуется обслуживание")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                NavigationLink(value: DashboardRoute.parts) {
                    AllLinkLabel()
                }
            }
            ForEach(items) { item in
                Group {
                    switch item.source {
                    case .part(let part):
                        NavigationLink(value: part) { UpcomingServiceRow(item: item) }
                    case .reminder:
                        NavigationLink(value: DashboardRoute.reminders) { UpcomingServiceRow(item: item) }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .card()
    }
}

/// «Все ›» в заголовках карточек
struct AllLinkLabel: View {
    var body: some View {
        HStack(spacing: 2) {
            Text("Все")
            Image(systemName: "chevron.right").font(.caption.weight(.bold))
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Theme.accent)
    }
}

// MARK: - Header

private struct CarHeader: View {
    let car: Car
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(car.displayName)
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Text([car.bodyCode, car.engine, String(car.year)].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    HStack(spacing: 5) {
                        Image(systemName: "gauge.with.dots.needle.67percent")
                        Text(car.mileage.km)
                            .contentTransition(.numericText())
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.accent.opacity(0.12), in: Capsule())
                }
                Spacer(minLength: 0)
                carImage
                    .frame(width: 150, height: 78)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityHint("Открыть гараж")
    }

    @ViewBuilder
    private var carImage: some View {
        if let data = car.photoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 78)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            Image("CarHero")
                .resizable()
                .scaledToFit()
        }
    }
}

// MARK: - Summary

private struct SummaryCard: View {
    let summary: DashboardSummary
    let spark: [MonthTotal]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Всего потрачено")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Text(summary.total.rub)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("за всё время")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer(minLength: 12)
                SparkBars(data: spark)
                    .frame(width: 96, height: 56)
            }

            HStack(spacing: 10) {
                metric(title: "В этом месяце", value: summary.thisMonth.rub, delta: summary.deltaVsLastMonth)
                metric(title: "Средний / мес за год", value: summary.averagePerMonth.rub, delta: nil)
            }
        }
        .card(padding: 18)
    }

    private func metric(title: String, value: String, delta: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let delta {
                    // Для расходов рост — плохо (оранжевый), снижение — хорошо (акцент)
                    HStack(spacing: 1) {
                        Image(systemName: delta > 0 ? "arrow.up" : "arrow.down")
                        Text("\(Int(abs(delta).rounded()))%")
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(delta > 0 ? Theme.warning : Theme.accent)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardElevated, in: RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous))
    }
}

/// Мини-столбики как в карточке «Всего потрачено» референса
private struct SparkBars: View {
    let data: [MonthTotal]

    var body: some View {
        let maxValue = max(data.map(\.total).max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                let isLast = index == data.count - 1
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.accent.opacity(isLast ? 1 : 0.55), Theme.accent.opacity(0.15)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(maxWidth: .infinity)
                    .frame(height: max(4, 56 * item.total / maxValue))
            }
        }
        .animation(Theme.spring, value: data)
        .accessibilityHidden(true)
    }
}

private struct CategoryTile: View {
    let item: CategoryTotal

    var body: some View {
        VStack(spacing: 6) {
            CategoryIcon(category: item.category, size: 34)
            Text(item.category.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(item.total.rub)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("\(Int((item.share * 100).rounded()))%")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.stroke))
    }
}

// MARK: - Monthly chart (используется и в статистике)

struct MonthlyChartCard: View {
    let data: [MonthTotal]
    var title = "Расходы по месяцам"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            MonthlyBarChart(data: data)
                .frame(height: 190)
        }
        .card()
    }
}

struct MonthlyBarChart: View {
    let data: [MonthTotal]
    @State private var selected: Date?

    private var selectedItem: MonthTotal? {
        guard let selected else { return nil }
        return data.first { Calendar.current.isDate($0.month, equalTo: selected, toGranularity: .month) }
    }

    var body: some View {
        Chart(data) { item in
            BarMark(x: .value("Месяц", item.month, unit: .month),
                    y: .value("Сумма", item.total))
                .cornerRadius(6)
                .foregroundStyle(barStyle(for: item))
            if let selectedItem, selectedItem.month == item.month {
                RuleMark(x: .value("Месяц", item.month, unit: .month))
                    .foregroundStyle(.clear)
                    .annotation(position: .top, spacing: 0, overflowResolution: .init(x: .fit, y: .disabled)) {
                        VStack(spacing: 2) {
                            Text(item.month.ruMonthYear)
                                .font(.caption2)
                                .foregroundStyle(Theme.textSecondary)
                            Text(item.total.rub)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.textPrimary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.cardElevated, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
            }
        }
        .chartXSelection(value: $selected)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month, count: data.count > 12 ? 3 : 1)) { _ in
                AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                    .foregroundStyle(Theme.stroke)
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(v.rubShort).foregroundStyle(Theme.textTertiary)
                    }
                }
            }
        }
        .animation(Theme.spring, value: data)
    }

    private func barStyle(for item: MonthTotal) -> AnyShapeStyle {
        let isCurrent = Calendar.current.isDate(item.month, equalTo: .now, toGranularity: .month)
        let isSelected = selectedItem?.month == item.month
        if isSelected || (selectedItem == nil && isCurrent) {
            return AnyShapeStyle(LinearGradient(colors: [Theme.accent, Theme.accentDeep.opacity(0.6)],
                                                startPoint: .top, endPoint: .bottom))
        }
        return AnyShapeStyle(LinearGradient(colors: [Theme.accent.opacity(0.55), Theme.accent.opacity(0.15)],
                                            startPoint: .top, endPoint: .bottom))
    }
}
