import Foundation
import Testing

@testable import StandByWatch

struct WatchSettingsTests {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "com.mickamy.StandBy.tests.\(UUID().uuidString)")!
    }

    @Test func defaultValues() {
        let settings = WatchSettings()
        #expect(settings.hapticEnabled == true)
    }

    @Test func codableRoundTrip() throws {
        var settings = WatchSettings()
        settings.hapticEnabled = false

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(WatchSettings.self, from: data)

        #expect(decoded == settings)
    }

    @Test func loadReturnsDefaultWhenEmpty() {
        let defaults = makeDefaults()
        let settings = WatchSettings.load(defaults: defaults)
        #expect(settings == WatchSettings())
    }

    @Test func saveAndLoadRoundTrip() {
        let defaults = makeDefaults()
        var settings = WatchSettings()
        settings.hapticEnabled = false

        settings.save(defaults: defaults)
        let loaded = WatchSettings.load(defaults: defaults)

        #expect(loaded == settings)
    }

    @Test func loadReturnsDefaultWhenCorrupted() {
        let defaults = makeDefaults()
        defaults.set(Data("not json".utf8), forKey: "watchSettings")

        let settings = WatchSettings.load(defaults: defaults)

        #expect(settings == WatchSettings())
    }
}
