import SwiftUI

/// Overlays a fast-rotating motion-blur disc on top of a Spark image's static propeller
/// to give the illusion of spinning. Positioned at the head/propeller area.
struct PropellerSpinView: View {
    let sparkSize: CGFloat
    var propellerYRatio: CGFloat = 0.105
    var propellerWidthRatio: CGFloat = 0.18

    @State private var angle: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let diameter = sparkSize * propellerWidthRatio
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [
                        .white.opacity(0.0),
                        .white.opacity(0.85),
                        .white.opacity(0.6),
                        .white.opacity(0.85),
                        .white.opacity(0.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: diameter * 1.05, height: diameter * 0.18)
            .blur(radius: 1.2)
            .rotationEffect(.degrees(angle))
            .offset(y: -sparkSize * (0.5 - propellerYRatio))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 0.12).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
    }
}

/// A Spark image with the spinning propeller overlay.
struct SparkAnimated: View {
    let imageName: String
    var size: CGFloat = 200
    var propellerYRatio: CGFloat = 0.105
    var showPropeller: Bool = true

    var body: some View {
        ZStack {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size)

            if showPropeller {
                PropellerSpinView(sparkSize: size, propellerYRatio: propellerYRatio)
            }
        }
        .frame(width: size, height: size)
    }
}
