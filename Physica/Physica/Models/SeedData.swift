import Foundation
import SwiftData

enum SeedData {
    /// Light Realm — World 1 modules, per PIPELINE.md §7.
    private static let lightModules: [(id: String, number: Int, title: String)] = [
        ("light-realm.m1", 1, "The Sleeping Beacon"),
        ("light-realm.m2", 2, "The Line of Dawn"),
        ("light-realm.m3", 3, "Shadow Garden"),
        ("light-realm.m4", 4, "Crystal Gate"),
        ("light-realm.m5", 5, "Pinhole Studio"),
        ("light-realm.m6", 6, "Mirrorworks"),
        ("light-realm.m7", 7, "Eclipse Tower")
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
        // World 1 — Light Realm (V1 scope)
        let light = Realm(
            id: "light-realm",
            displayName: "Light Realm",
            subtitle: "Light & Shadows",
            order: 1,
            isUnlocked: true
        )
        for entry in lightModules {
            let module = Level(id: entry.id, number: entry.number, title: entry.title)
            module.realm = light
            light.levels.append(module)
        }
        context.insert(light)

        // Worlds 2–5 — locked placeholders. Modules ship when each world enters scope.
        let volt = Realm(
            id: "volt-city",
            displayName: "Volt City",
            subtitle: "Electricity & Circuits",
            order: 2,
            isUnlocked: false
        )
        let magnetic = Realm(
            id: "magnetic-peaks",
            displayName: "Magnetic Peaks",
            subtitle: "Magnetism",
            order: 3,
            isUnlocked: false
        )
        let echo = Realm(
            id: "echo-valley",
            displayName: "Echo Valley",
            subtitle: "Sound & Vibration",
            order: 4,
            isUnlocked: false
        )
        let drift = Realm(
            id: "drift-plains",
            displayName: "Drift Plains",
            subtitle: "Air & Pressure",
            order: 5,
            isUnlocked: false
        )

        context.insert(volt)
        context.insert(magnetic)
        context.insert(echo)
        context.insert(drift)
    }
}
