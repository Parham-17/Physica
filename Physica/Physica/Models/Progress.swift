import Foundation
import SwiftData

@Model
final class Progress {
    var totalXP: Int
    var currentStreakDays: Int
    var lastPlayedAt: Date?
    var earnedBadges: [String]

    init() {
        self.totalXP = 0
        self.currentStreakDays = 0
        self.lastPlayedAt = nil
        self.earnedBadges = []
    }
}
