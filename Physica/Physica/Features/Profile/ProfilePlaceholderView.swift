import SwiftUI

struct ProfilePlaceholderView: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white.opacity(0.5))
            Text("Profile")
                .font(.gameTitle)
                .foregroundStyle(.white)
            Text("Coming in Week 7")
                .font(.bodyGame)
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.shadowDeep.ignoresSafeArea())
    }
}

#Preview {
    ProfilePlaceholderView()
}
