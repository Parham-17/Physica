import Foundation
import Observation

@Observable
final class HubState {
    var hasSeenIntro: Bool = false
}
