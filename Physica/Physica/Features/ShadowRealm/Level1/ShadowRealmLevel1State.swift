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
    let initialSparkPosition = CGPoint(x: 0.5, y: 0.62)
    let crystalPosition      = CGPoint(x: 0.18, y: 0.30)
    let batPosition          = CGPoint(x: 0.78, y: 0.22)
    let exitPosition         = CGPoint(x: 0.82, y: 0.82)
    let discoveryRadius: CGFloat = 0.09  // ~9% of min(width, height)

    var phase: Phase = .dark
    var sparkPositionNormalized: CGPoint
    var discoveries: Set<DiscoveryID> = []
    var batReacted: Bool = false

    let hintEngine: HintEngine

    init() {
        self.sparkPositionNormalized = CGPoint(x: 0.5, y: 0.62)
        self.hintEngine = HintEngine(timeline: [
            .init(after: 30, level: .nudge),
            .init(after: 60, level: .hint),
            .init(after: 120, level: .strong)
        ])
    }

    var isLightOn: Bool {
        phase != .dark
    }

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

    func moveSpark(toNormalized point: CGPoint) {
        guard phase == .exploring else { return }
        sparkPositionNormalized = clampUnit(point)
        hintEngine.registerActivity()
        checkDiscoveries()
    }

    private func clampUnit(_ p: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(p.x, 0.04), 0.96),
            y: min(max(p.y, 0.06), 0.94)
        )
    }

    private func checkDiscoveries() {
        if !discoveries.contains(.crystal), distance(sparkPositionNormalized, crystalPosition) < discoveryRadius {
            discoveries.insert(.crystal)
        }
        if !discoveries.contains(.bat), distance(sparkPositionNormalized, batPosition) < discoveryRadius {
            discoveries.insert(.bat)
            batReacted = true
        }
        if !discoveries.contains(.exit), distance(sparkPositionNormalized, exitPosition) < discoveryRadius {
            discoveries.insert(.exit)
            phase = .complete
            hintEngine.stop()
        }
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
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
        discoveries = []
        batReacted = false
        hintEngine.start()
    }
}
