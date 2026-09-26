import PhotosUI
import SwiftData
import SwiftUI

enum CarRoute: Hashable {
    case reminders
    case parts
}

struct CarView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Car.createdAt) private var cars: [Car]
    @Query(sort: \RepairRecord.date, order: .reverse) private var repairs: [RepairRecord]
    @Query private var reminders: [Reminder]
    @Query(filter: #Predicate<Part> { $0.isActive == true }) private var parts: [Part]
    @Query private var expenses: [Expense]
    @State private var vm = CarViewModel()
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Group {
                if let car = cars.first {
                    content(car)
                } else {
                    EmptyStateView(symbol: "car", title: "Нет автомобиля", message: "Загрузите демо-данные")
                }
            }
            .background(ScreenBackground())
            .navigationTitle("Гараж")
            .navigationDestination(for: CarRoute.self) { route in
                switch route {
                case .reminders: RemindersView()
                case .parts: PartsView()
                }
            }
            .navigationDestination(for: Part.self) { PartDetailView(part: $0) }
            .navigationDestination(for: RepairRoute.self) { route in
                switch route {
                case .list: RepairsView()
                case .timeline: CarTimelineView()
                }
            }
            .navigationDestination(for: RepairRecord.self) { RepairDetailView(repair: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { vm.showEditCar = true } label: { Label("Редактировать", systemImage: "pencil") }
                        Button { vm.showResetConfirm = true } label: {
                            Label("Загрузить демо-данные", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $vm.showEditCar) {
                if let car = cars.first { EditCarView(car: car).autoSheetStyle() }
            }
            .confirmationDialog("Заменить все данные демонстрационными?", isPresented: $vm.showResetConfirm,
                                titleVisibility: .visible) {
                Button("Сбросить и загрузить", role: .destructive) {
                    withAnimation(Theme.spring) { DemoDataService.reset(context) }
                }
            } message: {
                Text("Текущие расходы, ремонты и напоминания будут удалены.")
            }
            .alert("Текущий пробег", isPresented: $vm.showMileageUpdate) {
                TextField("Пробег, км", text: $vm.mileageDraft)
                    .keyboardType(.numberPad)
                Button("Сохранить") {
                    withAnimation(Theme.spring) { vm.applyMileage(context: context) }
                }
                Button("Отмена", role: .cancel) {}
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = await ImageService.loadJPEG(from: item), let car = cars.first {
                        withAnimation(Theme.spring) { car.photoData = data }
                        try? context.save()
                    }
                }
            }
        }
    }

    private func content(_ car: Car) -> some View {
        let overview = vm.overview(repairs: repairs, reminders: reminders, parts: parts,
                                   expenses: expenses, mileage: car.mileage)
        return ScrollView {
            VStack(spacing: 20) {
                hero(car)
                    .appear()
                linksCard
                    .appear(delay: 0.05)
                serviceCard(overview, mileage: car.mileage)
                    .appear(delay: 0.1)
                infoCard(car)
                    .appear(delay: 0.15)
                serviceHistory
                    .appear(delay: 0.2)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Hero

    private func hero(_ car: Car) -> some View {
        VStack(spacing: 14) {
            CarHeroImage(photoData: car.photoData, height: 220)
                .overlay(alignment: .bottomTrailing) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(car.photoData == nil ? "Добавить фото" : "Сменить фото", systemImage: "camera.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding(12)
                }
                .overlay(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous).strokeBorder(Theme.stroke))

            VStack(spacing: 4) {
                Text(car.displayName)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(car.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }

            Button {
                vm.mileageDraft = String(car.mileage)
                vm.showMileageUpdate = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gauge.with.dots.needle.67percent")
                    Text(car.mileage.km)
                        .contentTransition(.numericText())
                    Image(systemName: "pencil")
                        .font(.caption)
                }
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Theme.accentGradient, in: Capsule())
            }
            .buttonStyle(PressableStyle())
        }
    }

    // MARK: Info

    private func infoCard(_ car: Car) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Информация")
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    infoCell("Марка", car.make, "car.fill")
                    infoCell("Модель", car.model, "tag.fill")
                }
                GridRow {
                    infoCell("Год", String(car.year), "calendar")
                    infoCell("Кузов", car.bodyCode, "square.3.layers.3d")
                }
                GridRow {
                    infoCell("Двигатель", car.engine, "engine.combustion.fill")
                    infoCell("Пробег", car.mileage.km, "gauge.with.dots.needle.50percent")
                }
            }
            VStack(spacing: 10) {
                InfoRow(title: "VIN / номер кузова", value: car.vin.isEmpty ? "—" : car.vin)
                Divider().overlay(Theme.stroke)
                HStack {
                    Text("Госномер")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    PlateView(plate: car.plate)
                }
            }
            .card()
        }
    }

    private func infoCell(_ title: String, _ value: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Text(value.isEmpty ? "—" : value)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .card(padding: 14)
    }

    // MARK: Service overview

    private func serviceCard(_ overview: ServiceOverview, mileage: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Обслуживание")
            VStack(spacing: 0) {
                overviewRow(symbol: "checkmark.circle.fill", tint: Theme.accent, title: "Последнее ТО",
                            value: overview.lastService.map { "\($0.date.ruShort) · \($0.mileage.km)" } ?? "Нет данных")
                Divider().overlay(Theme.stroke).padding(.leading, 44)
                overviewRow(symbol: "calendar.badge.clock",
                            tint: overview.nextService?.status.color ?? Theme.textTertiary,
                            title: "Следующее ТО",
                            value: overview.nextService.map { "\($0.title) · \($0.headline.lowercased())" } ?? "Не запланировано")
                Divider().overlay(Theme.stroke).padding(.leading, 44)
                overviewRow(symbol: "wrench.and.screwdriver.fill", tint: RepairCategory.engine.color, title: "Последний ремонт",
                            value: overview.lastRepair.map { "\($0.title) · \($0.date.ruShort)" } ?? "Нет данных")
            }
            .card(padding: 4)

            if !overview.nearestWorks.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Ближайшие работы")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                    ForEach(overview.nearestWorks) { item in
                        Group {
                            switch item.source {
                            case .part(let part):
                                NavigationLink(value: part) { UpcomingServiceRow(item: item) }
                            case .reminder:
                                NavigationLink(value: CarRoute.reminders) { UpcomingServiceRow(item: item) }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .card()
            }
        }
    }

    private func overviewRow(symbol: String, tint: Color, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(12)
    }

    // MARK: Links

    private var linksCard: some View {
        VStack(spacing: 0) {
            NavigationLink(value: RepairRoute.list) {
                linkRow(symbol: "wrench.and.screwdriver.fill", title: "Ремонт и обслуживание",
                        subtitle: "История ремонтов, фото, стоимость работ")
            }
            Divider().overlay(Theme.stroke).padding(.leading, 70)
            NavigationLink(value: CarRoute.parts) {
                linkRow(symbol: "gearshape.2.fill", title: "Детали и ресурс",
                        subtitle: "Износ установленных деталей и сроки замены")
            }
            Divider().overlay(Theme.stroke).padding(.leading, 70)
            NavigationLink(value: CarRoute.reminders) {
                linkRow(symbol: "bell.badge.fill", title: "Напоминания",
                        subtitle: "ОСАГО, техосмотр и регламентные работы")
            }
            Divider().overlay(Theme.stroke).padding(.leading, 70)
            NavigationLink(value: RepairRoute.timeline) {
                linkRow(symbol: "point.topleft.down.to.point.bottomright.curvepath.fill", title: "Timeline эксплуатации",
                        subtitle: "Вся история ремонтов по годам")
            }
        }
        .card(padding: 0)
        .buttonStyle(.plain)
    }

    private func linkRow(symbol: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            SymbolBadge(symbol: symbol, color: Theme.accent, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(14)
        .contentShape(Rectangle())
    }

    // MARK: History

    private var serviceHistory: some View {
        let items = vm.serviceHistory(repairs)
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "История обслуживания")
            if items.isEmpty {
                EmptyStateView(symbol: "wrench.adjustable", title: "Пока нет ТО",
                               message: "Добавьте запись с категорией «Плановое ТО» в разделе «Ремонт»")
                    .card()
            } else {
                VStack(spacing: 0) {
                    ForEach(items) { repair in
                        NavigationLink(value: repair) {
                            HStack(spacing: 12) {
                                SymbolBadge(symbol: repair.category.symbol, color: repair.category.color, size: 38)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(repair.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("\(repair.date.ruShort) · \(repair.mileage.km)")
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Text(repair.totalCost.rub)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            .padding(12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if repair.persistentModelID != items.last?.persistentModelID {
                            Divider().overlay(Theme.stroke).padding(.leading, 62)
                        }
                    }
                }
                .card(padding: 4)
            }
        }
    }
}

/// Российский госномер в стилизованной рамке
struct PlateView: View {
    let plate: String

    var body: some View {
        let parts = plate.split(separator: " ", maxSplits: 1).map(String.init)
        HStack(spacing: 0) {
            Text(parts.first ?? plate)
                .padding(.horizontal, 8)
            if parts.count > 1 {
                Rectangle().fill(.black).frame(width: 1.5)
                VStack(spacing: -2) {
                    Text(parts[1]).font(.system(size: 12, weight: .bold, design: .monospaced))
                    Text("RUS").font(.system(size: 6, weight: .bold))
                }
                .padding(.horizontal, 5)
            }
        }
        .font(.system(size: 16, weight: .bold, design: .monospaced))
        .foregroundStyle(.black)
        .frame(height: 30)
        .background(.white, in: RoundedRectangle(cornerRadius: 5))
        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.black, lineWidth: 1.5))
    }
}
