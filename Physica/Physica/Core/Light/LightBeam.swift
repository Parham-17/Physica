import Foundation
import CoreGraphics

/// The result of casting a beam from an emitter — one or more line segments
/// describing the path the light takes through the scene.
///
/// V1 modules produce a single-segment beam (lantern → first blocker or max
/// distance). M6 Mirrorworks will produce multi-segment beams as the beam
/// bounces off mirrors. Rendering is the consumer's job — SwiftUI views can
/// draw segments with `Canvas` / `Path`; SpriteKit scenes with `SKShapeNode`.
struct LightBeam: Hashable {
    var segments: [BeamSegment]
    var color: LightEmitter.BeamColor
    var intensity: CGFloat

    struct BeamSegment: Hashable {
        var start: CGPoint
        var end: CGPoint
        var intensity: CGFloat

        var length: CGFloat {
            hypot(end.x - start.x, end.y - start.y)
        }
    }

    /// A beam with no segments — what you get when the emitter is off.
    static let empty = LightBeam(segments: [], color: .white, intensity: 0)

    var isEmpty: Bool { segments.isEmpty }
}
