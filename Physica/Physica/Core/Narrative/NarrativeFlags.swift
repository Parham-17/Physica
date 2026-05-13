import Foundation
import Observation

/// In-memory store of narrative state — which dialogue beats have fired,
/// which Umbra glimpses the player has triggered, and other one-shot flags.
///
/// `DialogueController` writes to this when a beat plays; `ChapterController`
/// and module coordinators read from it to decide whether to re-fire something.
/// Long-term, this should be mirrored to a `NarrativeProgress` SwiftData model
/// so state survives app relaunch — currently session-scoped.
@Observable
final class NarrativeFlags {
    /// IDs of dialogue beats that have already fired this session.
    /// Beats marked `showOnce: true` in JSON consult this set before firing.
    var firedBeats: Set<String> = []

    /// Module-level identifiers for Umbra appearances the player has triggered.
    /// e.g. `"m3.mural7_silhouette"`, `"m4.shadow_flicker"`, `"m5.memory3_extra_silhouette"`.
    var umbraGlimpsesSeen: Set<String> = []

    /// Whether Umbra has spoken (only true after the M7 opening beat).
    var umbraSpoken: Bool = false

    // MARK: - Dialogue beats

    func markBeatFired(_ id: String) {
        firedBeats.insert(id)
    }

    func hasBeatFired(_ id: String) -> Bool {
        firedBeats.contains(id)
    }

    // MARK: - Umbra glimpses

    func markUmbraGlimpse(_ id: String) {
        umbraGlimpsesSeen.insert(id)
    }

    func hasSeenUmbraGlimpse(_ id: String) -> Bool {
        umbraGlimpsesSeen.contains(id)
    }

    // MARK: - Reset

    /// Debug / new-game helper — clears all session state.
    func resetAll() {
        firedBeats.removeAll()
        umbraGlimpsesSeen.removeAll()
        umbraSpoken = false
    }

    /// Clear all fired beats and Umbra glimpses for a single module — called
    /// when the player retries a completed module so its dialogue beats fire
    /// fresh.
    ///
    /// Beat IDs are conventionally namespaced by module slug (e.g. `m1_opening`,
    /// `m3.mural7_silhouette`). The slug is the part after the last `.` of the
    /// module ID: `"light-realm.m1"` → `"m1"`.
    func clearState(forModuleID moduleID: String) {
        let slug = moduleID.split(separator: ".").last.map(String.init) ?? moduleID
        let prefix = slug + "_"
        firedBeats = firedBeats.filter { !$0.hasPrefix(prefix) }
        umbraGlimpsesSeen = umbraGlimpsesSeen.filter {
            !$0.hasPrefix(slug + ".") && !$0.hasPrefix(prefix)
        }
    }
}
