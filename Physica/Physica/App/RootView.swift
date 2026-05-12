import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Query private var progressList: [Progress]

    private var onboardingCompleted: Bool {
        progressList.first?.onboardingCompleted ?? false
    }

    var body: some View {
        if onboardingCompleted {
            mainContent
        } else {
            OnboardingFlowView()
        }
    }

    private var mainContent: some View {
        @Bindable var router = router
        return ZStack(alignment: .bottom) {
            NavigationStack(path: $router.path) {
                HomeView()
                    .navigationDestination(for: NavRoute.self) { route in
                        destination(for: route)
                    }
            }
            DialogueOverlayView()
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func destination(for route: NavRoute) -> some View {
        switch route {
        case .realmMap:
            RealmMapView()
        case .module:
            modulePlaceholder
        case .profile:
            ProfilePlaceholderView()
        }
    }

    private var modulePlaceholder: some View {
        Text("Module under redesign — see PHYSICA_LIGHT_PIPELINE_V2.md")
            .font(.bodyGame)
            .foregroundStyle(.white.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.realmDark.ignoresSafeArea())
    }
}
