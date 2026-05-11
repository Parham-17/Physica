import SwiftUI
import Observation

@Observable
final class ShadowRealmLevel2State {
    enum Phase {
        case intro
        case playing
        case complete
        case test
        case finished
    }

    struct Mirror: Identifiable {
        let id: Int
        let position: CGPoint
        var angleDegrees: Double
        let length: Double

        func endpoints() -> (CGPoint, CGPoint) {
            let rad = angleDegrees * .pi / 180
            let half = length / 2
            let dx = cos(rad) * half
            let dy = sin(rad) * half
            return (
                CGPoint(x: position.x - dx, y: position.y - dy),
                CGPoint(x: position.x + dx, y: position.y + dy)
            )
        }
    }

    struct BeamSegment {
        let start: CGPoint
        let end: CGPoint
    }

    struct Crystal: Identifiable {
        let id: Int
        let position: CGPoint
        var isLit: Bool = false
    }

    var phase: Phase = .intro

    // Spark is stationary, emitting a beam to the right
    let sparkPosition = CGPoint(x: 0.08, y: 0.82)
    let beamOrigin = CGPoint(x: 0.12, y: 0.82)
    private let beamInitialDirection = CGVector(dx: 1, dy: 0)

    // Three rotatable mirrors (initial angles chosen so the puzzle isn't solved)
    var mirrors: [Mirror] = [
        Mirror(id: 0, position: CGPoint(x: 0.50, y: 0.82), angleDegrees: 90, length: 0.12),
        Mirror(id: 1, position: CGPoint(x: 0.50, y: 0.28), angleDegrees: 0, length: 0.12),
        Mirror(id: 2, position: CGPoint(x: 0.85, y: 0.28), angleDegrees: 90, length: 0.12),
    ]

    let receiverPosition = CGPoint(x: 0.85, y: 0.68)
    var receiverLit = false

    var crystals: [Crystal] = [
        Crystal(id: 0, position: CGPoint(x: 0.50, y: 0.55)),
        Crystal(id: 1, position: CGPoint(x: 0.68, y: 0.28)),
    ]

    var beamSegments: [BeamSegment] = []
    var hitMirrorIDs: Set<Int> = []
    var selectedMirrorID: Int? = nil

    let hintEngine: HintEngine
    private let maxBounces = 10
    private let hitRadius: Double = 0.045

    init() {
        self.hintEngine = HintEngine(timeline: [
            .init(after: 20, level: .nudge),
            .init(after: 45, level: .hint),
            .init(after: 90, level: .strong)
        ])
    }

    var starsEarned: Int {
        guard phase == .complete || phase == .test || phase == .finished else { return 0 }
        var s = 1
        for crystal in crystals where crystal.isLit { s += 1 }
        return min(3, s)
    }

    // MARK: - Phase transitions

    func startPlaying() {
        guard phase == .intro else { return }
        phase = .playing
        hintEngine.start()
        traceBeam()
    }

    func startTest() { phase = .test }
    func finish() { phase = .finished }

    func reset() {
        phase = .intro
        mirrors[0].angleDegrees = 90
        mirrors[1].angleDegrees = 0
        mirrors[2].angleDegrees = 90
        receiverLit = false
        for i in crystals.indices { crystals[i].isLit = false }
        beamSegments = []
        hitMirrorIDs = []
        selectedMirrorID = nil
    }

    // MARK: - Mirror interaction

    func rotateMirror(id: Int, to angle: Double) {
        guard phase == .playing,
              let index = mirrors.firstIndex(where: { $0.id == id }) else { return }
        mirrors[index].angleDegrees = angle
        hintEngine.registerActivity()
        traceBeam()
    }

    // MARK: - Ray tracing

    func traceBeam() {
        var segments: [BeamSegment] = []
        var hits: Set<Int> = []
        var origin = beamOrigin
        var dir = beamInitialDirection

        for _ in 0..<maxBounces {
            var closestT = Double.infinity
            var closestIdx: Int?
            var closestHit: CGPoint?

            for (i, mirror) in mirrors.enumerated() {
                if let (t, pt) = intersectRaySegment(
                    origin: origin, dir: dir, segment: mirror.endpoints()
                ), t > 0.002 && t < closestT {
                    closestT = t
                    closestIdx = i
                    closestHit = pt
                }
            }

            if let idx = closestIdx, let hit = closestHit {
                segments.append(BeamSegment(start: origin, end: hit))
                hits.insert(mirrors[idx].id)
                dir = reflect(dir, mirrorAngle: mirrors[idx].angleDegrees)
                origin = hit
            } else {
                segments.append(BeamSegment(start: origin, end: boundaryPoint(from: origin, dir: dir)))
                break
            }
        }

        receiverLit = false
        for i in crystals.indices { crystals[i].isLit = false }

        for seg in segments {
            if segmentDist(receiverPosition, seg.start, seg.end) < hitRadius {
                receiverLit = true
            }
            for i in crystals.indices {
                if segmentDist(crystals[i].position, seg.start, seg.end) < hitRadius {
                    crystals[i].isLit = true
                }
            }
        }

        beamSegments = segments
        hitMirrorIDs = hits

        if receiverLit && phase == .playing {
            phase = .complete
            hintEngine.stop()
        }
    }

    // MARK: - Geometry helpers

    private func intersectRaySegment(
        origin o: CGPoint, dir d: CGVector, segment: (CGPoint, CGPoint)
    ) -> (Double, CGPoint)? {
        let (p1, p2) = segment
        let sx = p2.x - p1.x, sy = p2.y - p1.y
        let denom = d.dx * sy - d.dy * sx
        guard abs(denom) > 1e-10 else { return nil }

        let t = ((p1.x - o.x) * sy - (p1.y - o.y) * sx) / denom
        let s = ((p1.x - o.x) * d.dy - (p1.y - o.y) * d.dx) / denom
        guard t > 0 && s >= 0 && s <= 1 else { return nil }

        return (Double(t), CGPoint(x: o.x + d.dx * t, y: o.y + d.dy * t))
    }

    private func reflect(_ dir: CGVector, mirrorAngle: Double) -> CGVector {
        let rad = mirrorAngle * .pi / 180
        let nx = -sin(rad), ny = cos(rad)
        let dot = dir.dx * nx + dir.dy * ny
        return CGVector(dx: dir.dx - 2 * dot * nx, dy: dir.dy - 2 * dot * ny)
    }

    private func segmentDist(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint) -> Double {
        let dx = b.x - a.x, dy = b.y - a.y
        let lenSq = dx * dx + dy * dy
        guard lenSq > 1e-10 else { return hypot(p.x - a.x, p.y - a.y) }
        let t = max(0, min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / lenSq))
        return hypot(p.x - (a.x + t * dx), p.y - (a.y + t * dy))
    }

    private func boundaryPoint(from o: CGPoint, dir d: CGVector) -> CGPoint {
        var minT = Double.infinity
        if d.dx > 0 { minT = min(minT, (1 - o.x) / d.dx) }
        if d.dx < 0 { minT = min(minT, -o.x / d.dx) }
        if d.dy > 0 { minT = min(minT, (1 - o.y) / d.dy) }
        if d.dy < 0 { minT = min(minT, -o.y / d.dy) }
        return CGPoint(x: o.x + d.dx * minT, y: o.y + d.dy * minT)
    }
}
