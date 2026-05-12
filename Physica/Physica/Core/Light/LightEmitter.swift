import Foundation
import CoreGraphics

/// A source of light (lantern, candle, sun-shaft) — the start of a beam.
///
/// PIPELINE.md §6.1 specs this as `@Observable final class LightEmitter: SKNode`.
/// For Phase 1 — where modules ship in SwiftUI — we use a value type so it
/// composes naturally with an `@Observable` module-level coordinator. When a
/// later module adopts SpriteKit, an `SKNode` wrapper that owns one of these
/// can be added under `Core/Light/Sprite/` without changing the data model.
struct LightEmitter: Hashable, Codable {
    /// World-space position the beam starts from.
    var origin: CGPoint

    /// Direction the beam travels (must be a unit vector — see `setDirection(_:)`).
    var direction: CGVector

    /// 0.0 = off, 1.0 = full strength. Used by receivers to gate activation.
    var intensity: CGFloat

    /// V1 light is always white. Future modules may use color-coded beams.
    var color: BeamColor

    /// Master switch. A `false` emitter casts an empty beam regardless of intensity.
    var isOn: Bool

    /// Point source = single-pixel origin → sharp shadows.
    /// Extended source = disc of `radius` → umbra + penumbra.
    var sourceType: SourceType

    enum SourceType: Hashable, Codable {
        case point
        case extended(radius: CGFloat)
    }

    enum BeamColor: String, Codable, Hashable {
        case white
    }

    // MARK: - Convenience constructors

    /// A standard point source pointing along `direction`, off by default.
    static func point(at origin: CGPoint, direction: CGVector = CGVector(dx: 0, dy: -1)) -> LightEmitter {
        LightEmitter(
            origin: origin,
            direction: direction.normalized,
            intensity: 1.0,
            color: .white,
            isOn: false,
            sourceType: .point
        )
    }

    // MARK: - Mutation helpers

    /// Update direction, normalizing to unit length. Zero-vector input is ignored.
    mutating func setDirection(_ vector: CGVector) {
        let normalized = vector.normalized
        guard normalized.dx != 0 || normalized.dy != 0 else { return }
        direction = normalized
    }
}

extension CGVector {
    /// Returns the unit-length form of this vector. Zero vector stays zero.
    var normalized: CGVector {
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0 else { return .zero }
        return CGVector(dx: dx / length, dy: dy / length)
    }
}
