import SwiftUI

extension Color {
    // Volt City palette
    static let voltCopper = Color(red: 0.78, green: 0.51, blue: 0.27)
    static let voltCopperBright = Color(red: 0.92, green: 0.65, blue: 0.36)
    static let voltBlue = Color(red: 0.32, green: 0.67, blue: 0.96)
    static let voltYellow = Color(red: 1.0, green: 0.84, blue: 0.32)

    // Shadow Realm palette
    static let shadowDeep = Color(red: 0.04, green: 0.05, blue: 0.10)
    static let shadowMid = Color(red: 0.10, green: 0.12, blue: 0.20)
    static let torchYellow = Color(red: 1.0, green: 0.78, blue: 0.36)
    static let torchWarm = Color(red: 1.0, green: 0.55, blue: 0.20)
}

enum RealmTheme {
    case shadow
    case volt

    var background: Color {
        switch self {
        case .shadow: return .shadowDeep
        case .volt: return Color(red: 0.05, green: 0.08, blue: 0.16)
        }
    }

    var accent: Color {
        switch self {
        case .shadow: return .torchYellow
        case .volt: return .voltBlue
        }
    }
}
