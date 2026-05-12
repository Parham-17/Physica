import Foundation
import CoreGraphics

/// Something opaque that a beam stops at and (in M3+) casts a shadow behind.
///
/// V1 simplification: axis-aligned rectangles only. M3 Shadow Garden will
/// extend this to convex polygons via a `blockerShape` enum once the shadow
/// polygon computer lands.
struct BlockerObject: Identifiable, Hashable {
    let id: String

    /// World-space axis-aligned bounding rect.
    var bounds: CGRect

    /// `false` for see-through decorative props that don't actually stop light.
    var isOpaque: Bool

    /// Set to `true` for M3+ shadow-casting blockers; ignored before M3.
    var castsShadow: Bool
}
