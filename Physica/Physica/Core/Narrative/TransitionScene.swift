import Foundation

/// A 15–30 second between-module scene. Per PIPELINE.md §5.5: Spark visibly
/// moves to the next location, says 1–2 reflective lines, and the world state
/// is shown restored from the previous chapter. Tap-to-skip is allowed after
/// `skipDelay` seconds.
///
/// For Phase 1, transitions are data — actual SwiftUI/SpriteKit rendering of
/// these scenes lands in Phase 2 (vertical slice). The data captures *what*
/// should appear; rendering decides *how*.
struct TransitionScene: Hashable {
    let fromModuleID: String
    let toModuleID: String
    let lines: [String]

    /// Total runtime. Tap-to-skip only kicks in after `skipDelay`.
    let duration: TimeInterval

    /// Player can tap to skip after this many seconds (PIPELINE.md §5.5 says 3s).
    let skipDelay: TimeInterval

    static let defaultDuration: TimeInterval = 22
    static let defaultSkipDelay: TimeInterval = 3
}

extension TransitionScene {
    /// Canonical Light Realm transitions. Phase 2 will replace the placeholder
    /// `lines` with the writer-approved versions and add scene-specific art cues.
    static let lightRealm: [TransitionScene] = [
        TransitionScene(
            fromModuleID: "light-realm.m1",
            toModuleID: "light-realm.m2",
            lines: [
                "There's a path forward. The light is showing us the way.",
                "Wherever the light goes here, it goes straight."
            ],
            duration: defaultDuration,
            skipDelay: defaultSkipDelay
        ),
        TransitionScene(
            fromModuleID: "light-realm.m2",
            toModuleID: "light-realm.m3",
            lines: [
                "Let's see what happens when something tries to block more than just stone."
            ],
            duration: defaultDuration,
            skipDelay: defaultSkipDelay
        ),
        TransitionScene(
            fromModuleID: "light-realm.m3",
            toModuleID: "light-realm.m4",
            lines: [
                "Something was there.",
                "Let's keep moving."
            ],
            duration: defaultDuration,
            skipDelay: defaultSkipDelay
        ),
        TransitionScene(
            fromModuleID: "light-realm.m4",
            toModuleID: "light-realm.m5",
            lines: [
                "Materials. Properties. Everything has a story written in how light passes through it."
            ],
            duration: defaultDuration,
            skipDelay: defaultSkipDelay
        ),
        TransitionScene(
            fromModuleID: "light-realm.m5",
            toModuleID: "light-realm.m6",
            lines: [
                "I think I'm starting to remember who I was."
            ],
            duration: defaultDuration,
            skipDelay: defaultSkipDelay
        ),
        TransitionScene(
            fromModuleID: "light-realm.m6",
            toModuleID: "light-realm.m7",
            lines: [
                "There's only one tower left now.",
                "And whatever's up there has been waiting."
            ],
            duration: defaultDuration,
            skipDelay: defaultSkipDelay
        )
    ]

    static func transition(from moduleID: String) -> TransitionScene? {
        lightRealm.first(where: { $0.fromModuleID == moduleID })
    }
}
