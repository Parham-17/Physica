import Foundation

/// V2 expression set — drives Spark's portrait in dialogue overlay and
/// his in-scene character behavior (scale, halo intensity, wobble speed).
///
/// Each chapter constrains Spark to a range of expressions tracking his
/// inner arc. See PIPELINE.md §5.1 for the mapping.
///
/// The `rawValue` matches the `expression` string in dialogue JSON, so
/// `SparkExpression(rawValue: beat.expression)` parses directly.
enum SparkExpression: String, Codable, Hashable, CaseIterable {
    case idle      // default — gentle hover, neutral
    case curious   // pre-tap exploration, framing beats
    case alarmed   // M3+ Umbra glimpses, surprise
    case hopeful   // M1 awakening, M4 scanner upgrade
    case steady    // insight beats, mid-realm narrator tone
    case resolved  // M7 resolution, ally pose
}

/// Independent of expression — controls Spark's halo / inner glow.
/// A dim Spark with a curious expression is M1's opening (pre-tap).
/// A bright Spark with resolved is M7's final restoration.
enum GlowState: String, Codable, Hashable {
    case off       // no halo, normal body (awake but not lit by an external beam)
    case dim       // pre-awakening, no halo + desaturated body
    case warm      // just-woken (M1 after first activation), soft halo
    case stable    // mid-realm, in-rhythm — the default
    case bright    // climactic moments / beam currently on him
}
