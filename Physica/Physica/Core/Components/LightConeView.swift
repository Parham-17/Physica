import SwiftUI

struct LightConeView: View {
    var position: CGPoint
    var radius: CGFloat = 200
    var color: Color = .torchYellow

    var body: some View {
        RadialGradient(
            colors: [color.opacity(0.85), color.opacity(0.35), .clear],
            center: .center,
            startRadius: 8,
            endRadius: radius
        )
        .frame(width: radius * 2, height: radius * 2)
        .position(position)
        .blendMode(.screen)
        .allowsHitTesting(false)
    }
}

#Preview("LightCone") {
    ZStack {
        Color.shadowDeep
        LightConeView(position: CGPoint(x: 200, y: 300), radius: 180)
    }
    .ignoresSafeArea()
}
