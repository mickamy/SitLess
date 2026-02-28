import Foundation
import Testing
import WatchKit

@testable import StandByWatch

/// @unchecked Sendable: Test-only stub; no concurrent mutation.
private final class StubMotionProvider: MotionActivityProviding, @unchecked Sendable {
    var stationaryDuration: TimeInterval = 0

    func startMonitoring(handler: @escaping @Sendable (Bool) -> Void) {}
    func stopMonitoring() {}
    func queryStationaryDuration(from start: Date, to end: Date) async -> TimeInterval {
        stationaryDuration
    }
}

/// @unchecked Sendable: Test-only spy; mutated only from test thread.
private final class SpyNotificationSender: NotificationSending, @unchecked Sendable {
    var sentNotifications: [(title: String, body: String)] = []

    func requestAuthorization() async -> Bool { true }

    func send(title: String, body: String) {
        sentNotifications.append((title: title, body: body))
    }
}

/// @unchecked Sendable: Test-only spy; mutated only from test thread.
private final class SpyHapticPlayer: HapticPlaying, @unchecked Sendable {
    var playedTypes: [WKHapticType] = []

    func play(_ type: WKHapticType) {
        playedTypes.append(type)
    }
}

private let testStretches = [
    Stretch(id: "a", name: "ストレッチA", instruction: "説明A", durationSeconds: 30, targetArea: "腰"),
    Stretch(id: "b", name: "ストレッチB", instruction: "説明B", durationSeconds: 20, targetArea: "肩"),
]

@MainActor
struct WatchSittingTrackerTests {
    private func makeSUT(
        hapticEnabled: Bool = true,
        today: @escaping () -> CalendarDay = { CalendarDay() }
    ) -> (WatchSittingTracker, SpyNotificationSender, SpyHapticPlayer, StubMotionProvider) {
        let suite = "com.mickamy.StandBy.tests.\(UUID().uuidString)"
        let storage = UserDefaultsStorageProvider(defaults: UserDefaults(suiteName: suite)!)
        let sender = SpyNotificationSender()
        let haptic = SpyHapticPlayer()
        let notifier = WatchStretchNotifier(storage: storage, sender: sender, haptic: haptic)
        let motion = StubMotionProvider()

        let tracker = WatchSittingTracker(
            motionProvider: motion,
            storage: storage,
            notifier: notifier,
            stretches: testStretches,
            watchSettings: WatchSettings(hapticEnabled: hapticEnabled),
            today: today
        )
        return (tracker, sender, haptic, motion)
    }

    @Test func tickIncrementsSittingWhenStationary() {
        let (sut, _, _, _) = makeSUT()
        sut.isStationary = true
        sut.tick()
        #expect(sut.currentSessionSeconds == 60)
    }

    @Test func tickAccumulatesSitting() {
        let (sut, _, _, _) = makeSUT()
        sut.isStationary = true
        sut.tick()
        sut.tick()
        #expect(sut.currentSessionSeconds == 120)
    }

    @Test func tickResetsWhenNotStationary() {
        let (sut, _, _, _) = makeSUT()
        sut.isStationary = true
        sut.tick()
        sut.isStationary = false
        sut.tick()
        #expect(sut.currentSessionSeconds == 0)
    }

    @Test func tickRecordsSittingSession() {
        let (sut, _, _, _) = makeSUT()
        sut.isStationary = true
        sut.tick()
        #expect(sut.dailyRecord.sessions.count == 1)
    }

    @Test func tickEndsSessionWhenNotStationary() {
        let (sut, _, _, _) = makeSUT()
        sut.isStationary = true
        sut.tick()
        sut.isStationary = false
        sut.tick()
        #expect(sut.dailyRecord.sessions.allSatisfy { $0.endedAt != nil })
    }

    @Test func tickSendsNotificationAtInterval() {
        let (sut, sender, _, _) = makeSUT()
        sut.settings = Settings(stretchIntervalMinutes: 5)
        sut.isStationary = true
        for _ in 1...5 { sut.tick() } // 5 min = interval
        #expect(sender.sentNotifications.count == 1)
    }

    @Test func tickDoesNotSendNotificationBeforeInterval() {
        let (sut, sender, _, _) = makeSUT()
        sut.settings = Settings(stretchIntervalMinutes: 5)
        sut.isStationary = true
        for _ in 1...4 { sut.tick() } // 4 min < interval
        #expect(sender.sentNotifications.isEmpty)
    }

    @Test func tickPlaysHapticWhenEnabled() {
        let (sut, _, haptic, _) = makeSUT(hapticEnabled: true)
        sut.settings = Settings(stretchIntervalMinutes: 5)
        sut.isStationary = true
        for _ in 1...5 { sut.tick() }
        #expect(haptic.playedTypes == [.notification])
    }

