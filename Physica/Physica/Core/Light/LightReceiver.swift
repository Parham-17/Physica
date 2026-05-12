import Foundation
import CoreGraphics

/// Something the player needs to hit with light — a beacon receiver crystal,
/// a Dawn Gate eye, a Crystal Gate slot. Activates when a beam segment passes
/// through its circular sense zone with sufficient intensity.
///
/// M1 uses three of these. M2+ add `requiredBeamProfile` checks (sharp vs.
/// scattered vs. blocked) — deferred to when M4 implements `MaterialPanel`.
struct LightReceiver: Identifiable, Hashable {
    let id: String

    /// World-space center of the sense zone.
    var position: CGPoint

    /// Radius of the sense zone — a beam segment passing within this many
    /// points of the position counts as a hit.
    var radius: CGFloat

    /// Minimum beam intensity to activate. 0.0–1.0.
    var requiredIntensity: CGFloat

    /// Whether this receiver is currently lit. Set by the simulation, read by views.
    var isActivated: Bool
}
