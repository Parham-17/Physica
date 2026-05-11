import SwiftUI
import SwiftData

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressList: [Progress]
    @State private var currentPage = 0

    private let pageCount = 4

    var body: some View {
        ZStack(alignment: .topTrailing) {
            pageContent
                .id(currentPage)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity
                ))

            Button {
                completeOnboarding()
            } label: {
                Text("Skip")
                    .font(.hintCaption)
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .padding(.top, Spacing.xl)
            .padding(.trailing, Spacing.md)
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }

    @ViewBuilder
    private var pageContent: some View {
        switch currentPage {
        case 0:
            OnboardingSparkPage { advancePage() }
        case 1:
            OnboardingTroublePage { advancePage() }
        case 2:
            OnboardingBrokenPage { advancePage() }
        case 3:
            OnboardingMissionPage { completeOnboarding() }
        default:
            EmptyView()
        }
    }

    private func advancePage() {
        guard currentPage < pageCount - 1 else {
            completeOnboarding()
            return
        }
        withAnimation(.easeInOut(duration: 0.4)) {
            currentPage += 1
        }
    }

    private func completeOnboarding() {
        if let progress = progressList.first {
            progress.onboardingCompleted = true
            try? modelContext.save()
        }
    }
}

#Preview {
    OnboardingFlowView()
        .modelContainer(.previewPhysica())
}
