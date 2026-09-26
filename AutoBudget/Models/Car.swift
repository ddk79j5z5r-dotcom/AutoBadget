import Foundation
import SwiftData

@Model
final class Car {
    var make: String
    var model: String
    var bodyCode: String
    var year: Int
    var engine: String
    var vin: String
    var plate: String
    var mileage: Int
    @Attribute(.externalStorage) var photoData: Data?
    var createdAt: Date

    init(make: String,
         model: String,
         bodyCode: String = "",
         year: Int,
         engine: String = "",
         vin: String = "",
         plate: String = "",
         mileage: Int,
         photoData: Data? = nil) {
        self.make = make
        self.model = model
        self.bodyCode = bodyCode
        self.year = year
        self.engine = engine
        self.vin = vin
        self.plate = plate
        self.mileage = mileage
        self.photoData = photoData
        self.createdAt = .now
    }

    var displayName: String { "\(make) \(model)" }

    var subtitle: String {
        [bodyCode, String(year), engine].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}
