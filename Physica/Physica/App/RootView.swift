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
        return NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: NavRoute.self) { route in
                    destination(for: route)
                }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func destination(for route: NavRoute) -> some View {
        switch route {
        case .realmMap:
            RealmMapView()
        case .shadowLevel(let n):
            switch n {
            case 1:
                ShadowRealmLevel1View()
            default:
                ShadowRealmPlaceholderView(levelNumber: n)
            }
        case .voltLevel(let n):
            VoltCityPlaceholderView(levelNumber: n)
        case .profile:
            ProfilePlaceholderView()
        }
    }
}
