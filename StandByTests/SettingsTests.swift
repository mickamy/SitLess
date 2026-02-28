import Foundation
import Testing

@testable import StandBy

struct SettingsTests {
    @Test func defaultValues() {
        let settings = Settings()
        #expect(settings.stretchIntervalMinutes == 30)
        #expect(settings.idleThresholdMinutes == 5)
        #expect(settings.launchAtLogin == false)
    }

    @Test func codableRoundTrip() throws {
        var settings = Settings()
        settings.stretchIntervalMinutes = 45
        settings.idleThresholdMinutes = 10
        settings.launchAtLogin = true

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(Settings.self, from: data)

        #expect(decoded == settings)
    }

    @Test func equatable() {
        let a = Settings()
        var b = Settings()
        #expect(a == b)

        b.stretchIntervalMinutes = 60
        #expect(a != b)
    }

    @Test func clampsStretchIntervalTooLow() {
        let settings = Settings(stretchIntervalMinutes: 0)
        #expect(settings.stretchIntervalMinutes == Settings.stretchIntervalRange.lowerBound)
    }

    @Test func clampsStretchIntervalTooHigh() {
        let settings = Settings(stretchIntervalMinutes: 999)
        #expect(settings.stretchIntervalMinutes == Settings.stretchIntervalRange.upperBound)
    }

    @Test func clampsIdleThresholdTooLow() {
        let settings = Settings(idleThresholdMinutes: -1)
        #expect(settings.idleThresholdMinutes == Settings.idleThresholdRange.lowerBound)
    }

    @Test func clampsIdleThresholdTooHigh() {
        let settings = Settings(idleThresholdMinutes: 100)
        #expect(settings.idleThresholdMinutes == Settings.idleThresholdRange.upperBound)
    }

    @Test func clampsOnDecode() throws {
        let json = #"{"stretchIntervalMinutes":-5,"idleThresholdMinutes":0,"launchAtLogin":false}"#
        let decoded = try JSONDecoder().decode(Settings.self, from: Data(json.utf8))

        #expect(decoded.stretchIntervalMinutes == Settings.stretchIntervalRange.lowerBound)
        #expect(decoded.idleThresholdMinutes == Settings.idleThresholdRange.lowerBound)
    }

    @Test func clampsOnDirectAssignment() {
        var settings = Settings()

        settings.stretchIntervalMinutes = 0
        #expect(settings.stretchIntervalMinutes == Settings.stretchIntervalRange.lowerBound)

        settings.idleThresholdMinutes = 999
        #expect(settings.idleThresholdMinutes == Settings.idleThresholdRange.upperBound)
    }
}
