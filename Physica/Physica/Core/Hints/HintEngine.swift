import Foundation
import Observation

@Observable
final class HintEngine {
    enum HintLevel {
        case none, nudge, hint, strong
    }

    struct Stage {
        let after: TimeInterval
        let level: HintLevel
    }

    var currentLevel: HintLevel = .none

    private let timeline: [Stage]
    private var timer: Timer?
    private var idleStart: Date = Date()

    init(timeline: [Stage]) {
        self.timeline = timeline.sorted { $0.after < $1.after }
    }

    func start() {
        idleStart = Date()
        currentLevel = .none
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func registerActivity() {
        idleStart = Date()
        if currentLevel != .none {
            currentLevel = .none
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        currentLevel = .none
    }

    private func tick() {
        let elapsed = Date().timeIntervalSince(idleStart)
        var nextLevel: HintLevel = .none
        for stage in timeline where elapsed >= stage.after {
            nextLevel = stage.level
        }
        if nextLevel != currentLevel {
            currentLevel = nextLevel
        }
    }

    deinit {
        timer?.invalidate()
    }
}
