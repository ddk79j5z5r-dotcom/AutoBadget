import SwiftData
import SwiftUI

/// Все установленные детали, сгруппированные по категориям, с остатком ресурса
struct PartsView: View {
    @Query(sort: \Part.installDate, order: .reverse) private var parts: [Part]
    @Query(sort: \Car.createdAt) private var cars: [Car]
    @State private var vm = PartsViewModel()

    private var mileage: Int { cars.first?.mileage ?? 0 }

    var body: some View {
        let groups = vm.groups(parts, mileage: mileage)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                NotificationPermissionBanner(message: "Предупредим, когда ресурс деталей подойдёт к концу.")
                summary(vm.summary(parts, mileage: mileage))
                SearchField(text: $vm.searchText, prompt: "Название, производитель, артикул")

                if groups.isEmpty {
                    EmptyStateView(symbol: "shippingbox",
                                   title: vm.searchText.isEmpty ? "Нет деталей" : "Ничего не найдено",
                                   message: "Детали добавляются в записи ремонта: «Гараж» → «Ремонт и обслуживание» → раздел «Заменённые детали».")
                }

                ForEach(groups) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Label(group.category.title, systemImage: group.category.symbol)
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        VStack(spacing: 0) {
                            ForEach(group.parts) { part in
                                NavigationLink(value: part) {
                                    PartRow(part: part, mileage: mileage)
                                        .padding(.vertical, 12)
                                }
                                .buttonStyle(.plain)
                                if part.persistentModelID != group.parts.last?.persistentModelID {
                                    Divider().overlay(Theme.stroke)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.padding)
                        .padding(.vertical, 4)
                        .card(padding: 0)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .animation(Theme.spring, value: groups.map(\.id))
        }
        .scrollIndicators(.hidden)
        .background(ScreenBackground())
        .navigationTitle("Детали и ресурс")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func summary(_ s: PartsSummary) -> some View {
        HStack(spacing: 10) {
            tile(value: s.replaceNow, title: "Замена", color: ServiceStatus.overdue.color)
            tile(value: s.attention, title: "Скоро", color: ServiceStatus.warning.color)
            tile(value: s.total, title: "На учёте", color: Theme.accent)
        }
    }

    private func tile(value: Int, title: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .card(padding: 12)
    }
}
