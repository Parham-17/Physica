import Foundation
import Observation

enum NavRoute: Hashable {
    case realmMap
    case shadowLevel(Int)
    case voltLevel(Int)
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
