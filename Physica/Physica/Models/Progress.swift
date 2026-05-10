import Foundation
import SwiftData

@Model
final class Progress {
    var totalXP: Int
    var currentStreakDays: Int
    var lastPlayedAt: Date?
    var earnedBadges: [String]
    var onboardingCompleted: Bool

    init() {
        self.totalXP = 0
        self.currentStreakDays = 0
        self.lastPlayedAt = nil
        self.earnedBadges = []
        self.onboardingCompleted = false
    }
}
