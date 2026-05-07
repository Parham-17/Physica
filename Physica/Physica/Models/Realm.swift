import Foundation
import SwiftData

@Model
final class Realm {
    @Attribute(.unique) var id: String
    var displayName: String
    var subtitle: String
    var order: Int
    var isUnlocked: Bool

    @Relationship(deleteRule: .cascade, inverse: \Level.realm)
    var levels: [Level] = []

    init(id: String, displayName: String, subtitle: String, order: Int, isUnlocked: Bool) {
        self.id = id
        self.displayName = displayName
        self.subtitle = subtitle
        self.order = order
        self.isUnlocked = isUnlocked
    }
}
