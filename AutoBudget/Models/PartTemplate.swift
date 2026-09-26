import Foundation

/// Типовые детали с рекомендуемым ресурсом — быстрый выбор при добавлении детали в ремонт
struct PartTemplate: Identifiable, Hashable {
    let name: String
    let category: RepairCategory
    let lifeKm: Int
    let lifeMonths: Int

    var id: String { "\(category.rawValue)-\(name)" }

    static let catalog: [PartTemplate] = [
        PartTemplate(name: "Моторное масло", category: .service, lifeKm: 7_500, lifeMonths: 12),
        PartTemplate(name: "Масляный фильтр", category: .service, lifeKm: 7_500, lifeMonths: 12),
        PartTemplate(name: "Воздушный фильтр", category: .service, lifeKm: 15_000, lifeMonths: 12),
        PartTemplate(name: "Салонный фильтр", category: .service, lifeKm: 15_000, lifeMonths: 12),
        PartTemplate(name: "Свечи зажигания", category: .engine, lifeKm: 30_000, lifeMonths: 0),
        PartTemplate(name: "Ремень ГРМ", category: .engine, lifeKm: 100_000, lifeMonths: 60),
        PartTemplate(name: "Помпа", category: .engine, lifeKm: 100_000, lifeMonths: 0),
        PartTemplate(name: "Антифриз", category: .engine, lifeKm: 60_000, lifeMonths: 36),
        PartTemplate(name: "Масло АКПП (ATF)", category: .gearbox, lifeKm: 40_000, lifeMonths: 0),
        PartTemplate(name: "Передние колодки", category: .brakes, lifeKm: 30_000, lifeMonths: 0),
        PartTemplate(name: "Задние колодки", category: .brakes, lifeKm: 50_000, lifeMonths: 0),
        PartTemplate(name: "Тормозные диски", category: .brakes, lifeKm: 60_000, lifeMonths: 0),
        PartTemplate(name: "Тормозная жидкость", category: .brakes, lifeKm: 0, lifeMonths: 24),
        PartTemplate(name: "Амортизаторы", category: .suspension, lifeKm: 80_000, lifeMonths: 0),
        PartTemplate(name: "Сайлентблоки", category: .suspension, lifeKm: 80_000, lifeMonths: 0),
        PartTemplate(name: "Аккумулятор", category: .electrics, lifeKm: 0, lifeMonths: 48),
        PartTemplate(name: "Щётки стеклоочистителя", category: .body, lifeKm: 0, lifeMonths: 12),
    ]
}
