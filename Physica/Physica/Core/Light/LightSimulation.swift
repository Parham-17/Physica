import Foundation
import CoreGraphics

/// Pure-compute light raycasting + receiver activation.
///
/// Stateless — call `cast(...)` each frame (or whenever the emitter or blockers
/// change) to get the current beam. Call `receivers(activatedBy:...)` with the
/// beam and the current receiver list to find which ones light up.
///
/// PIPELINE.md §6.8 specs this as a `final class` with a `tick(_:)` for
/// time-based animation. The current pure-function form is enough for M1 / M2;
/// stateful tick can be added when an animated module (M3 shadow polygons,
/// M7 orbital model) needs it.
enum LightSimulation {

    /// Cast a single straight beam from `emitter`. Stops at the nearest opaque
    /// blocker in its path, or at `maxDistance` if nothing is in the way.
    /// If the emitter is off, returns `.empty`.
    static func cast(
        from emitter: LightEmitter,
        blockers: [BlockerObject] = [],
        maxDistance: CGFloat = 4000
    ) -> LightBeam {
        guard emitter.isOn, emitter.intensity > 0 else { return .empty }

        let endpoint = nearestHit(
            from: emitter.origin,
            direction: emitter.direction,
            blockers: blockers,
            maxDistance: maxDistance
        )
        let segment = LightBeam.BeamSegment(
            start: emitter.origin,
            end: endpoint,
            intensity: emitter.intensity
        )
        return LightBeam(segments: [segment], color: emitter.color, intensity: emitter.intensity)
    }

    /// IDs of receivers the beam currently activates — a receiver activates
    /// when a beam segment passes within its radius AND segment intensity
    /// meets the receiver's requirement.
    static func receivers(activatedBy beam: LightBeam, receivers: [LightReceiver]) -> Set<String> {
        guard !beam.isEmpty else { return [] }
        var hits: Set<String> = []
        for r in receivers {
            for seg in beam.segments where seg.intensity >= r.requiredIntensity {
                if segmentIntersectsCircle(seg, center: r.position, radius: r.radius) {
                    hits.insert(r.id)
                    break
                }
            }
        }
        return hits
    }

    // MARK: - Geometry

    private static func nearestHit(
        from origin: CGPoint,
        direction: CGVector,
        blockers: [BlockerObject],
        maxDistance: CGFloat
    ) -> CGPoint {
        let normalized = direction.normalized
        guard normalized.dx != 0 || normalized.dy != 0 else { return origin }

        var bestT = maxDistance
        for blocker in blockers where blocker.isOpaque {
            if let t = rayRectIntersection(
                origin: origin,
                direction: normalized,
                rect: blocker.bounds
            ), t > 0 && t < bestT {
                bestT = t
            }
        }
        return CGPoint(
            x: origin.x + normalized.dx * bestT,
            y: origin.y + normalized.dy * bestT
        )
    }

    /// Ray vs. axis-aligned bounding box (slab method). Returns the t-value
    /// along the ray at which it first enters the rect, or `nil` if it misses.
    private static func rayRectIntersection(
        origin: CGPoint,
        direction: CGVector,
        rect: CGRect
    ) -> CGFloat? {
        let invX: CGFloat = direction.dx == 0 ? .infinity : 1.0 / direction.dx
        let invY: CGFloat = direction.dy == 0 ? .infinity : 1.0 / direction.dy

        let t1 = (rect.minX - origin.x) * invX
        let t2 = (rect.maxX - origin.x) * invX
        let t3 = (rect.minY - origin.y) * invY
        let t4 = (rect.maxY - origin.y) * invY

        let tmin = max(min(t1, t2), min(t3, t4))
        let tmax = min(max(t1, t2), max(t3, t4))

        if tmax < 0 || tmin > tmax { return nil }
        return tmin >= 0 ? tmin : tmax
    }

    /// Distance from a circle's center to the nearest point on the segment ≤ radius?
    private static func segmentIntersectsCircle(
        _ segment: LightBeam.BeamSegment,
        center: CGPoint,
        radius: CGFloat
    ) -> Bool {
        let dx = segment.end.x - segment.start.x
        let dy = segment.end.y - segment.start.y
        let lenSquared = dx * dx + dy * dy
        guard lenSquared > 0 else {
            return hypot(segment.start.x - center.x, segment.start.y - center.y) <= radius
        }

        // Project center onto segment, clamp to [0, 1]
        let t = ((center.x - segment.start.x) * dx + (center.y - segment.start.y) * dy) / lenSquared
        let clamped = max(0, min(1, t))
        let closestX = segment.start.x + clamped * dx
        let closestY = segment.start.y + clamped * dy
        let distSquared = (center.x - closestX) * (center.x - closestX)
                        + (center.y - closestY) * (center.y - closestY)
        return distSquared <= radius * radius
    }
}
