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
        case .module(let moduleID):
            moduleScene(for: moduleID)
        case .profile:
            ProfilePlaceholderView()
        }
    }

    @ViewBuilder
    private func moduleScene(for moduleID: String) -> some View {
        switch moduleID {
        case "light-realm.m1":
            M1Scene()
        default:
            modulePlaceholder(for: moduleID)
        }
    }

    private func modulePlaceholder(for moduleID: String) -> some View {
        VStack(spacing: Spacing.md) {
            Text(moduleID)
                .font(.levelHeader)
                .foregroundStyle(.white.opacity(0.85))
            Text("Module under construction — see PIPELINE.md")
                .font(.bodyGame)
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.realmDark.ignoresSafeArea())
    }
}
