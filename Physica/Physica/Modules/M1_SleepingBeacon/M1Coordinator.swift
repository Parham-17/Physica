import Foundation
import Observation
import CoreGraphics

/// Game state for M1 Sleeping Beacon.
///
/// All positions are **normalized 0..1** — the view multiplies by container size
/// at render time. The puzzle is solved when Spark is awake AND all 3 receivers
/// are lit, which restores the beacon and fires the Insight beat.
@Observable
final class M1Coordinator {

    enum Phase: Hashable {
        case opening         // scene loaded, opening beat playing
        case awake           // dialogue dismissed, lantern interactable
        case solved          // all 4 targets hit, beacon restored
        case quiz            // post-connection quiz showing
        case celebrating     // quiz answered correctly, celebration showing
        case complete        // celebration dismissed, ready to leave
    }

    private(set) var phase: Phase = .opening
    private(set) var quizAttempts: Int = 0
    private(set) var starsEarned: Int = 0

    // MARK: - Layout (normalized)

    let lanternY: CGFloat = 0.65
    let sparkPosition: CGPoint = CGPoint(x: 0.35, y: 0.50)
    let sparkRadius: CGFloat = 0.06
    let beaconColumnRect = CGRect(x: 0.35, y: 0.10, width: 0.30, height: 0.14)

    private(set) var receivers: [LightReceiver] = [
        LightReceiver(id: "r1", position: CGPoint(x: 0.18, y: 0.30), radius: 0.05, requiredIntensity: 0.5, isActivated: false),
        LightReceiver(id: "r2", position: CGPoint(x: 0.50, y: 0.30), radius: 0.05, requiredIntensity: 0.5, isActivated: false),
        LightReceiver(id: "r3", position: CGPoint(x: 0.82, y: 0.30), radius: 0.05, requiredIntensity: 0.5, isActivated: false)
    ]

    // MARK: - Mutable game state

    var lanternX: CGFloat = 0.05
    private(set) var sparkActivated: Bool = false
    private(set) var activatedReceiverIDs: Set<String> = []
    private(set) var currentBeam: LightBeam = .empty
    private(set) var lanternIsOn: Bool = false

    var beaconRestored: Bool {
        sparkActivated && activatedReceiverIDs.count == receivers.count
    }

    // MARK: - Lifecycle

    func didLoad() {
        // Beam stays off until the player first touches the lantern.
        phase = .opening
    }

    func dialogueDidDismissOpening() {
        if phase == .opening { phase = .awake }
    }

    /// Connection beat just dismissed — show the quiz.
    func startQuiz() {
        if phase == .solved { phase = .quiz }
    }

    /// Player answered the quiz correctly after `attempts` tries.
    /// 1 attempt → 3 stars, 2 → 2 stars, 3+ → 1 star.
    func answerQuizCorrect(attempts: Int) {
        quizAttempts = attempts
        starsEarned = max(1, 4 - min(attempts, 3))
        phase = .celebrating
    }

    func markComplete() {
        phase = .complete
    }

    // MARK: - Input

    /// Called from the lantern's drag gesture. `normalizedX` is the gesture
    /// location's X divided by the container width.
    func handleLanternDrag(to normalizedX: CGFloat) {
        lanternIsOn = true
        lanternX = max(0.05, min(0.95, normalizedX))
        recomputeBeam()
    }

    // MARK: - Beam computation

    private func recomputeBeam() {
        let emitter = LightEmitter(
            origin: CGPoint(x: lanternX, y: lanternY),
            direction: CGVector(dx: 0, dy: -1),   // upward in normalized coords (y decreases up)
            intensity: 1.0,
            color: .white,
            isOn: lanternIsOn,
            sourceType: .point
        )
        currentBeam = LightSimulation.cast(from: emitter)

        // Spark activation — beam passes within sparkRadius of sparkPosition.
        if !sparkActivated, beamHitsSpark() {
            sparkActivated = true
        }

        // Receiver activation — refresh from the simulation, but never deactivate
        // a receiver that has already been lit (one-shot).
        let hits = LightSimulation.receivers(activatedBy: currentBeam, receivers: receivers)
        activatedReceiverIDs.formUnion(hits)
        for index in receivers.indices {
            if activatedReceiverIDs.contains(receivers[index].id) {
                receivers[index].isActivated = true
            }
        }

        if beaconRestored, phase == .awake {
            phase = .solved
        }
    }

    private func beamHitsSpark() -> Bool {
        // Same segment-vs-circle test the simulation uses for receivers.
        guard let segment = currentBeam.segments.first else { return false }
        return distanceFromPointToSegment(sparkPosition, segment: segment) <= sparkRadius
    }

    private func distanceFromPointToSegment(_ point: CGPoint, segment: LightBeam.BeamSegment) -> CGFloat {
        let dx = segment.end.x - segment.start.x
        let dy = segment.end.y - segment.start.y
        let lenSquared = dx * dx + dy * dy
        guard lenSquared > 0 else {
            return hypot(point.x - segment.start.x, point.y - segment.start.y)
        }
        let t = ((point.x - segment.start.x) * dx + (point.y - segment.start.y) * dy) / lenSquared
        let clamped = max(0, min(1, t))
        let closestX = segment.start.x + clamped * dx
        let closestY = segment.start.y + clamped * dy
        return hypot(point.x - closestX, point.y - closestY)
    }
}
