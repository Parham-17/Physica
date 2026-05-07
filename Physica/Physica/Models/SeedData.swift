import Foundation
import SwiftData

enum SeedData {
    private static let shadowLevelTitles = [
        "First Light",
        "Things That Block",
        "Closer & Bigger",
        "Match the Shadow",
        "Through Or Not"
    ]

    private static let voltLevelTitles = [
        "Close the Loop",
        "Cut the Wire",
        "Flip the Switch",
        "What Lets It Through",
        "Two Lights, One Battery"
    ]

    static func populateIfNeeded(_ context: ModelContext) {
        let existingRealms = (try? context.fetch(FetchDescriptor<Realm>())) ?? []
        if existingRealms.isEmpty {
            seedRealms(into: context)
        }

        let existingProgress = (try? context.fetch(FetchDescriptor<Progress>())) ?? []
        if existingProgress.isEmpty {
            context.insert(Progress())
        }

        try? context.save()
    }

    private static func seedRealms(into context: ModelContext) {
        let shadow = Realm(
            id: "shadow-realm",
            displayName: "Shadow Realm",
            subtitle: "Light & Shadows",
            order: 1,
            isUnlocked: true
        )
        for (i, title) in shadowLevelTitles.enumerated() {
            let level = Level(id: "shadow-realm.\(i + 1)", number: i + 1, title: title)
            level.realm = shadow
            shadow.levels.append(level)
        }
        let shadowBoss = Level(id: "shadow-realm.boss", number: 99, title: "Escape the Cave")
        shadowBoss.realm = shadow
        shadow.levels.append(shadowBoss)

        let volt = Realm(
            id: "volt-city",
            displayName: "Volt City",
            subtitle: "Electricity & Circuits",
            order: 2,
            isUnlocked: false
        )
        for (i, title) in voltLevelTitles.enumerated() {
            let level = Level(id: "volt-city.\(i + 1)", number: i + 1, title: title)
            level.realm = volt
            volt.levels.append(level)
        }
        let voltBoss = Level(id: "volt-city.boss", number: 99, title: "Repair the Robot")
        voltBoss.realm = volt
        volt.levels.append(voltBoss)

        context.insert(shadow)
        context.insert(volt)
    }
}
