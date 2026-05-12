import Foundation

/// A whole dialogue script for one module — what `DialogueLoader` parses
/// from `<Module>Dialogue.json`.
struct DialogueScript: Decodable {
    let module: String
    let beats: [DialogueBeat]
}

/// A single beat — one block of lines spoken by Spark or Umbra, fired
/// by a specific module trigger.
struct DialogueBeat: Decodable, Identifiable, Hashable {
    let id: String
    let type: BeatType
    let speaker: Speaker
    let expression: String       // matches a SparkExpression / UmbraExpression
    let lines: [String]
    let trigger: String          // e.g. "onSceneLoaded", "onSparkActivated"
    let showOnce: Bool?          // default true for opening/insight/connection

    var fireOnlyOnce: Bool { showOnce ?? true }
}

/// The four beats every module fires, per PIPELINE.md §5.3.
enum BeatType: String, Decodable {
    case opening
    case discovery
    case insight
    case connection
}

enum Speaker: String, Decodable {
    case spark
    case umbra
}
