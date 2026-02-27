import Foundation

nonisolated struct Stretch: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let instruction: String
    let durationSeconds: Int
    /// Kept as String for extensibility since values are loaded from JSON.
    let targetArea: String
}
