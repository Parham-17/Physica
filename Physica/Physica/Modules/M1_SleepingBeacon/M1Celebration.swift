import SwiftUI
import UIKit

/// Shown after the player answers the post-module quiz correctly. Spark says
/// "Well done", three stars pop in with spring + haptic, and the XP earned is
/// displayed. Tapping "Continue" calls `onContinue`.
struct M1CelebrationView: View {
    let stars: Int          // 0–3
    let xpEarned: Int
    let onContinue: () -> Void

    @State private var titleVisible = false
    @State private var sparkVisible = false
    @State private var visibleStars: Int = 0
    @State private var xpVisible = false
    @State private var continueVisible = false

    var body: some View {
        ZStack {
            backgroundGlow

            VStack(spacing: Spacing.xl) {
                Spacer()

                Text("Well done.")
                    .font(.gameTitle)
                    .foregroundStyle(.white)
                    .opacity(titleVisible ? 1 : 0)
                    .offset(y: titleVisible ? 0 : 14)

                sparkPortrait
                    .opacity(sparkVisible ? 1 : 0)
                    .scaleEffect(sparkVisible ? 1 : 0.6)

                starsRow
                    .padding(.top, Spacing.md)

                if xpVisible {
                    Text("+\(xpEarned) XP")
                        .font(.levelHeader)
                        .foregroundStyle(Color.beaconYellow)
                        .transition(.scale.combined(with: .opacity))
                }

                Spacer()

                continueButton
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xl)
                    .opacity(continueVisible ? 1 : 0)
                    .offset(y: continueVisible ? 0 : 18)
            }
        }
        .background(Color.realmDark.opacity(0.96).ignoresSafeArea())
        .onAppear { runEntranceSequence() }
    }

    // MARK: - Subviews

    private var backgroundGlow: some View {
        Circle()
            .fill(Color.beaconWarm.opacity(0.35))
            .frame(width: 420, height: 420)
            .blur(radius: 110)
            .offset(y: -40)
    }

    private var sparkPortrait: some View {
        ZStack {
            Circle()
                .fill(Color.beaconWarm.opacity(0.5))
                .frame(width: 200, height: 200)
                .blur(radius: 32)
            Image("SparkFrontHappy")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
        }
    }

    private var starsRow: some View {
        HStack(spacing: Spacing.md) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < visibleStars ? "star.fill" : "star")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(
                        index < min(visibleStars, stars)
                            ? Color.beaconYellow
                            : Color.white.opacity(0.18)
                    )
                    .shadow(
                        color: index < min(visibleStars, stars)
                            ? Color.beaconWarm.opacity(0.7)
                            : .clear,
                        radius: 18
                    )
                    .scaleEffect(index < visibleStars ? 1.0 : 0.4)
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.55),
                        value: visibleStars
                    )
            }
        }
    }

    private var continueButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onContinue()
        } label: {
            Text("Continue")
                .font(.levelHeader)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.electricBlue, in: Capsule())
                .foregroundStyle(.white)
                .shadow(color: .electricBlue.opacity(0.5), radius: 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Animation sequence

    private func runEntranceSequence() {
        // Success haptic the moment celebration appears
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        withAnimation(.easeOut(duration: 0.4).delay(0.05)) {
            titleVisible = true
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.25)) {
            sparkVisible = true
        }

        // Reveal stars sequentially with a haptic per star
        for index in 0..<stars {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7 + Double(index) * 0.22) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                visibleStars = index + 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7 + Double(stars) * 0.22 + 0.2) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) {
                xpVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7 + Double(stars) * 0.22 + 0.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                continueVisible = true
            }
        }
    }
}

#Preview {
    M1CelebrationView(stars: 3, xpEarned: 50) {}
}
