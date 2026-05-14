import Foundation
import Observation
import CoreGraphics

/// Game state for M1 Sleeping Beacon.
///
/// All positions are **normalized 0..1** — the view multiplies by container size
/// at render time. Layout: lantern fixed at the bottom-center; the player aims
/// the beam by dragging anywhere in the play area. A stone pillar blocks the
/// center, forcing a deliberate aim (not just a sweep). Each receiver and Spark
/// must be lit for `chargeDuration` seconds to be "discovered."
@Observable
final class M1Coordinator {

    enum Phase: Hashable {
        case opening         // scene loaded, opening beat playing
        case awake           // dialogue dismissed, beam interactable
        case solved          // all 4 charged, gate opened
        case walking         // connection dismissed, Spark walks toward the gate
        case quiz            // Spark arrived at gate, quiz showing
        case celebrating     // quiz answered correctly, celebration showing
        case complete        // celebration dismissed, ready to leave
    }

    private(set) var phase: Phase = .opening
    private(set) var quizAttempts: Int = 0
    private(set) var starsEarned: Int = 0

    // MARK: - Layout (normalized)

    let lanternPosition: CGPoint = CGPoint(x: 0.50, y: 0.86)
    let sparkPosition: CGPoint = CGPoint(x: 0.30, y: 0.62)
    let sparkRadius: CGFloat = 0.06
    let beaconColumnRect = CGRect(x: 0.35, y: 0.08, width: 0.30, height: 0.12)

    /// Three receivers placed so each requires a distinct aim direction.
    /// R1 = far upper-left, R2 = far upper-right, R3 = lower-right — the three
    /// are spread across three different angles so the same drag never finds
    /// two of them at once.
    private(set) var receivers: [LightReceiver] = [
        LightReceiver(id: "r1", position: CGPoint(x: 0.16, y: 0.22), radius: 0.05, requiredIntensity: 0.5, isActivated: false),
        LightReceiver(id: "r2", position: CGPoint(x: 0.84, y: 0.22), radius: 0.05, requiredIntensity: 0.5, isActivated: false),
        LightReceiver(id: "r3", position: CGPoint(x: 0.82, y: 0.56), radius: 0.05, requiredIntensity: 0.5, isActivated: false)
    ]

    /// Stone pillar in the middle of the play area. Blocks any direct vertical
    /// beam from the lantern — player has to aim around it.
    private(set) var blockers: [BlockerObject] = [
        BlockerObject(
            id: "pillar",
            bounds: CGRect(x: 0.43, y: 0.40, width: 0.14, height: 0.22),
            isOpaque: true,
            castsShadow: false
        )
    ]

    // MARK: - Charge mechanic

    /// Seconds of continuous beam exposure required to discover a target.
    let chargeDuration: TimeInterval = 0.8

    /// 0...1 charge progress per receiver ID. Once it reaches 1, the receiver
    /// is added to `discoveredReceiverIDs` (permanent). Spark does NOT require
    /// charging — he awakens the moment the beam touches him.
    private(set) var receiverChargeProgress: [String: CGFloat] = [:]

    // MARK: - Mutable game state

    /// Where the player is aiming the beam toward (normalized). The beam
    /// direction is `(aimTarget - lanternPosition).normalized`.
    var aimTarget: CGPoint = CGPoint(x: 0.50, y: 0.50)
    private(set) var lanternIsOn: Bool = false
    private(set) var currentBeam: LightBeam = .empty

    private(set) var sparkAwakened: Bool = false
    private(set) var sparkCurrentlyLit: Bool = false
    private(set) var discoveredReceiverIDs: Set<String> = []
    private(set) var currentlyLitReceiverIDs: Set<String> = []

    var beaconRestored: Bool {
        sparkAwakened && discoveredReceiverIDs.count == receivers.count
    }

    // MARK: - Walking phase

    private(set) var sparkWalkPosition: CGPoint = .zero
    var joystickInput: CGVector = .zero
    private let walkSpeed: CGFloat = 0.45
    private let arrivalRadius: CGFloat = 0.07

    var gateCenter: CGPoint {
        CGPoint(x: beaconColumnRect.midX, y: beaconColumnRect.midY)
    }

    // MARK: - Lifecycle

    func didLoad() {
        phase = .opening
    }

    func dialogueDidDismissOpening() {
        if phase == .opening { phase = .awake }
    }

