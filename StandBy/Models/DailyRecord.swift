import Foundation

nonisolated struct CalendarDay: Codable, Equatable, Sendable, CustomStringConvertible {
    let value: String

    init(_ date: Date = Date(), calendar: Calendar = .current) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = calendar
        self.value = formatter.string(from: date)
    }

    var description: String { value }
}

nonisolated struct DailyRecord: Codable, Equatable, Sendable {
    var date: CalendarDay
    var stretchCount: Int = 0
    var sessions: [SittingSession] = []

    var totalSittingSeconds: Int {
        sessions.reduce(0) { $0 + $1.durationSeconds }
    }
}

nonisolated struct SittingSession: Codable, Equatable, Sendable {
    var startedAt: Date
    var endedAt: Date?

    var durationSeconds: Int {
        let end = endedAt ?? Date()
        return max(0, Int(end.timeIntervalSince(startedAt)))
    }
}
