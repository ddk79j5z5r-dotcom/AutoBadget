import SwiftUI

enum Theme {
    // MARK: Colors
    static let accent = Color(hex: 0x00D4AA)
    static let accentDeep = Color(hex: 0x00A887)
    static let background = Color.black
    static let card = Color(hex: 0x16171A)
    static let cardElevated = Color(hex: 0x202226)
    static let field = Color(hex: 0x26282D)
    static let stroke = Color.white.opacity(0.07)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.62)
    static let textTertiary = Color(white: 0.40)
    static let danger = Color(hex: 0xFF5A5F)
    static let warning = Color(hex: 0xFFB547)
    static let critical = Color(hex: 0xFF7A3D)

    // MARK: Metrics
    static let radius: CGFloat = 20
    static let smallRadius: CGFloat = 14
    static let padding: CGFloat = 16

    // MARK: Motion
    static let spring = Animation.spring(response: 0.42, dampingFraction: 0.82)
    static let snappy = Animation.spring(response: 0.28, dampingFraction: 0.75)

    static let accentGradient = LinearGradient(colors: [accent, accentDeep],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

extension ExpenseCategory {
    var color: Color {
        switch self {
        case .fuel: Color(hex: 0x2FC86B)
        case .maintenance: Color(hex: 0x3D7BFF)
        case .tires: Color(hex: 0x8E5CFF)
        case .tuning: Color(hex: 0xFF4FA3)
        case .insurance: Color(hex: 0x19B5E8)
        case .taxes: Color(hex: 0xFFB020)
        case .repair: Color(hex: 0xFF4D4F)
        case .parts: Color(hex: 0xFF7A1A)
        }
    }

    var symbol: String {
        switch self {
        case .fuel: "fuelpump.fill"
        case .maintenance: "wrench.fill"
        case .tires: "circle.circle"
        case .tuning: "paintbrush.pointed.fill"
        case .insurance: "checkmark.shield.fill"
        case .taxes: "doc.text.fill"
        case .repair: "hammer.fill"
        case .parts: "gearshape.fill"
        }
    }
}

extension RepairCategory {
    var color: Color {
        switch self {
        case .engine: Color(hex: 0xFF7A45)
        case .gearbox: Color(hex: 0xA66CFF)
        case .suspension: Color(hex: 0x4D8DFF)
        case .brakes: Color(hex: 0xFF5A5F)
        case .electrics: Color(hex: 0xFFD166)
        case .body: Color(hex: 0x8E9AAF)
        case .interior: Color(hex: 0xE58FD8)
        case .service: Theme.accent
        }
    }
}

extension ServiceStatus {
    var color: Color {
        switch self {
        case .ok: Theme.accent
        case .warning: Theme.warning
        case .critical: Theme.critical
        case .overdue: Theme.danger
        }
    }
}

extension FuelType {
    /// Цвет серии на графиках цены топлива
    var color: Color {
        switch self {
        case .ai92: Color(hex: 0x4D8DFF)
        case .ai95: ExpenseCategory.fuel.color
        case .ai98: Color(hex: 0xA66CFF)
        case .ai100: Color(hex: 0xFF4FA3)
        case .diesel: Color(hex: 0xFFB020)
        case .lpg: Color(hex: 0x19B5E8)
        case .other: Color(hex: 0x8E9AAF)
        }
    }
}
