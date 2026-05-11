import Foundation

/// Derives the player's rank/level from cumulative XP.
///
/// Each level requires `xpPerLevel` (100 XP). Since each mission awards 50 XP,
/// a level is earned every 2 missions.
struct PlayerLevel: Equatable {
    static let xpPerLevel: Int = 100

    let level: Int
    let title: String
    let xpInLevel: Int
    let xpForNextLevel: Int

    var progress: Double {
        guard xpForNextLevel > 0 else { return 0 }
        return Double(xpInLevel) / Double(xpForNextLevel)
    }

    init(totalXP: Int) {
        let safeXP = max(0, totalXP)
        let computedLevel = safeXP / Self.xpPerLevel + 1
        self.level = computedLevel
        self.xpInLevel = safeXP % Self.xpPerLevel
        self.xpForNextLevel = Self.xpPerLevel
        self.title = Self.title(for: computedLevel)
    }

    private static func title(for level: Int) -> String {
        switch level {
        case 1: return "Spark Apprentice"
        case 2: return "Curious Explorer"
        case 3: return "Light Seeker"
        case 4: return "Circuit Tinkerer"
        case 5: return "World Mender"
        default: return "Physics Hero"
        }
    }
}
