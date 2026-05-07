import Foundation
import SwiftData

extension ModelContainer {
    static func physica() -> ModelContainer {
        let schema = Schema([Realm.self, Level.self, Progress.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            SeedData.populateIfNeeded(container.mainContext)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    static func previewPhysica() -> ModelContainer {
        let schema = Schema([Realm.self, Level.self, Progress.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            SeedData.populateIfNeeded(container.mainContext)
            return container
        } catch {
            fatalError("Could not create preview ModelContainer: \(error)")
        }
    }
}
