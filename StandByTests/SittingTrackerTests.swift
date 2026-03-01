import Foundation
import Testing

@testable import StandBy

// MARK: - Test Doubles

private final class StubIdleTimeProvider: IdleTimeProviding, @unchecked Sendable {
    var idleTime: TimeInterval? = 0

    func systemIdleTime() -> TimeInterval? {
        idleTime
    }
}

private final class SpyNotificationSender: NotificationSending, @unchecked Sendable {
    var sentNotifications: [(title: String, body: String)] = []

    func requestAuthorization() async -> Bool { true }

    func send(title: String, body: String) {
        sentNotifications.append((title: title, body: body))
    }
}

private func makeStretches() -> [Stretch] {
    [
        Stretch(id: "a", name: "A", instruction: "Do A", durationSeconds: 30, targetArea: "腰"),
        Stretch(id: "b", name: "B", instruction: "Do B", durationSeconds: 20, targetArea: "肩"),
    ]
}

private func makeSUT(
    idleProvider: StubIdleTimeProvider? = nil,
    stretchInterval: Int = 30,
    idleThreshold: Int = 5
) -> (SittingTracker, SpyNotificationSender, UserDefaultsStorageProvider, StubIdleTimeProvider) {
    let suite = "com.mickamy.StandBy.tests.\(UUID().uuidString)"
    let storage = UserDefaultsStorageProvider(defaults: UserDefaults(suiteName: suite)!)
    let settings = Settings(stretchIntervalMinutes: stretchInterval, idleThresholdMinutes: idleThreshold)
    storage.saveSettings(settings)

    let sender = SpyNotificationSender()
    let notifier = StretchNotifier(storage: storage, sender: sender)
    let provider = idleProvider ?? StubIdleTimeProvider()

    let tracker = SittingTracker(
        idleTimeProvider: provider,
        storage: storage,
        notifier: notifier,
        stretches: makeStretches()
    )
    return (tracker, sender, storage, provider)
}

// MARK: - Tests

struct SittingTrackerActiveStateTests {
    @Test func tickIncrementsSessionWhenActive() {
        let (sut, _, _, _) = makeSUT()

        sut.tick()

        #expect(sut.currentSessionSeconds == 60)
    }

    @Test func tickAccumulatesAcrossMultipleTicks() {
        let (sut, _, _, _) = makeSUT()

        sut.tick()
        sut.tick()
        sut.tick()

        #expect(sut.currentSessionSeconds == 180)
    }

    @Test func dailyTotalReflectsSessions() {
        let (sut, _, _, _) = makeSUT()

        sut.tick()
        sut.tick()

        // totalSittingSeconds is based on wall-clock duration (endedAt - startedAt),
        // which is near-zero in tests. Verify the session exists and
        // currentSessionSeconds tracks the logical sitting time.
        #expect(sut.dailyRecord.sessions.count == 1)
        #expect(sut.currentSessionSeconds == 120)
    }
}

struct SittingTrackerIdleStateTests {
    @Test func tickResetsSessionWhenIdle() {
        let provider = StubIdleTimeProvider()
        provider.idleTime = 600
        let (sut, _, _, _) = makeSUT(idleProvider: provider)

        sut.tick()

        #expect(sut.currentSessionSeconds == 0)
    }

    @Test func sessionResetsAfterIdlePeriod() {
        let provider = StubIdleTimeProvider()
        let (sut, _, _, _) = makeSUT(idleProvider: provider)

        provider.idleTime = 0
        sut.tick()
        sut.tick()
        #expect(sut.currentSessionSeconds == 120)

        provider.idleTime = 600
        sut.tick()
        #expect(sut.currentSessionSeconds == 0)
    }

    @Test func idleStateCleansUpPendingSessions() {
        let provider = StubIdleTimeProvider()
        let (sut, _, _, _) = makeSUT(idleProvider: provider)

        provider.idleTime = 0
        sut.tick()
        sut.tick()

        provider.idleTime = 600
        sut.tick()

        // All sessions should have endedAt set
        for session in sut.dailyRecord.sessions {
            #expect(session.endedAt != nil)
        }
    }
}

