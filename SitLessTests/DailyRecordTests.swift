import Foundation
import Testing

@testable import SitLess

struct CalendarDayTests {
    @Test func formatsAsYMD() {
        let date = Date(timeIntervalSince1970: 0)  // 1970-01-01 UTC
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let day = CalendarDay(date, calendar: calendar)
        #expect(day.value == "1970-01-01")
    }

    @Test func equalityByValue() {
        let date = Date(timeIntervalSince1970: 86400)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let a = CalendarDay(date, calendar: calendar)
        let b = CalendarDay(date, calendar: calendar)
        #expect(a == b)
    }

    @Test func codableRoundTrip() throws {
        let day = CalendarDay(Date(timeIntervalSince1970: 0))
        let data = try JSONEncoder().encode(day)
        let decoded = try JSONDecoder().decode(CalendarDay.self, from: data)
        #expect(decoded == day)
    }
}

struct DailyRecordTests {
    @Test func defaultValues() {
        let record = DailyRecord(date: CalendarDay())
        #expect(record.totalSittingSeconds == 0)
        #expect(record.stretchCount == 0)
        #expect(record.sessions.isEmpty)
    }

    @Test func totalSittingSecondsComputedFromSessions() {
        var record = DailyRecord(date: CalendarDay())
        record.sessions = [
            SittingSession(startedAt: Date(timeIntervalSince1970: 0), endedAt: Date(timeIntervalSince1970: 1800)),
            SittingSession(startedAt: Date(timeIntervalSince1970: 3600), endedAt: Date(timeIntervalSince1970: 4500)),
        ]
        #expect(record.totalSittingSeconds == 2700)
    }

    @Test func codableRoundTrip() throws {
        let session = SittingSession(
            startedAt: Date(timeIntervalSince1970: 1000),
            endedAt: Date(timeIntervalSince1970: 2800)
        )
        var record = DailyRecord(date: CalendarDay())
        record.stretchCount = 2
        record.sessions = [session]

        let data = try JSONEncoder().encode(record)
        let decoded = try JSONDecoder().decode(DailyRecord.self, from: data)

        #expect(decoded == record)
    }
}

struct SittingSessionTests {
    @Test func durationWithEndDate() {
        let session = SittingSession(
            startedAt: Date(timeIntervalSince1970: 1000),
            endedAt: Date(timeIntervalSince1970: 2800)
        )
        #expect(session.durationSeconds == 1800)
    }

    @Test func durationWithoutEndDateUsesNow() {
        let start = Date()
        let session = SittingSession(
            startedAt: start.addingTimeInterval(-120),
            endedAt: nil
        )
        #expect(session.durationSeconds >= 118)
        #expect(session.durationSeconds <= 122)
    }

    @Test func durationNeverNegative() {
        let session = SittingSession(
            startedAt: Date(timeIntervalSince1970: 2000),
            endedAt: Date(timeIntervalSince1970: 1000)
        )
        #expect(session.durationSeconds == 0)
    }

    @Test func codableRoundTrip() throws {
        let session = SittingSession(
            startedAt: Date(timeIntervalSince1970: 1000),
            endedAt: Date(timeIntervalSince1970: 1600)
        )

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(SittingSession.self, from: data)

        #expect(decoded == session)
    }
}
