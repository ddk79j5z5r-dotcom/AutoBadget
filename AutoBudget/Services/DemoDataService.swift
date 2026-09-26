import Foundation
import SwiftData

/// Демо-данные: Toyota Aristo JZS160, 1998, 2JZ-GE, 430 000 км
@MainActor
enum DemoDataService {
    static func seedIfNeeded(_ context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Car>())) ?? 0
        guard count == 0 else { return }
        seed(context)
    }

    static func reset(_ context: ModelContext) {
        DataService.deleteAll(in: context)
        seed(context)
    }

    static func seed(_ context: ModelContext) {
        let car = Car(make: "Toyota",
                      model: "Aristo",
                      bodyCode: "JZS160",
                      year: 1998,
                      engine: "2JZ-GE",
                      vin: "JZS160-0071345",
                      plate: "А160РС 178",
                      mileage: 430_000)
        context.insert(car)

        seedRepairs(context)
        seedExpenses(context)
        seedReminders(context)

        try? context.save()
    }

    // MARK: - Repairs (каждый ремонт дублируется в бюджет, детали ставятся на учёт)

    private static func seedRepairs(_ context: ModelContext) {
        // Хронологический порядок важен: новая деталь снимает с учёта ранее установленную на той же позиции
        let repairs: [(RepairRecord, [Part])] = [
            (RepairRecord(title: "Замена ремня ГРМ и помпы",
                          category: .engine,
                          date: date(2021, 11, 10),
                          mileage: 342_000,
                          worksDone: "Замена ремня ГРМ, натяжного и обводного роликов, помпы",
                          partsUsed: "Ролики ГРМ, антифриз",
                          laborCost: 6_000,
                          partsCost: 14_500,
                          shop: "Garage 2JZ"),
             [Part(name: "Ремень ГРМ", category: .engine, manufacturer: "Gates", articleNumber: "T254",
                   serviceLifeKm: 100_000, serviceLifeMonths: 60, purchasePrice: 4_200),
              Part(name: "Помпа", category: .engine, manufacturer: "Aisin", articleNumber: "WPT-060",
                   serviceLifeKm: 100_000, purchasePrice: 5_800)]),
            (RepairRecord(title: "Ремонт коробки передач",
                          category: .gearbox,
                          date: date(2024, 6, 14),
                          mileage: 398_700,
                          worksDone: "Снятие/установка АКПП, дефектовка, замена фрикционов и сальников, промывка гидроблока",
                          partsUsed: "Ремкомплект АКПП, пакет фрикционов, фильтр АКПП",
                          laborCost: 38_000,
                          partsCost: 42_500,
                          shop: "АКПП-Сервис на Обводном",
                          comment: "Пинки при переключении 2→3. После ремонта — гарантия 12 мес."),
             [Part(name: "Масло АКПП (ATF)", category: .gearbox, manufacturer: "Toyota", articleNumber: "08886-01705",
                   serviceLifeKm: 40_000, purchasePrice: 9_600, notes: "ATF Type T-IV, 12 л")]),
            (RepairRecord(title: "Замена колодок и дисков",
                          category: .brakes,
                          date: date(2024, 10, 28),
                          mileage: 402_000,
                          worksDone: "Замена передних тормозных дисков и колодок, замена тормозной жидкости",
                          laborCost: 3_000,
                          partsCost: 9_800,
                          shop: "Тормоза+"),
             [Part(name: "Передние колодки", category: .brakes, manufacturer: "Akebono", articleNumber: "AN-690WK",
                   serviceLifeKm: 30_000, purchasePrice: 3_900),
              Part(name: "Тормозные диски", category: .brakes, manufacturer: "Brembo", articleNumber: "09.A717.10",
                   serviceLifeKm: 60_000, purchasePrice: 5_100),
              Part(name: "Тормозная жидкость", category: .brakes, manufacturer: "Toyota", articleNumber: "DOT4",
                   serviceLifeMonths: 24, purchasePrice: 800)]),
            (RepairRecord(title: "Плановое ТО",
                          category: .service,
                          date: date(2025, 1, 20),
                          mileage: 407_900,
                          worksDone: "Замена моторного масла, масляного и воздушного фильтров",
                          laborCost: 1_800,
                          partsCost: 6_200,
                          shop: "Garage 2JZ"),
             [Part(name: "Моторное масло", category: .service, manufacturer: "Mobil 1", articleNumber: "5W-30, 5 л",
                   serviceLifeKm: 7_500, serviceLifeMonths: 12, purchasePrice: 4_300),
              Part(name: "Масляный фильтр", category: .service, manufacturer: "Toyota", articleNumber: "90915-YZZD2",
                   serviceLifeKm: 7_500, serviceLifeMonths: 12, purchasePrice: 700),
              Part(name: "Воздушный фильтр", category: .service, manufacturer: "Mann", articleNumber: "C 26 003",
                   serviceLifeKm: 15_000, serviceLifeMonths: 12, purchasePrice: 1_200)]),
            (RepairRecord(title: "Замена топливного насоса",
                          category: .engine,
                          date: date(2025, 4, 22),
                          mileage: 412_300,
                          worksDone: "Замена топливного насоса в баке, проверка давления топлива",
                          partsUsed: "Сетка насоса",
                          laborCost: 5_000,
                          partsCost: 8_500,
                          shop: "Garage 2JZ",
                          comment: "Машина глохла на горячую, падало давление топлива."),
             [Part(name: "Топливный насос", category: .engine, manufacturer: "Denso", articleNumber: "195130-7010",
                   serviceLifeKm: 150_000, purchasePrice: 8_100)]),
            (RepairRecord(title: "Плановое ТО",
                          category: .service,
                          date: date(2025, 8, 2),
                          mileage: 415_100,
                          worksDone: "Замена масла, масляного фильтра, свечей зажигания",
                          laborCost: 2_500,
                          partsCost: 9_800,
                          shop: "Garage 2JZ"),
             [Part(name: "Моторное масло", category: .service, manufacturer: "Mobil 1", articleNumber: "5W-30, 5 л",
                   serviceLifeKm: 7_500, serviceLifeMonths: 12, purchasePrice: 4_400),
              Part(name: "Масляный фильтр", category: .service, manufacturer: "Toyota", articleNumber: "90915-YZZD2",
                   serviceLifeKm: 7_500, serviceLifeMonths: 12, purchasePrice: 700),
              Part(name: "Свечи зажигания", category: .engine, manufacturer: "Denso", articleNumber: "IK20 ×6",
                   serviceLifeKm: 30_000, purchasePrice: 4_700)]),
            (RepairRecord(title: "Замена генератора",
                          category: .electrics,
                          date: date(2026, 1, 18),
                          mileage: 421_900,
                          worksDone: "Диагностика зарядки, замена генератора",
                          laborCost: 2_500,
                          partsCost: 14_000,
                          shop: "Автоэлектрик Сергей"),
             [Part(name: "Генератор", category: .electrics, manufacturer: "Denso (восст.)", articleNumber: "27060-46090",
                   serviceLifeKm: 150_000, purchasePrice: 14_000)]),
            (RepairRecord(title: "Обслуживание подвески",
                          category: .suspension,
                          date: date(2026, 4, 12),
                          mileage: 424_600,
                          worksDone: "Замена сайлентблоков передних рычагов, стоек стабилизатора, развал-схождение",
                          laborCost: 9_500,
                          partsCost: 16_800,
                          shop: "Подвеска-Про",
                          comment: "Стук спереди на неровностях — устранён."),
             [Part(name: "Сайлентблоки передних рычагов", category: .suspension, manufacturer: "Toyota",
                   articleNumber: "48655-30150", serviceLifeKm: 80_000, purchasePrice: 11_200),
              Part(name: "Стойки стабилизатора", category: .suspension, manufacturer: "555",
                   articleNumber: "SL-3710", serviceLifeKm: 60_000, purchasePrice: 5_600)]),
            (RepairRecord(title: "Плановое ТО",
                          category: .service,
                          date: date(2026, 7, 20),
                          mileage: 428_100,
                          worksDone: "Замена моторного масла, масляного, воздушного и салонного фильтров",
                          laborCost: 2_000,
                          partsCost: 7_400,
                          shop: "Garage 2JZ"),
             [Part(name: "Моторное масло", category: .service, manufacturer: "Mobil 1", articleNumber: "5W-30, 5 л",
                   serviceLifeKm: 7_500, serviceLifeMonths: 12, purchasePrice: 4_600),
              Part(name: "Масляный фильтр", category: .service, manufacturer: "Toyota", articleNumber: "90915-YZZD2",
                   serviceLifeKm: 7_500, serviceLifeMonths: 12, purchasePrice: 750),
              Part(name: "Воздушный фильтр", category: .service, manufacturer: "Mann", articleNumber: "C 26 003",
                   serviceLifeKm: 15_000, serviceLifeMonths: 12, purchasePrice: 1_250),
              Part(name: "Салонный фильтр", category: .service, manufacturer: "Denso", articleNumber: "DCC-1009",
                   serviceLifeKm: 15_000, serviceLifeMonths: 12, purchasePrice: 800)]),
            (RepairRecord(title: "Полировка фар и перекрас бампера",
                          category: .body,
                          date: date(2026, 9, 2),
                          mileage: 429_700,
                          worksDone: "Восстановительная полировка фар, локальный окрас переднего бампера",
                          partsUsed: "Краска, лак",
                          laborCost: 9_000,
                          partsCost: 2_500,
                          shop: "Кузовной цех «Гранд»"),
             []),
        ]
        for (repair, parts) in repairs {
            context.insert(repair)
            for part in parts {
                context.insert(part)
                part.repair = repair
                part.installDate = repair.date
                part.installMileage = repair.mileage
                DataService.registerInstallation(of: part, in: context)
            }
            DataService.syncExpense(for: repair, in: context)
            // Сохраняем после каждого ремонта, чтобы следующий видел установленные детали
            try? context.save()
        }
    }

    // MARK: - Expenses

    private static func seedExpenses(_ context: ModelContext) {
        var rng = SeededGenerator(seed: 160)
        let cal = Calendar.current
        let now = Date.now
        let start = cal.date(byAdding: .day, value: -364, to: now)!
        let startKm = 417_200.0, endKm = 430_000.0
        let stations = ["Лукойл", "Газпромнефть", "Роснефть", "Shell", "Татнефть"]

        // Заправки каждые 10–16 дней; литры считаются от пройденного расстояния (~13 л/100 км)
        var day = 0
        var previousKm = startKm
        while day <= 360 {
            let d = cal.date(byAdding: .day, value: day, to: start)!
            let km = startKm + (endKm - startKm) * Double(day) / 364
            let distance = km - previousKm
            let liters = day == 0 ? 55 : (distance * Double.random(in: 0.124...0.14, using: &rng)).rounded()
            // Каждая пятая заправка — АИ-98
            let fuelType: FuelType = Int.random(in: 0..<5, using: &rng) == 0 ? .ai98 : .ai95
            let basePrice = fuelType == .ai98 ? 67.4 : 58.9
            let price = basePrice + Double(day) / 360 * 5 + Double.random(in: -0.6...0.6, using: &rng)
            context.insert(Expense(category: .fuel,
                                   title: ExpenseCategory.fuel.defaultTitle,
                                   date: d,
                                   amount: (liters * price).rounded(),
                                   mileage: Int(km),
                                   place: stations.randomElement(using: &rng)!,
                                   liters: liters,
                                   fuelType: fuelType))
            previousKm = km
            day += Int.random(in: 10...16, using: &rng)
        }

        func kmAt(_ d: Date) -> Int {
            let t = min(max(d.timeIntervalSince(start) / now.timeIntervalSince(start), 0), 1)
            return Int(startKm + (endKm - startKm) * t)
        }
        func ago(_ days: Int) -> Date { cal.date(byAdding: .day, value: -days, to: now)! }

        let misc: [(ExpenseCategory, String, Date, Double, String, String)] = [
            (.tires, "Зимняя резина Nokian Hakkapeliitta 225/55 R16", ago(340), 38_400, "Колёса Даром", "Комплект 4 шт."),
            (.tires, "Сезонный шиномонтаж", ago(338), 2_400, "Шиномонтаж 24", ""),
            (.tires, "Сезонный шиномонтаж", ago(160), 2_400, "Шиномонтаж 24", "Переобувка на лето"),
            (.taxes, "Транспортный налог", ago(300), 16_500, "Госуслуги", "220 л.с. × 75 ₽"),
            (.insurance, "ОСАГО", date(2026, 3, 10), 14_800, "Ингосстрах", "Без ограничений по водителям"),
            (.insurance, "КАСКО (частичное)", date(2026, 3, 12), 21_000, "Ингосстрах", "Угон + тотал"),
            (.parts, "Щётки стеклоочистителя", ago(330), 1_850, "Exist.ru", "Bosch Aerotwin"),
            (.parts, "Аккумулятор 75Ah", ago(250), 9_500, "Автозапчасти 78", "Varta Blue Dynamic"),
            (.parts, "Лампы ближнего света D2S", ago(95), 4_300, "Exist.ru", ""),
            (.tuning, "Линзы Bi-LED", ago(120), 12_000, "LightLab", "Установка в фары"),
            (.tuning, "Шумоизоляция дверей", ago(60), 18_000, "Тишина-Авто", "4 двери, вибродемпфер + сплен"),
            (.maintenance, "Мойка и химчистка салона", ago(200), 6_500, "Detailing Club", ""),
            (.maintenance, "Замена антифриза", ago(45), 3_900, "Garage 2JZ", "Toyota SLLC 6 л"),
            (.maintenance, "Мойка кузова", ago(12), 900, "Мойка «Капля»", ""),
        ]
        for item in misc {
            context.insert(Expense(category: item.0, title: item.1, date: item.2, amount: item.3,
                                   mileage: kmAt(item.2), comment: item.5, place: item.4))
        }
    }

    // MARK: - Reminders

    /// Напоминания — для процедур и документов. Масло, фильтры, колодки и ремень ГРМ
    /// отслеживаются как детали, чтобы одно и то же событие не появлялось дважды.
    private static func seedReminders(_ context: ModelContext) {
        let reminders = [
            Reminder(kind: .osago, lastDate: date(2026, 3, 10), lastMileage: 423_500, notifyDaysBefore: 14),
            Reminder(kind: .inspection, lastDate: date(2024, 10, 15), lastMileage: 401_000, notifyDaysBefore: 14),
        ]
        reminders.forEach(context.insert)
        reminders.forEach(NotificationService.shared.schedule)
    }

    private static func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: 12)) ?? .now
    }
}

/// Детерминированный генератор, чтобы демо-данные были одинаковыми при каждом запуске
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
