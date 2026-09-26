import SwiftUI

struct ExpenseRow: View {
    let expense: Expense

    private var subtitle: String {
        var parts = [expense.date.ruCompact]
        if let liters = expense.liters, expense.category == .fuel {
            parts.append("\(Int(liters.rounded())) л")
            if let fuelType = expense.fuelType { parts.append(fuelType.title) }
        } else if expense.mileage > 0 {
            parts.append(expense.mileage.km)
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: expense.category, size: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(subtitle)
                    if expense.repairID != nil {
                        Image(systemName: "link")
                            .accessibilityLabel("Из истории ремонтов")
                    }
                }
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
            }
            .layoutPriority(1)
            Spacer(minLength: 8)
            Text(expense.amount.rub)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

/// Строка блока «Скоро потребуется обслуживание»: «Через 2 000 км — Передние колодки»
struct UpcomingServiceRow: View {
    let item: UpcomingService

    var body: some View {
        HStack(spacing: 12) {
            SymbolBadge(symbol: item.symbol, color: item.status.color, size: 38)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.headline)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(item.status.color)
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                    }
                    Spacer()
                    if item.status != .ok {
                        StatusPill(text: item.status == .overdue ? item.item.overdueTitle : item.status.title,
                                   color: item.status.color)
                    }
                }
                ProgressBar(value: item.progress, tint: item.status.color, height: 5)
            }
        }
        .contentShape(Rectangle())
    }
}

/// Деталь в списке: износ, остаток ресурса, следующая замена
struct PartRow: View {
    let part: Part
    let mileage: Int

    var body: some View {
        let status = part.status(currentMileage: mileage)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                SymbolBadge(symbol: part.category.symbol, color: status.color, size: 38)
                VStack(alignment: .leading, spacing: 3) {
                    Text(part.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text([part.manufacturer, part.articleNumber].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                StatusPill(text: part.statusTitle(currentMileage: mileage), color: status.color)
            }
            ProgressBar(value: part.progress(currentMileage: mileage), tint: status.color, height: 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(part.remainingDescription(currentMileage: mileage).capitalizedFirst)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(status == .ok ? Theme.textSecondary : status.color)
                Text("Следующая замена: \(part.nextServiceDescription)")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .contentShape(Rectangle())
    }
}

/// Фото автомобиля или фирменная иллюстрация
struct CarHeroImage: View {
    let photoData: Data?
    var height: CGFloat = 200
    /// Отступ снизу для иллюстрации, чтобы оставить место под подписи
    var illustrationBottomInset: CGFloat = 0

    var body: some View {
        ZStack {
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .clipped()
                    .overlay(LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .center, endPoint: .bottom))
            } else {
                LinearGradient(colors: [Theme.cardElevated, Theme.card], startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [Theme.accent.opacity(0.22), .clear], center: .bottom, startRadius: 10, endRadius: 260)
                Image("CarHero")
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
                    .padding(.bottom, illustrationBottomInset)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
    }
}
