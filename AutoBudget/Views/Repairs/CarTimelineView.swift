import SwiftData
import SwiftUI

/// Общая временная шкала эксплуатации автомобиля
struct CarTimelineView: View {
    @Query(sort: \RepairRecord.date, order: .reverse) private var repairs: [RepairRecord]
    @Query(sort: \Car.createdAt) private var cars: [Car]

    var body: some View {
        let years = RepairsViewModel.timeline(repairs)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                summary(years: years)
                    .padding(.bottom, 24)

                // Краткая лента по годам: 2024 → …, 2025 → …
                if !years.isEmpty {
                    yearStrip(years.reversed())
                        .padding(.bottom, 24)
                }

                if let car = cars.first {
                    TimelineNode(color: Theme.accent, isFirst: true, isLast: false) {
                        HStack(spacing: 8) {
                            Image(systemName: "gauge.with.dots.needle.67percent")
                            Text("Сегодня · \(car.mileage.km)")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                        .padding(.bottom, 20)
                    }
                }

                ForEach(years) { year in
                    TimelineNode(color: Theme.textPrimary, isFirst: false, isLast: false, dotSize: 14) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(String(year.year))
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(year.total.rub)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.bottom, 12)
                    }
                    ForEach(Array(year.repairs.enumerated()), id: \.element.persistentModelID) { index, repair in
                        TimelineNode(color: repair.category.color, isFirst: false, isLast: false) {
                            NavigationLink(value: repair) {
                                TimelineEventCard(repair: repair)
                            }
                            .buttonStyle(PressableStyle())
                            .padding(.bottom, 14)
                        }
                        .appear(delay: Double(index) * 0.04)
                    }
                }

                if let car = cars.first {
                    TimelineNode(color: Theme.textTertiary, isFirst: false, isLast: true) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(car.year))
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.textSecondary)
                            Text("Выпуск автомобиля · \(car.displayName) \(car.bodyCode)")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(ScreenBackground())
        .navigationTitle("История автомобиля")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func summary(years: [TimelineYear]) -> some View {
        let total = years.reduce(0) { $0 + $1.total }
        let count = years.reduce(0) { $0 + $1.repairs.count }
        return HStack(spacing: 12) {
            StatTile(title: "Записей", value: "\(count)", symbol: "list.bullet")
            StatTile(title: "Сумма", value: total.rub, symbol: "rublesign.circle")
        }
    }

    private func yearStrip(_ years: [TimelineYear]) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Array(years.enumerated()), id: \.element.id) { index, year in
                    let main = year.repairs.max { $0.totalCost < $1.totalCost }
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(year.year))
                                .font(.headline)
                                .foregroundStyle(Theme.accent)
                            Text(main?.title ?? "")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous))
                        if index < years.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

private struct TimelineNode<Content: View>: View {
    let color: Color
    let isFirst: Bool
    let isLast: Bool
    var dotSize: CGFloat = 12
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(LinearGradient(colors: [Theme.accent.opacity(0.5), Theme.stroke],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 2)
                    .padding(.top, isFirst ? 10 : 0)
                    .frame(maxHeight: isLast ? 10 : .infinity, alignment: .top)
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
                    .overlay(Circle().stroke(Theme.background, lineWidth: 3))
                    .shadow(color: color.opacity(0.6), radius: 6)
                    .padding(.top, 6)
            }
            .frame(width: 20)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct TimelineEventCard: View {
    let repair: RepairRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(repair.date.ruDayMonth)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(repair.category.color)
                Spacer()
                Text(repair.mileage.km)
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
            Text(repair.title)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.leading)
            HStack {
                Label(repair.category.title, systemImage: repair.category.symbol)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(repair.totalCost.rub)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .card(padding: 14)
    }
}
