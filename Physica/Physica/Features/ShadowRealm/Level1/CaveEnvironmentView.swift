import SwiftUI

struct CaveEnvironmentView: View {
    let size: CGSize
    let crystalPosition: CGPoint   // normalized
    let batPosition: CGPoint
    let exitPosition: CGPoint
    let discoveries: Set<ShadowRealmLevel1State.DiscoveryID>
    let batReacted: Bool

    var body: some View {
        ZStack {
            CaveBackground()
                .frame(width: size.width, height: size.height)

            CaveStalactites()
                .frame(width: size.width, height: size.height * 0.35)
                .frame(maxHeight: .infinity, alignment: .top)

            CaveFloor()
                .frame(width: size.width, height: size.height * 0.18)
                .frame(maxHeight: .infinity, alignment: .bottom)

            CrystalView(discovered: discoveries.contains(.crystal))
                .position(actualPosition(crystalPosition))

            BatView(reacted: batReacted)
                .position(actualPosition(batPosition))

            CaveExitView(discovered: discoveries.contains(.exit))
                .position(actualPosition(exitPosition))
        }
        .frame(width: size.width, height: size.height)
    }

    private func actualPosition(_ normalized: CGPoint) -> CGPoint {
        CGPoint(x: normalized.x * size.width, y: normalized.y * size.height)
    }
}

private struct CaveBackground: View {
    var body: some View {
        RadialGradient(
            colors: [
                Color(red: 0.10, green: 0.10, blue: 0.18),
                Color(red: 0.05, green: 0.05, blue: 0.10)
            ],
            center: .center,
            startRadius: 60,
            endRadius: 700
        )
    }
}

private struct CaveStalactites: View {
    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .top, spacing: proxy.size.width * 0.04) {
                ForEach(0..<7, id: \.self) { i in
                    StalactiteShape()
                        .fill(Color(red: 0.08, green: 0.08, blue: 0.14))
                        .frame(
                            width: proxy.size.width * 0.10,
                            height: proxy.size.height * heightRatio(i)
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func heightRatio(_ i: Int) -> CGFloat {
        let pattern: [CGFloat] = [0.5, 0.85, 0.4, 0.95, 0.55, 0.7, 0.45]
        return pattern[i % pattern.count]
    }
}

private struct StalactiteShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct CaveFloor: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.08, green: 0.08, blue: 0.14).opacity(0),
                                Color(red: 0.06, green: 0.06, blue: 0.11)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { i in
                        Capsule()
                            .fill(Color(red: 0.10, green: 0.10, blue: 0.16))
                            .frame(
                                width: proxy.size.width * widthRatio(i),
                                height: proxy.size.height * 0.35
                            )
                    }
                }
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity, alignment: .bottom)
            }
        }
    }

    private func widthRatio(_ i: Int) -> CGFloat {
        let pattern: [CGFloat] = [0.18, 0.10, 0.22, 0.14, 0.20]
        return pattern[i % pattern.count]
    }
}

private struct CrystalView: View {
    let discovered: Bool
    @State private var sparkle: Bool = false

    var body: some View {
        ZStack {
            DiamondShape()
                .fill(
                    LinearGradient(
                        colors: discovered
                            ? [Color(red: 0.55, green: 0.85, blue: 1.0), Color(red: 0.25, green: 0.55, blue: 0.95)]
                            : [Color(red: 0.30, green: 0.50, blue: 0.75), Color(red: 0.15, green: 0.30, blue: 0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 50)
                .overlay(
                    DiamondShape()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: discovered ? .voltBlue.opacity(0.7) : .clear, radius: 14)

            if discovered {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 3, height: 3)
                        .offset(
                            x: sparkle ? CGFloat.random(in: -22...22) : 0,
                            y: sparkle ? CGFloat.random(in: -28...28) : 0
                        )
                        .opacity(sparkle ? 0 : 1)
                        .animation(
                            .easeOut(duration: 0.8)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.2),
                            value: sparkle
                        )
                }
            }
        }
        .onChange(of: discovered) { _, isOn in
            if isOn { sparkle = true }
        }
        .accessibilityLabel(discovered ? "Glowing crystal — discovered" : "Glowing crystal")
    }
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct BatView: View {
    let reacted: Bool
    @State private var wingFlap: CGFloat = 1.0

    var body: some View {
        ZStack {
            BatShape()
                .fill(Color(red: 0.16, green: 0.10, blue: 0.20))
                .frame(width: 44, height: 24)
                .scaleEffect(x: wingFlap, y: 1.0)
                .overlay(
                    HStack(spacing: 6) {
                        Circle().fill(Color.voltYellow.opacity(reacted ? 1.0 : 0.4)).frame(width: 3, height: 3)
                        Circle().fill(Color.voltYellow.opacity(reacted ? 1.0 : 0.4)).frame(width: 3, height: 3)
                    }
                    .offset(y: -2)
                )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: reacted ? 0.2 : 0.9).repeatForever(autoreverses: true)) {
                wingFlap = reacted ? 0.6 : 0.85
            }
        }
        .onChange(of: reacted) { _, _ in
            withAnimation(.easeInOut(duration: reacted ? 0.2 : 0.9).repeatForever(autoreverses: true)) {
                wingFlap = reacted ? 0.6 : 0.85
            }
        }
        .accessibilityLabel(reacted ? "A bat — woken up" : "A sleeping bat")
    }
}

private struct BatShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.midY + rect.height * 0.4))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.midY + rect.height * 0.4))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.maxX - rect.width * 0.2, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct CaveExitView: View {
    let discovered: Bool

    var body: some View {
        ZStack {
            ExitArchShape()
                .fill(
                    RadialGradient(
                        colors: discovered
                            ? [Color.torchYellow.opacity(0.9), Color.torchWarm.opacity(0.4), .clear]
                            : [Color(red: 0.05, green: 0.05, blue: 0.10), Color(red: 0.03, green: 0.03, blue: 0.07)],
                        center: .center,
                        startRadius: 4,
                        endRadius: 60
                    )
                )
                .frame(width: 60, height: 80)
                .shadow(color: discovered ? .torchYellow.opacity(0.6) : .clear, radius: 20)

            ExitArchShape()
                .stroke(
                    discovered ? Color.torchYellow.opacity(0.8) : Color(red: 0.20, green: 0.20, blue: 0.30),
                    lineWidth: 2
                )
                .frame(width: 60, height: 80)
        }
        .accessibilityLabel(discovered ? "Cave exit — found" : "Cave exit")
    }
}

private struct ExitArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = rect.width / 2
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.minY + radius),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
