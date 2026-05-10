import SwiftUI

struct GlitchOverlayView: View {
    var active: Bool = true

    @State private var particles: [GlitchParticle] = []
    @State private var timer: Timer?

    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.x * size.width,
                    y: particle.y * size.height,
                    width: particle.width,
                    height: particle.height
                )
                context.fill(
                    Path(rect),
                    with: .color(particle.color.opacity(particle.opacity))
                )
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard active else { return }
            spawnInitial()
            timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
                withAnimation(.linear(duration: 0.1)) {
                    refreshParticles()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func spawnInitial() {
        particles = (0..<12).map { _ in randomParticle() }
    }

    private func refreshParticles() {
        particles = particles.map { p in
            if Double.random(in: 0...1) < 0.4 {
                return randomParticle()
            }
            return p
        }
    }

    private func randomParticle() -> GlitchParticle {
        GlitchParticle(
            x: Double.random(in: 0...1),
            y: Double.random(in: 0...1),
            width: Double.random(in: 2...20),
            height: Double.random(in: 1...3),
            opacity: Double.random(in: 0.15...0.5),
            color: [Color.voltBlue, Color.torchYellow, Color.white].randomElement()!
        )
    }
}

private struct GlitchParticle {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var opacity: Double
    var color: Color
}