    @Test func tickSkipsHapticWhenDisabled() {
        let (sut, _, haptic, _) = makeSUT(hapticEnabled: false)
        sut.settings = Settings(stretchIntervalMinutes: 5)
        sut.isStationary = true
        for _ in 1...5 { sut.tick() }
        #expect(haptic.playedTypes.isEmpty)
    }

    @Test func markStretchDoneResetsSession() {
        let (sut, _, _, _) = makeSUT()
        sut.isStationary = true
        sut.tick()
        sut.tick()
        sut.markStretchDone()
        #expect(sut.currentSessionSeconds == 0)
        #expect(sut.dailyRecord.stretchCount == 1)
    }

    @Test func tickSendsMultipleNotificationsAcrossIntervals() {
        let (sut, sender, _, _) = makeSUT()
        sut.settings = Settings(stretchIntervalMinutes: 5)
        sut.isStationary = true
        for _ in 1...10 { sut.tick() } // 10 min = 2 intervals
        #expect(sender.sentNotifications.count == 2)
    }

    @Test func dateRolloverResetsSession() {
        var fakeDate = Date()
        let (sut, _, _, _) = makeSUT(today: { CalendarDay(fakeDate) })

        sut.isStationary = true
        sut.tick()
        #expect(sut.currentSessionSeconds == 60)

        fakeDate = Calendar.current.date(byAdding: .day, value: 1, to: fakeDate)!
        sut.tick()

        // After rollover, session resets to 0 then handleSitting adds 60.
        #expect(sut.currentSessionSeconds == 60)
        #expect(sut.dailyRecord.date == CalendarDay(fakeDate))
    }

    @Test func progressToNextStretch() {
        let (sut, _, _, _) = makeSUT()
        sut.settings = Settings(stretchIntervalMinutes: 5) // 300s
        sut.isStationary = true
        sut.tick() // 60s
        #expect(sut.progressToNextStretch == 60.0 / 300.0)
    }

    @Test func minutesToNextStretch() {
        let (sut, _, _, _) = makeSUT()
        sut.settings = Settings(stretchIntervalMinutes: 5)
        sut.isStationary = true
        sut.tick() // 60s sitting, 240s remaining = 4 min
        #expect(sut.minutesToNextStretch == 4)
    }

    @Test func formatDuration() {
        #expect(WatchSittingTracker.formatDuration(0) == "0m")
        #expect(WatchSittingTracker.formatDuration(300) == "5m")
        #expect(WatchSittingTracker.formatDuration(3660) == "1h01m")
        #expect(WatchSittingTracker.formatDuration(7200) == "2h00m")
    }

    // MARK: - Background Update Tests

    @Test func performBackgroundUpdateAddsSittingTime() async {
        let (sut, _, _, motion) = makeSUT()
        motion.stationaryDuration = 300 // 5 minutes stationary
        sut.lastCheckDate = Date(timeIntervalSinceNow: -600)

        await sut.performBackgroundUpdate()

        #expect(sut.currentSessionSeconds == 300)
    }

    @Test func performBackgroundUpdateSendsNotificationAtThreshold() async {
        let (sut, sender, _, motion) = makeSUT()
        sut.settings = Settings(stretchIntervalMinutes: 5)
        motion.stationaryDuration = 300 // exactly 5 min
        sut.lastCheckDate = Date(timeIntervalSinceNow: -600)

        await sut.performBackgroundUpdate()

        #expect(sender.sentNotifications.count == 1)
    }

    @Test func performBackgroundUpdateUpdatesLastCheckDate() async {
        let (sut, _, _, motion) = makeSUT()
        motion.stationaryDuration = 60
        let before = Date()
        sut.lastCheckDate = Date(timeIntervalSinceNow: -120)

        await sut.performBackgroundUpdate()

        #expect(sut.lastCheckDate != nil)
        #expect(sut.lastCheckDate! >= before)
    }

    @Test func performBackgroundUpdateNoOpWhenNoStationaryTime() async {
        let (sut, sender, _, motion) = makeSUT()
        motion.stationaryDuration = 0
        sut.lastCheckDate = Date(timeIntervalSinceNow: -600)

        await sut.performBackgroundUpdate()

        #expect(sut.currentSessionSeconds == 0)
        #expect(sender.sentNotifications.isEmpty)
    }

    @Test func startTrackingSetsLastCheckDate() {
        let (sut, _, _, _) = makeSUT()
        #expect(sut.lastCheckDate == nil)
        sut.startTracking()
        #expect(sut.lastCheckDate != nil)
        sut.stopTracking()
    }

    @Test func tickUpdatesLastCheckDate() {
        let (sut, _, _, _) = makeSUT()
        #expect(sut.lastCheckDate == nil)
        sut.isStationary = true
        sut.tick()
        #expect(sut.lastCheckDate != nil)
    }
}
