import SwiftUI

/// Virtual touch joystick. Emits a unit-vector direction + magnitude (0...1)
/// for the current stick offset. Resets to zero when released.
struct VirtualJoystick: View {
    var size: CGFloat = 130
    var onChange: (CGVector) -> Void

    @State private var stickOffset: CGSize = .zero
    @State private var isActive: Bool = false

    private var stickRadius: CGFloat { size * 0.3 }
    private var maxOffset: CGFloat { size * 0.32 }

    var body: some View {
        ZStack {
            // Base ring
            Circle()
                .fill(Color.white.opacity(isActive ? 0.12 : 0.07))
                .overlay(
                    Circle().stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                )
                .frame(width: size, height: size)

            // Inner guides
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: size * 0.55, height: size * 0.55)

            // Movable stick
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.torchYellow.opacity(0.95), Color.torchWarm.opacity(0.8)],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: stickRadius
                    )
                )
                .frame(width: stickRadius * 2, height: stickRadius * 2)
                .overlay(
                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .torchYellow.opacity(0.5), radius: 8)
                .offset(stickOffset)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isActive = true
                    let raw = CGSize(width: value.translation.width, height: value.translation.height)
                    let clamped = clamp(raw, to: maxOffset)
                    stickOffset = clamped
                    emit(clamped)
                }
                .onEnded { _ in
                    isActive = false
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        stickOffset = .zero
                    }
                    emit(.zero)
                }
        )
    }

    private func clamp(_ s: CGSize, to maxLen: CGFloat) -> CGSize {
        let len = hypot(s.width, s.height)
        guard len > maxLen else { return s }
        let scale = maxLen / len
        return CGSize(width: s.width * scale, height: s.height * scale)
    }

    private func emit(_ s: CGSize) {
        if maxOffset == 0 {
            onChange(.zero)
            return
        }
        onChange(CGVector(dx: s.width / maxOffset, dy: s.height / maxOffset))
    }
}

#Preview {
    ZStack {
        Color.shadowDeep.ignoresSafeArea()
        VirtualJoystick { v in
            print("Joystick: \(v)")
        }
    }
}
