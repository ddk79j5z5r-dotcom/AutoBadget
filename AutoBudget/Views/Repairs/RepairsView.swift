import SwiftData
import SwiftUI

enum RepairRoute: Hashable {
    case list
    case timeline
}

struct RepairsView: View {
    @Query(sort: \RepairRecord.date, order: .reverse) private var repairs: [RepairRecord]
    @Query(sort: \Car.createdAt) private var cars: [Car]
    @State private var vm = RepairsViewModel()

    var body: some View {
        let stats = vm.stats(repairs)
        let items = vm.filtered(repairs)

        ScrollView {
                VStack(spacing: 20) {
                    StatsHeader(stats: stats)
                        .appear()

                    NavigationLink(value: RepairRoute.timeline) {
                        HStack(spacing: 14) {
                            SymbolBadge(symbol: "point.topleft.down.to.point.bottomright.curvepath.fill", color: Theme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("История автомобиля")
                                    .font(.headline)
                                    .foregroundStyle(Theme.textPrimary)
                                Text("Все ремонты на временной шкале")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .card()
                    }
                    .buttonStyle(PressableStyle())
                    .appear(delay: 0.05)

                    VStack(spacing: 12) {
                        SearchField(text: $vm.searchText, prompt: "Поиск по работам и запчастям")
                        filterBar
                    }

                    LazyVStack(spacing: 12) {
                        if items.isEmpty {
                            EmptyStateView(symbol: "wrench.and.screwdriver",
                                           title: "Нет записей",
                                           message: "Добавьте ремонт кнопкой «+»")
                        }
                        ForEach(items) { repair in
                            NavigationLink(value: repair) {
                                RepairCard(repair: repair)
                            }
                            .buttonStyle(PressableStyle())
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        }
                    }
                    .animation(Theme.spring, value: vm.selectedCategory)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(ScreenBackground())
            .navigationTitle("Ремонт и ТО")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { vm.showAddRepair = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Добавить ремонт")
                }
            }
            .sheet(isPresented: $vm.showAddRepair) {
                AddRepairView(currentMileage: cars.first?.mileage ?? 0)
                    .autoSheetStyle()
            }
    }

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                FilterChip(title: "Все", isSelected: vm.selectedCategory == nil) {
                    vm.selectedCategory = nil
                }
                ForEach(RepairCategory.allCases) { category in
                    FilterChip(title: category.title, isSelected: vm.selectedCategory == category) {
                        vm.selectedCategory = vm.selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }
}

private struct StatsHeader: View {
    let stats: RepairStats

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Все ремонты")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Text(stats.total.rub)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(stats.count)")
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.accent)
                    Text(Plural.form(stats.count, "ремонт", "ремонта", "ремонтов"))
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            HStack(spacing: 10) {
                mini(title: "Средняя стоимость", value: stats.average.rub, detail: nil)
                mini(title: "Самая дорогая",
                     value: stats.mostExpensive?.totalCost.rub ?? "—",
                     detail: stats.mostExpensive?.title)
            }
            if let last = stats.last {
                HStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Последний ремонт")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(last.title) · \(last.date.ruShort)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(last.totalCost.rub)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(12)
                .background(Theme.cardElevated, in: RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous))
            }
        }
        .card(padding: 20)
    }

    private func mini(title: String, value: String, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(detail ?? " ")
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardElevated, in: RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous))
    }
}

struct RepairCard: View {
    let repair: RepairRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                SymbolBadge(symbol: repair.category.symbol, color: repair.category.color)
                VStack(alignment: .leading, spacing: 4) {
                    Text(repair.title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text("\(repair.date.ruShort) · Пробег: \(repair.mileage.km)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
                StatusPill(text: repair.category.title, color: repair.category.color)
            }

            VStack(spacing: 6) {
                costRow("Работы", repair.laborCost)
                costRow("Запчасти", repair.partsCost)
                Divider().overlay(Theme.stroke)
                HStack {
                    Text("Итого")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text(repair.totalCost.rub)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Theme.accent)
                }
            }

            if !repair.shop.isEmpty || repair.photoBefore != nil || repair.photoAfter != nil {
                HStack(spacing: 6) {
                    if !repair.shop.isEmpty {
                        Image(systemName: "building.2.fill")
                        Text(repair.shop).lineLimit(1)
                    }
                    Spacer()
                    if repair.photoBefore != nil || repair.photoAfter != nil {
                        Image(systemName: "photo.on.rectangle.angled")
                    }
                }
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
            }
        }
        .card()
    }

    private func costRow(_ title: String, _ value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value.rub)
        }
        .font(.subheadline)
        .foregroundStyle(Theme.textSecondary)
    }
}
