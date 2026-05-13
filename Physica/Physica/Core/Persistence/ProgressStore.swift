import Foundation
import SwiftData

struct ProgressStore {
    let context: ModelContext

    func recordLevelCompletion(levelID: String, stars: Int, xp: Int = 50) {
        let descriptor = FetchDescriptor<Level>(predicate: #Predicate { $0.id == levelID })
        guard let level = try? context.fetch(descriptor).first else { return }

        let isFirstCompletion = (level.completedAt == nil)
        level.starsEarned = max(level.starsEarned, stars)
        if isFirstCompletion {
            level.completedAt = Date()
        }

        if let progress = try? context.fetch(FetchDescriptor<Progress>()).first {
            // Only award XP on first completion — replaying a module shouldn't
            // farm XP. Stars still upgrade (max-of) regardless.
            if isFirstCompletion {
                progress.totalXP += xp
            }
            progress.lastPlayedAt = Date()
        }

        unlockNextRealmIfReady(after: level)
        try? context.save()
    }

    func isLevelUnlocked(_ level: Level) -> Bool {
        guard let realm = level.realm, realm.isUnlocked else { return false }
        if level.number == 1 { return true }

        let sorted = realm.levels.sorted { $0.number < $1.number }
        if level.isBoss {
            return sorted.first(where: { $0.number == 5 })?.isCompleted ?? false
        }
        let prev = sorted.first { $0.number == level.number - 1 }
        return prev?.isCompleted ?? false
    }

    var totalXP: Int {
        ((try? context.fetch(FetchDescriptor<Progress>()))?.first?.totalXP) ?? 0
    }

    private func unlockNextRealmIfReady(after level: Level) {
        guard level.isBoss, let realm = level.realm else { return }
        let allRealms = (try? context.fetch(FetchDescriptor<Realm>(sortBy: [SortDescriptor(\.order)]))) ?? []
        guard let idx = allRealms.firstIndex(where: { $0.id == realm.id }),
              idx + 1 < allRealms.count else { return }
        allRealms[idx + 1].isUnlocked = true
    }
}
