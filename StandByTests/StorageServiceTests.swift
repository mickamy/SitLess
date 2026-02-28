import Foundation
import Testing

@testable import StandBy

struct StorageServiceTests {
    private func makeSUT() -> UserDefaultsStorageProvider {
        let suite = "com.mickamy.StandBy.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return UserDefaultsStorageProvider(defaults: defaults)
    }

    // MARK: - Settings

    @Test func loadSettingsReturnsDefaultWhenEmpty() {
        let sut = makeSUT()
        let settings = sut.loadSettings()
        #expect(settings == Settings())
    }

    @Test func saveAndLoadSettingsRoundTrip() {
        let sut = makeSUT()
        let settings = Settings(stretchIntervalMinutes: 45, idleThresholdMinutes: 10, launchAtLogin: true)

        sut.saveSettings(settings)
        let loaded = sut.loadSettings()

        #expect(loaded == settings)
    }

    @Test func saveSettingsOverwritesPrevious() {
        let sut = makeSUT()
        sut.saveSettings(Settings(stretchIntervalMinutes: 10))
        sut.saveSettings(Settings(stretchIntervalMinutes: 60))

        let loaded = sut.loadSettings()
        #expect(loaded.stretchIntervalMinutes == 60)
    }

    // MARK: - DailyRecord

    @Test func loadDailyRecordReturnsDefaultWhenEmpty() {
        let sut = makeSUT()
        let day = CalendarDay()
        let record = sut.loadDailyRecord(for: day)

        #expect(record.date == day)
        #expect(record.sessions.isEmpty)
        #expect(record.stretchCount == 0)
    }

    @Test func saveAndLoadDailyRecordRoundTrip() {
        let sut = makeSUT()
        let day = CalendarDay()
        var record = DailyRecord(date: day)
        record.stretchCount = 3
        record.sessions = [
            SittingSession(startedAt: Date(timeIntervalSince1970: 0), endedAt: Date(timeIntervalSince1970: 1800)),
        ]

        sut.saveDailyRecord(record)
        let loaded = sut.loadDailyRecord(for: day)

        #expect(loaded == record)
    }

    @Test func dailyRecordsAreIsolatedByDay() {
        let sut = makeSUT()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let day1 = CalendarDay(Date(timeIntervalSince1970: 0), calendar: calendar)
        let day2 = CalendarDay(Date(timeIntervalSince1970: 86400), calendar: calendar)

        var record1 = DailyRecord(date: day1)
        record1.stretchCount = 5
        sut.saveDailyRecord(record1)

        let loaded2 = sut.loadDailyRecord(for: day2)
        #expect(loaded2.stretchCount == 0)
    }

    // MARK: - Stretch Index

    @Test func nextStretchIndexDefaultsToZero() {
        let sut = makeSUT()
        #expect(sut.nextStretchIndex() == 0)
    }

    @Test func advanceStretchIndexCyclesThroughCount() {
        let sut = makeSUT()

        sut.advanceStretchIndex(count: 3)
        #expect(sut.nextStretchIndex() == 1)

        sut.advanceStretchIndex(count: 3)
        #expect(sut.nextStretchIndex() == 2)

        sut.advanceStretchIndex(count: 3)
        #expect(sut.nextStretchIndex() == 0)
    }

    @Test func advanceStretchIndexIgnoresZeroCount() {
        let sut = makeSUT()
        sut.advanceStretchIndex(count: 0)
        #expect(sut.nextStretchIndex() == 0)
    }
}
