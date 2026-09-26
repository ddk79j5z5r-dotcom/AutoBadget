import Foundation
import SwiftData

enum RepairCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case engine
    case gearbox
    case suspension
    case brakes
    case electrics
    case body
    case interior
    case service

    var id: String { rawValue }

    var title: String {
        switch self {
        case .engine: "Двигатель"
        case .gearbox: "Трансмиссия"
        case .suspension: "Подвеска"
        case .brakes: "Тормоза"
        case .electrics: "Электрика"
        case .body: "Кузов"
        case .interior: "Салон"
        case .service: "Плановое ТО"
        }
    }

    var symbol: String {
        switch self {
        case .engine: "engine.combustion.fill"
        case .gearbox: "gearshift.layout.sixspeed"
        case .suspension: "arrow.up.and.down.circle.fill"
        case .brakes: "exclamationmark.brakesignal"
        case .electrics: "bolt.fill"
        case .body: "car.fill"
        case .interior: "carseat.left.fill"
        case .service: "wrench.and.screwdriver.fill"
        }
    }

    /// В какую категорию бюджета попадает стоимость ремонта
    var expenseCategory: ExpenseCategory {
        self == .service ? .maintenance : .repair
    }
}

@Model
final class RepairRecord {
    var uid: UUID
    var title: String
    var categoryRaw: String
    var date: Date
    var mileage: Int
    var worksDone: String
    var partsUsed: String
    var laborCost: Double
    var partsCost: Double
    var shop: String
    var comment: String
    @Attribute(.externalStorage) var photoBefore: Data?
    @Attribute(.externalStorage) var photoAfter: Data?
    /// Заменённые детали. Удаление ремонта выполняется через `DataService.delete(_:in:)`,
    /// который перед каскадным удалением возвращает на учёт ранее снятые детали.
    @Relationship(deleteRule: .cascade, inverse: \Part.repair)
    var parts: [Part]? = []

    init(title: String,
         category: RepairCategory,
         date: Date,
         mileage: Int,
         worksDone: String = "",
         partsUsed: String = "",
         laborCost: Double = 0,
         partsCost: Double = 0,
         shop: String = "",
         comment: String = "",
         photoBefore: Data? = nil,
         photoAfter: Data? = nil) {
        self.uid = UUID()
        self.title = title
        self.categoryRaw = category.rawValue
        self.date = date
        self.mileage = mileage
        self.worksDone = worksDone
        self.partsUsed = partsUsed
        self.laborCost = laborCost
        self.partsCost = partsCost
        self.shop = shop
        self.comment = comment
        self.photoBefore = photoBefore
        self.photoAfter = photoAfter
    }

    var category: RepairCategory {
        get { RepairCategory(rawValue: categoryRaw) ?? .engine }
        set { categoryRaw = newValue.rawValue }
    }

    var totalCost: Double { laborCost + partsCost }

    var sortedParts: [Part] { (parts ?? []).sorted { $0.name < $1.name } }
}
