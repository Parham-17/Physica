import Foundation
import Observation

/// Orchestrates the player's journey across modules: which module is active,
/// when a transition is playing, and what comes next.
///
/// Modules call `completeModule(_:)` when their puzzle is solved and the
/// Spark Connection beat has dismissed. ChapterController looks up the next
/// module via the world sequence, kicks off the transition, then advances
/// to the next module's scene.
@Observable
final class ChapterController {

    enum Phase: Hashable {
        case idle
        case playingModule(moduleID: String)
        case playingTransition(TransitionScene)
        case worldComplete(worldID: String)
    }

    private(set) var phase: Phase = .idle

    private let flags: NarrativeFlags

    init(flags: NarrativeFlags) {
        self.flags = flags
    }

    // MARK: - Module lifecycle

    func startModule(_ moduleID: String) {
        phase = .playingModule(moduleID: moduleID)
    }

    /// Called when the module's puzzle is solved AND its Spark Connection
    /// beat has dismissed. Looks up the next module in the world sequence
    /// and either plays the transition, or marks the world complete.
    func completeModule(_ moduleID: String) {
        if let next = Self.nextModuleID(after: moduleID),
           let transition = TransitionScene.transition(from: moduleID) {
            phase = .playingTransition(transition)
            _ = next
        } else {
            phase = .worldComplete(worldID: Self.worldID(forModule: moduleID))
        }
    }

    /// Called when the transition is dismissed (auto-finish after duration, or
    /// user tap-to-skip after `skipDelay`). Advances to the next module's scene.
    func finishTransition() {
        guard case .playingTransition(let transition) = phase else { return }
        phase = .playingModule(moduleID: transition.toModuleID)
    }

    /// Force-exit back to idle (player tapped Home / world map).
    func leaveActiveScene() {
        phase = .idle
    }

    // MARK: - Sequence

    /// Light Realm module order. Future worlds register their own sequences here.
    static let lightRealmSequence: [String] = [
        "light-realm.m1",
        "light-realm.m2",
        "light-realm.m3",
        "light-realm.m4",
        "light-realm.m5",
        "light-realm.m6",
        "light-realm.m7"
    ]

    static func nextModuleID(after current: String) -> String? {
        guard let idx = lightRealmSequence.firstIndex(of: current),
              idx + 1 < lightRealmSequence.count else { return nil }
        return lightRealmSequence[idx + 1]
    }

    /// World ID is the prefix before the first `.` — `"light-realm.m1"` → `"light-realm"`.
    static func worldID(forModule moduleID: String) -> String {
        moduleID.split(separator: ".").first.map(String.init) ?? moduleID
    }
}
