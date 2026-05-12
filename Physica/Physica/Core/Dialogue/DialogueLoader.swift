import Foundation

/// Loads a module's dialogue script from a JSON file in the app bundle.
///
/// Module JSON files are co-located with the module they belong to
/// (`Modules/M<N>_*/M<N>Dialogue.json`) and added to the build target so
/// they ship inside the bundle.
enum DialogueLoader {
    enum LoadError: Error, LocalizedError {
        case fileNotFound(String)
        case decodingFailed(String, Error)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let name):
                return "Dialogue file '\(name).json' not found in bundle"
            case .decodingFailed(let name, let underlying):
                return "Failed to decode '\(name).json': \(underlying.localizedDescription)"
            }
        }
    }

    /// Load the script for a module by its dialogue file name (no extension).
    /// Example: `try DialogueLoader.load("M1Dialogue")` finds `M1Dialogue.json`.
    static func load(_ filename: String, bundle: Bundle = .main) throws -> DialogueScript {
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            throw LoadError.fileNotFound(filename)
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(DialogueScript.self, from: data)
        } catch let error as LoadError {
            throw error
        } catch {
            throw LoadError.decodingFailed(filename, error)
        }
    }
}