    func startWalking() {
        if phase == .solved {
            sparkWalkPosition = sparkPosition
            joystickInput = .zero
            lanternIsOn = false
            currentBeam = .empty
            currentlyLitReceiverIDs = []
            sparkCurrentlyLit = false
            phase = .walking
        }
    }

    func tickWalk(dt: CGFloat) {
        guard phase == .walking else { return }
        let dx = joystickInput.dx * walkSpeed * dt
        let dy = joystickInput.dy * walkSpeed * dt
        sparkWalkPosition = CGPoint(
            x: max(0.05, min(0.95, sparkWalkPosition.x + dx)),
            y: max(0.05, min(0.95, sparkWalkPosition.y + dy))
        )
        let distance = hypot(
            sparkWalkPosition.x - gateCenter.x,
            sparkWalkPosition.y - gateCenter.y
        )
        if distance <= arrivalRadius {
            joystickInput = .zero
            phase = .quiz
        }
    }

    func answerQuizCorrect(attempts: Int) {
        quizAttempts = attempts
        starsEarned = max(1, 4 - min(attempts, 3))
        phase = .celebrating
    }

    func markComplete() {
        phase = .complete
    }

    // MARK: - Input

    /// Called while the player is dragging anywhere in the play area. Sets the
    /// aim target and turns the lantern on. Releasing the finger calls
    /// `endAim()` which turns the lantern off.
    func handleAim(to normalizedPoint: CGPoint) {
        guard phase == .awake else { return }
        aimTarget = CGPoint(
            x: max(0.02, min(0.98, normalizedPoint.x)),
            y: max(0.02, min(0.98, normalizedPoint.y))
        )
        lanternIsOn = true
        recomputeBeam()
    }

    /// Called when the player lifts their finger. Beam goes off; transient
    /// lit state clears. Charge progress that's already accumulated *stays*.
    func endAim() {
        lanternIsOn = false
        currentBeam = .empty
        currentlyLitReceiverIDs = []
        sparkCurrentlyLit = false
    }

    // MARK: - Beam computation

    private func recomputeBeam() {
        let dx = aimTarget.x - lanternPosition.x
        let dy = aimTarget.y - lanternPosition.y
        let mag = sqrt(dx * dx + dy * dy)
        let direction: CGVector
        if mag > 0 {
            direction = CGVector(dx: dx / mag, dy: dy / mag)
        } else {
            direction = CGVector(dx: 0, dy: -1)
        }

        let emitter = LightEmitter(
            origin: lanternPosition,
            direction: direction,
            intensity: 1.0,
            color: .white,
            isOn: lanternIsOn,
            sourceType: .point
        )
        currentBeam = LightSimulation.cast(from: emitter, blockers: blockers, maxDistance: 2.0)

        sparkCurrentlyLit = beamHitsSpark()
        if sparkCurrentlyLit, !sparkAwakened {
            sparkAwakened = true
        }
        currentlyLitReceiverIDs = LightSimulation.receivers(activatedBy: currentBeam, receivers: receivers)
    }

    // MARK: - Per-frame charge tick

    /// One frame of puzzle progress. Called from M1Scene while `phase == .awake`.
    /// Increments charge progress for each receiver currently lit; once a target's
    /// progress hits 1, it's permanently discovered. Spark is *not* charged here —
    /// he awakens instantly the moment the beam first touches him (see `recomputeBeam`).
    func tickPuzzle(dt: CGFloat) {
        guard phase == .awake else { return }

        for receiver in receivers where !discoveredReceiverIDs.contains(receiver.id) {
            let isLit = currentlyLitReceiverIDs.contains(receiver.id)
            let current = receiverChargeProgress[receiver.id] ?? 0
            if isLit, current < 1 {
                let next = min(1, current + CGFloat(dt) / CGFloat(chargeDuration))
                receiverChargeProgress[receiver.id] = next
                if next >= 1 {
                    discoveredReceiverIDs.insert(receiver.id)
                }
            }
        }

        if beaconRestored, phase == .awake {
            phase = .solved
        }
    }

    /// Charge progress for a specific receiver — used by the view to draw the
    /// circular charge ring.
    func chargeProgress(for receiverID: String) -> CGFloat {
        receiverChargeProgress[receiverID] ?? 0
    }

    // MARK: - Geometry helpers

    private func beamHitsSpark() -> Bool {
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
