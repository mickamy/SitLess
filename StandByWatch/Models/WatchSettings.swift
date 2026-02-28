import Foundation

nonisolated struct WatchSettings: Codable, Equatable, Sendable {
    private static let key = "watchSettings"

    var hapticEnabled: Bool = true

    static func load(defaults: UserDefaults = .standard) -> WatchSettings {
        guard let data = defaults.data(forKey: Self.key) else { return WatchSettings() }
        do {
            return try JSONDecoder().decode(WatchSettings.self, from: data)
        } catch {
            return WatchSettings()
        }
    }

    func save(defaults: UserDefaults = .standard) {
        do {
            let data = try JSONEncoder().encode(self)
            defaults.set(data, forKey: Self.key)
        } catch {
            // Encoding a simple Codable struct should never fail.
        }
    }
}
