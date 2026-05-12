import Foundation

extension Realm {
    /// Asset catalog name of the circular planet illustration shown on the
    /// world map. Files live in `Assets.xcassets/WorldIcon_<Name>.imageset/`.
    /// Returns nil if no icon is registered for this realm yet.
    var iconAssetName: String? {
        switch id {
        case "light-realm":     return "WorldIcon_LightRealm"
        case "volt-city":       return "WorldIcon_VoltCity"
        case "magnetic-peaks":  return "WorldIcon_MagneticPeaks"
        case "echo-valley":     return "WorldIcon_EchoValley"
        case "drift-plains":    return "WorldIcon_DriftPlains"
        default:                return nil
        }
    }
}
