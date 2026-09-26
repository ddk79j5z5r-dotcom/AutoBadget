import Foundation

enum Formatters {
    static let locale = Locale(identifier: "ru_RU")

    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .currency
        f.currencyCode = "RUB"
        f.currencySymbol = "₽"
        f.maximumFractionDigits = 0
        return f
    }()

    static let integer: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    static let decimal: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .decimal
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        return f
    }()

    static let dayMonthYear: DateFormatter = {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    static let dayMonthShort: DateFormatter = {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "d MMM"
        return f
    }()

    static let dayMonth: DateFormatter = {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "d MMMM"
        return f
    }()

    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    /// Ресурс «30 000 км / 24 мес.»; нулевые значения не показываются
    static func resource(km: Int, months: Int) -> String {
        [km > 0 ? km.km : nil, months > 0 ? "\(months) мес." : nil]
            .compactMap { $0 }
            .joined(separator: " / ")
    }

    /// Разбор пользовательского ввода: «1 234,50» → 1234.5
    static func parseNumber(_ text: String) -> Double? {
        let cleaned = text
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned)
    }
}

extension Double {
    var rub: String { Formatters.currency.string(from: NSNumber(value: self)) ?? "\(Int(self)) ₽" }

    /// Компактная запись для осей графиков: 12,5 тыс
    var rubShort: String {
        switch abs(self) {
        case 1_000_000...: return (Formatters.decimal.string(from: NSNumber(value: self / 1_000_000)) ?? "") + " млн"
        case 1_000...: return (Formatters.integer.string(from: NSNumber(value: self / 1_000)) ?? "") + " тыс"
        default: return Formatters.integer.string(from: NSNumber(value: self)) ?? ""
        }
    }

    var oneDecimal: String { Formatters.decimal.string(from: NSNumber(value: self)) ?? "\(self)" }
}

extension Int {
    var grouped: String { Formatters.integer.string(from: NSNumber(value: self)) ?? "\(self)" }
    var km: String { "\(grouped) км" }
}

extension String {
    /// «осталось 5 000 км» → «Осталось 5 000 км»
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

extension Date {
    var ruShort: String { Formatters.dayMonthYear.string(from: self) }
    var ruDayMonth: String { Formatters.dayMonth.string(from: self) }
    /// «2 сент.» для текущего года, «2 сент. 2025» — для прошлых
    var ruCompact: String {
        Calendar.current.isDate(self, equalTo: .now, toGranularity: .year)
            ? Formatters.dayMonthShort.string(from: self)
            : Formatters.dayMonthYear.string(from: self)
    }
    var ruMonthYear: String { Formatters.monthYear.string(from: self).capitalized(with: Formatters.locale) }
    var year: Int { Calendar.current.component(.year, from: self) }
    var startOfMonth: Date { Calendar.current.dateInterval(of: .month, for: self)?.start ?? self }
}

enum Plural {
    /// Русские формы множественного числа: 1 ремонт, 2 ремонта, 5 ремонтов
    static func form(_ n: Int, _ one: String, _ few: String, _ many: String) -> String {
        let n10 = n % 10, n100 = n % 100
        if n10 == 1 && n100 != 11 { return one }
        if (2...4).contains(n10) && !(12...14).contains(n100) { return few }
        return many
    }

    static func days(_ n: Int) -> String { "\(n) \(form(n, "день", "дня", "дней"))" }
}

/// Подписи ресурса — общие для напоминаний и деталей
extension ServiceLifeTracked {
    /// «осталось 5 000 км · 120 дней», «осталось 32 дня», «перепробег 1 200 км»
    func remainingDescription(currentMileage: Int, now: Date = .now) -> String {
        var left: [String] = []
        var overdue: [String] = []
        if let km = remainingKm(currentMileage: currentMileage) {
            if km >= 0 { left.append(km.km) } else { overdue.append("перепробег \(abs(km).km)") }
        }
        if let days = remainingDays(from: now) {
            if days >= 0 { left.append(Plural.days(days)) } else { overdue.append("просрочено на \(Plural.days(abs(days)))") }
        }
        let leftText = left.isEmpty ? nil : "осталось " + left.joined(separator: " · ")
        return (overdue + [leftText].compactMap { $0 }).joined(separator: " · ")
    }

    /// «30 000 км / 24 мес.»
    var resourceDescription: String { Formatters.resource(km: lifeKm, months: lifeMonths) }

    /// «460 000 км или 12 окт. 2027»
    var nextServiceDescription: String {
        [nextMileage?.km, nextDate?.ruShort].compactMap { $0 }.joined(separator: " или ")
    }
}
