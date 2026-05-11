import SwiftUI

/// Renders a Spark image with an optional spinning propeller overlay.
///
/// Body SVGs have the propeller blades + center dot REMOVED. Only the
/// stem and hub remain in the body. The blades layer is overlaid via
/// `SparkPropellerBlades` and rotated around the propeller pivot point
/// (49.5%, 10.4% of the image).
struct SparkAnimated: View {
    let imageName: String
    var size: CGFloat = 200
    var showPropeller: Bool = true

    @State private var propAngle: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let propellerPivot = UnitPoint(x: 0.495, y: 0.104)

    var body: some View {
        ZStack {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)

            if showPropeller {
                Image("SparkPropellerBlades")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(propAngle), anchor: propellerPivot)
                    .rotation3DEffect(
                        .degrees(65),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: propellerPivot
                    )
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.linear(duration: 0.6).repeatForever(autoreverses: false)) {
                            propAngle = 360
                        }
                    }
            }
        }
        .frame(width: size, height: size)
    }
}

/// Hello pose with a waving raised arm.
///
/// Body SVG has the raised arm + propeller blades removed. We overlay the
/// arm separately so we can rotate it around the shoulder pivot
/// (approx 30.5%, 61.6% of the image).
struct SparkHelloWaving: View {
    var size: CGFloat = 200

    @State private var propAngle: Double = 0
    @State private var armAngle: Double = -12
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let propellerPivot = UnitPoint(x: 0.495, y: 0.104)
    private let shoulderPivot = UnitPoint(x: 0.305, y: 0.616)

    var body: some View {
        ZStack {
            // Body (no arm, no propeller blades)
            Image("SparkFrontHello")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)

            // Waving arm
            Image("SparkFrontHelloArm")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .rotationEffect(.degrees(armAngle), anchor: shoulderPivot)

            // Rotating propeller blades, tilted forward for helicopter look
            Image("SparkPropellerBlades")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .rotationEffect(.degrees(propAngle), anchor: propellerPivot)
                .rotation3DEffect(
                    .degrees(65),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: propellerPivot
                )
        }
        .frame(width: size, height: size)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 0.6).repeatForever(autoreverses: false)) {
                propAngle = 360
            }
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                armAngle = 12
            }
        }
    }
}
