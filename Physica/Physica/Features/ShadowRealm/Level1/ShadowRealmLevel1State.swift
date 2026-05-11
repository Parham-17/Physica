import SwiftUI
import Observation

@Observable
final class ShadowRealmLevel1State {
    enum Phase {
        case dark               // before first tap
        case exploring          // light on, free movement
        case complete           // reached exit
        case test               // post-level question
        case finished           // returned to map
    }

    enum DiscoveryID: Hashable {
        case crystal, bat, exit
    }

    // Normalized positions (0..1 in each axis). Multiplied by geometry size at render.
    let initialSparkPosition = CGPoint(x: 0.5, y: 0.85)
    let crystalPosition      = CGPoint(x: 0.18, y: 0.38)
    let batPosition          = CGPoint(x: 0.80, y: 0.25)
    let exitPosition         = CGPoint(x: 0.50, y: 0.12)

    /// Distance threshold for "discovery" — object only counts as discovered when
    /// it's inside the light cone (handled in `isInLightCone`).
    let discoveryConeRadius: CGFloat = 0.28

    var phase: Phase = .dark
    var sparkPositionNormalized: CGPoint
    /// Heading in degrees, 0 = up (north), 90 = right (east), 180 = down, 270 = left.
    var headingDegrees: Double = 0
    var joystickVector: CGVector = .zero
    var discoveries: Set<DiscoveryID> = []
    var batReacted: Bool = false

    let hintEngine: HintEngine

    init() {
        self.sparkPositionNormalized = CGPoint(x: 0.5, y: 0.85)
        self.hintEngine = HintEngine(timeline: [
            .init(after: 30, level: .nudge),
            .init(after: 60, level: .hint),
            .init(after: 120, level: .strong)
        ])
    }

    var isLightOn: Bool { phase != .dark }

    var starsEarned: Int {
        guard phase == .complete || phase == .test || phase == .finished else { return 0 }
        var s = 1
        if discoveries.contains(.crystal) { s += 1 }
        if discoveries.contains(.bat) { s += 1 }
        return min(3, s)
    }

    func tapSpark() {
        guard phase == .dark else { return }
        phase = .exploring
        hintEngine.registerActivity()
    }

    /// Called by joystick. dx/dy are in [-1,1].
    func setJoystick(_ vector: CGVector) {
        joystickVector = vector
        if vector.dx != 0 || vector.dy != 0 {
            // Update heading to point in joystick direction.
            // atan2(dx, -dy) gives angle where 0 = up (negative Y), clockwise positive.
            let radians = atan2(vector.dx, -vector.dy)
            headingDegrees = radians * 180 / .pi
            hintEngine.registerActivity()
        }
    }

    /// Step movement by deltaTime seconds. Called by the game loop while exploring.
    /// `speed` is normalized units (0..1) per second.
    func tickMovement(deltaTime: Double, speed: Double = 0.35) {
        guard phase == .exploring else { return }
        let mag = hypot(joystickVector.dx, joystickVector.dy)
        guard mag > 0.05 else { return }

        let dx = joystickVector.dx * speed * deltaTime
        let dy = joystickVector.dy * speed * deltaTime

        let newX = sparkPositionNormalized.x + dx
        let newY = sparkPositionNormalized.y + dy
        sparkPositionNormalized = clampUnit(CGPoint(x: newX, y: newY))

        checkDiscoveries()
    }

    private func clampUnit(_ p: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(p.x, 0.06), 0.94),
            y: min(max(p.y, 0.08), 0.94)
        )
    }

    /// Object discovery rule: object must be within `discoveryConeRadius` AND
    /// inside the 120° light cone from Spark's heading.
    private func isInLightCone(target: CGPoint) -> Bool {
        let dx = target.x - sparkPositionNormalized.x
        let dy = target.y - sparkPositionNormalized.y
        let dist = hypot(dx, dy)
        guard dist < discoveryConeRadius else { return false }
        guard dist > 0.001 else { return true }

        // Angle from Spark to target (0 = up, clockwise positive)
        let targetAngleDeg = atan2(dx, -dy) * 180 / .pi
        // Smallest signed difference between target angle and current heading
        var diff = (targetAngleDeg - headingDegrees).truncatingRemainder(dividingBy: 360)
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }

        return abs(diff) <= 60   // half-cone of 120°
    }

    private func checkDiscoveries() {
        if !discoveries.contains(.crystal), isInLightCone(target: crystalPosition) {
            discoveries.insert(.crystal)
        }
        if !discoveries.contains(.bat), isInLightCone(target: batPosition) {
            discoveries.insert(.bat)
            batReacted = true
        }
        if !discoveries.contains(.exit), isInLightCone(target: exitPosition) {
            // Exit is "discovered" the moment light hits it, but only completes
            // the level when Spark actually walks into it.
            discoveries.insert(.exit)
        }
        // Walking into the exit completes the level (proximity check).
        if discoveries.contains(.exit) && phase == .exploring {
            let d = hypot(sparkPositionNormalized.x - exitPosition.x,
                          sparkPositionNormalized.y - exitPosition.y)
            if d < 0.08 {
                phase = .complete
                hintEngine.stop()
            }
        }
    }

    func startTest() {
        phase = .test
    }

    func finish() {
        phase = .finished
    }

    func reset() {
        phase = .dark
        sparkPositionNormalized = initialSparkPosition
        headingDegrees = 0
        joystickVector = .zero
        discoveries = []
        batReacted = false
        hintEngine.start()
    }
}
