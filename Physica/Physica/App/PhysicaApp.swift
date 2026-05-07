import SwiftUI
import SwiftData

@main
struct PhysicaApp: App {
    let modelContainer: ModelContainer
    @State private var router = AppRouter()
    @State private var audioManager = AudioManager()

    init() {
        self.modelContainer = ModelContainer.physica()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(audioManager)
        }
        .modelContainer(modelContainer)
    }
}
