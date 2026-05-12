import SwiftUI
import SwiftData

@main
struct PhysicaApp: App {
    let modelContainer: ModelContainer
    @State private var router: AppRouter
    @State private var audioManager: AudioManager
    @State private var narrativeFlags: NarrativeFlags
    @State private var dialogue: DialogueController
    @State private var chapterController: ChapterController

    init() {
        let flags = NarrativeFlags()
        _router = State(initialValue: AppRouter())
        _audioManager = State(initialValue: AudioManager())
        _narrativeFlags = State(initialValue: flags)
        _dialogue = State(initialValue: DialogueController(flags: flags))
        _chapterController = State(initialValue: ChapterController(flags: flags))
        self.modelContainer = ModelContainer.physica()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(audioManager)
                .environment(narrativeFlags)
                .environment(dialogue)
                .environment(chapterController)
        }
        .modelContainer(modelContainer)
    }
}
