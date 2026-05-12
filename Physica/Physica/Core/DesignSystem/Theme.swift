import SwiftUI

extension Color {
    // Spark palette (universal — used everywhere Spark appears)
    static let sparkBrass = Color(red: 0.78, green: 0.51, blue: 0.27)
    static let sparkBrassLight = Color(red: 0.92, green: 0.65, blue: 0.36)

    // Light Realm accent palette (World 1)
    static let realmDark = Color(red: 0.04, green: 0.05, blue: 0.10)
    static let realmMid = Color(red: 0.10, green: 0.12, blue: 0.20)
    static let beaconYellow = Color(red: 1.0, green: 0.78, blue: 0.36)
    static let beaconWarm = Color(red: 1.0, green: 0.55, blue: 0.20)

    // Volt City accent palette (World 2, stretch)
    static let electricBlue = Color(red: 0.32, green: 0.67, blue: 0.96)
    static let sparkYellow = Color(red: 1.0, green: 0.84, blue: 0.32)
}

enum WorldTheme {
    case light
    case volt
    // Worlds 3–5 TBD

    var background: Color {
        switch self {
        case .light: return .realmDark
        case .volt: return Color(red: 0.05, green: 0.08, blue: 0.16)
        }
    }

    var accent: Color {
        switch self {
        case .light: return .beaconYellow
        case .volt: return .electricBlue
        }
    }
}
