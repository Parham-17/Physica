import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            HubView()
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