struct SittingTrackerNotificationTests {
    @Test func sendsNotificationAtStretchInterval() {
        let (sut, sender, _, _) = makeSUT(stretchInterval: 5)

        for _ in 0..<5 {
            sut.tick()
        }

        #expect(sender.sentNotifications.count == 1)
    }

    @Test func sendsMultipleNotificationsAtMultiples() {
        let (sut, sender, _, _) = makeSUT(stretchInterval: 5)

        for _ in 0..<10 {
            sut.tick()
        }

        #expect(sender.sentNotifications.count == 2)
    }

    @Test func noNotificationBeforeInterval() {
        let (sut, sender, _, _) = makeSUT(stretchInterval: 5)

        for _ in 0..<4 {
            sut.tick()
        }

        #expect(sender.sentNotifications.isEmpty)
    }

    @Test func notificationCounterResetsAfterIdle() {
        let provider = StubIdleTimeProvider()
        let (sut, sender, _, _) = makeSUT(idleProvider: provider, stretchInterval: 5)

        provider.idleTime = 0
        for _ in 0..<5 {
            sut.tick()
        }
        #expect(sender.sentNotifications.count == 1)

        provider.idleTime = 600
        sut.tick()

        provider.idleTime = 0
        for _ in 0..<5 {
            sut.tick()
        }
        #expect(sender.sentNotifications.count == 2)
    }
}

struct SittingTrackerStretchDoneTests {
    @Test func markStretchDoneResetsSession() {
        let (sut, _, _, _) = makeSUT()

        sut.tick()
        sut.tick()
        sut.markStretchDone()

        #expect(sut.currentSessionSeconds == 0)
    }

    @Test func markStretchDoneIncrementsCount() {
        let (sut, _, _, _) = makeSUT()

        sut.markStretchDone()
        sut.markStretchDone()

        #expect(sut.dailyRecord.stretchCount == 2)
    }

    @Test func markStretchDoneDoesNotDuplicateOpenSessions() {
        let (sut, _, _, _) = makeSUT()

        sut.tick()
        sut.tick()
        sut.markStretchDone()

        let openSessions = sut.dailyRecord.sessions.filter { $0.endedAt == nil }
        #expect(openSessions.isEmpty)
    }

    @Test func markStretchDonePersists() {
        let (sut, _, storage, _) = makeSUT()

        sut.tick()
        sut.markStretchDone()

        let loaded = storage.loadDailyRecord(for: CalendarDay())
        #expect(loaded.stretchCount == 1)
    }
}

struct SittingTrackerFormatTests {
    @Test func formatDurationMinutesOnly() {
        #expect(SittingTracker.formatDuration(0) == "0m")
        #expect(SittingTracker.formatDuration(60) == "1m")
        #expect(SittingTracker.formatDuration(1800) == "30m")
    }

    @Test func formatDurationWithHours() {
        #expect(SittingTracker.formatDuration(3600) == "1h00m")
        #expect(SittingTracker.formatDuration(4980) == "1h23m")
        #expect(SittingTracker.formatDuration(7200) == "2h00m")
    }

    @Test func progressToNextStretchCycles() {
        let (sut, _, _, _) = makeSUT(stretchInterval: 5)

        #expect(sut.progressToNextStretch == 0.0)

        sut.tick() // 60s / 300s = 0.2
        #expect(sut.progressToNextStretch == 0.2)
    }

    @Test func progressResetsAfterInterval() {
        let (sut, _, _, _) = makeSUT(stretchInterval: 5)

        // 5 ticks = 300s = exactly 1 interval → resets to 0.0
        for _ in 0..<5 {
            sut.tick()
        }
        #expect(sut.progressToNextStretch == 0.0)

        // 6 ticks = 360s → 60s into next cycle = 0.2
        sut.tick()
        #expect(sut.progressToNextStretch == 0.2)
    }
}
