import Foundation
import SwiftData

@Model
final class Level {
    @Attribute(.unique) var id: String
    var number: Int
    var title: String
    var starsEarned: Int
    var completedAt: Date?
    var realm: Realm?

    init(id: String, number: Int, title: String) {
        self.id = id
        self.number = number
        self.title = title
        self.starsEarned = 0
        self.completedAt = nil
    }

    var isCompleted: Bool { completedAt != nil }
    var isBoss: Bool { number == 99 }
}
