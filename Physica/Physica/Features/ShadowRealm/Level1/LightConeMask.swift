import SwiftUI

/// Builds a 120° directional light cone shape originating at `origin`,
/// pointing in `headingDegrees` (0° = up, 90° = right).
///
/// Used both as a mask to reveal the cave only inside the cone, and as
/// the visual light glow.
struct LightConeShape: Shape {
    var origin: CGPoint
    var radius: CGFloat
    var headingDegrees: Double
    var coneAngleDegrees: Double = 120

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // SwiftUI angles: 0° points to the right (positive X). We want 0° to mean "up"
        // (negative Y in screen coords). So shift by -90° to convert from our heading
        // space (0 = up, clockwise) to SwiftUI's angle space (0 = right, counterclockwise).
        let half = coneAngleDegrees / 2.0
        let startAngle = Angle.degrees(headingDegrees - 90 - half)
        let endAngle   = Angle.degrees(headingDegrees - 90 + half)

        path.move(to: origin)
        path.addArc(
            center: origin,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

/// Soft-edged light cone fill. Renders the cone with a radial gradient that's
/// bright near `origin` and fades to transparent at the cone's edge.
struct DirectionalLightConeView: View {
    let origin: CGPoint
    let radius: CGFloat
    let headingDegrees: Double
    var color: Color = .torchYellow
    var coneAngleDegrees: Double = 120

    var body: some View {
        LightConeShape(
            origin: origin,
            radius: radius,
            headingDegrees: headingDegrees,
            coneAngleDegrees: coneAngleDegrees
        )
        .fill(
            RadialGradient(
                colors: [
                    color.opacity(0.55),
                    color.opacity(0.30),
                    color.opacity(0.10),
                    color.opacity(0.0)
                ],
                center: UnitPoint(
                    x: 0.5 + (origin.x.isFinite ? 0 : 0),
                    y: 0.5 + (origin.y.isFinite ? 0 : 0)
                ),
                startRadius: 8,
                endRadius: radius
            )
        )
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }
}
