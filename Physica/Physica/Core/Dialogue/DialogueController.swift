import Foundation
import Observation

/// Orchestrates dialogue playback for the active module.
///
/// Lifecycle:
/// 1. Module load → `loadScript(filename:)` parses JSON via `DialogueLoader`.
/// 2. Gameplay triggers → `fire(trigger:)` looks up the matching beat,
///    consults `NarrativeFlags` to respect `showOnce`, sets `activeBeat`.
/// 3. The dialogue overlay reads `activeBeat` + `currentLineIndex` and renders.
/// 4. Player taps to advance → `advanceLine()`; final line dismisses.
@Observable
final class DialogueController {
    // MARK: - Public state (read by overlay view)

    private(set) var activeScript: DialogueScript?
    private(set) var activeBeat: DialogueBeat?
    var currentLineIndex: Int = 0
    var isTypewriterComplete: Bool = false

    private let flags: NarrativeFlags

    init(flags: NarrativeFlags) {
        self.flags = flags
    }

    // MARK: - Script loading

    /// Load a module's dialogue script. Idempotent for the same module.
    func loadScript(filename: String) throws {
        if activeScript?.module == filename { return }
        activeScript = try DialogueLoader.load(filename)
    }

    /// Drop the active script — call when leaving a module.
    func unloadScript() {
        activeScript = nil
        dismissBeat()
    }

    // MARK: - Beat firing

    /// Fire the beat whose `trigger` matches `triggerID`. Returns whether a beat fired.
    /// - Beats marked `showOnce: true` are skipped if `NarrativeFlags.firedBeats` already contains the id.
    /// - Only one beat can be active at a time; a second `fire` while a beat is active is a no-op.
    @discardableResult
    func fire(trigger triggerID: String) -> Bool {
        guard activeBeat == nil, let script = activeScript else { return false }
        guard let beat = script.beats.first(where: { $0.trigger == triggerID }) else { return false }
        if beat.fireOnlyOnce, flags.hasBeatFired(beat.id) { return false }

        activeBeat = beat
        currentLineIndex = 0
        isTypewriterComplete = false
        flags.markBeatFired(beat.id)
        return true
    }

    // MARK: - Playback control

    /// Player tapped the overlay.
    /// - If the current line is still revealing, completes it instantly.
    /// - If the line is fully revealed, advances to the next line — or dismisses if last.
    func advance() {
        guard activeBeat != nil else { return }
        if !isTypewriterComplete {
            isTypewriterComplete = true
            return
        }
        advanceLine()
    }

    /// Move to the next line. If past the last line, dismiss the beat.
    func advanceLine() {
        guard let beat = activeBeat else { return }
        let next = currentLineIndex + 1
        if next >= beat.lines.count {
            dismissBeat()
        } else {
            currentLineIndex = next
            isTypewriterComplete = false
        }
    }

    /// Force-close the active beat.
    func dismissBeat() {
        activeBeat = nil
        currentLineIndex = 0
        isTypewriterComplete = false
    }

    // MARK: - Helpers

    var currentLine: String? {
        guard let beat = activeBeat else { return nil }
        return beat.lines.indices.contains(currentLineIndex) ? beat.lines[currentLineIndex] : nil
    }

    var isLastLine: Bool {
        guard let beat = activeBeat else { return false }
        return currentLineIndex >= beat.lines.count - 1
    }
}
