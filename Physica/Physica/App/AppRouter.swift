import Foundation
import Observation

enum NavRoute: Hashable {
    case realmMap
    case module(String)   // module ID, e.g. "light-realm.m1"
    case profile
}

@Observable
final class AppRouter {
    var path: [NavRoute] = []

    func push(_ route: NavRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
