import Foundation
import Observation

@Observable
final class WatchSittingTracker {
    // MARK: - Observed State

    private(set) var currentSessionSeconds: Int = 0
    private(set) var dailyRecord: DailyRecord
    var settings: Settings
    var watchSettings: WatchSettings
    let stretches: [Stretch]

    // MARK: - Dependencies

    private let motionProvider: any MotionActivityProviding
    private let storage: any StorageProviding
    private let notifier: WatchStretchNotifier

    // MARK: - Private State

    private var timer: Timer?
    private var currentSession: SittingSession?
    private var notificationsSentInSession: Int = 0
    private let today: () -> CalendarDay
    /// Internal for testability; updated by MotionActivityProviding callback.
    var isStationary: Bool = false
    /// Tracks the last time background or foreground processing occurred.
    var lastCheckDate: Date?

    init(
        motionProvider: any MotionActivityProviding = CMMotionActivityProvider(),
        storage: any StorageProviding = UserDefaultsStorageProvider(),
        notifier: WatchStretchNotifier? = nil,
        stretches: [Stretch] = [],
        watchSettings: WatchSettings = .load(),
        today: @escaping () -> CalendarDay = { CalendarDay() }
    ) {
        self.motionProvider = motionProvider
        self.storage = storage
        self.today = today
        self.settings = storage.loadSettings()
        self.dailyRecord = storage.loadDailyRecord(for: today())
        self.stretches = stretches
        self.watchSettings = watchSettings
        self.notifier = notifier ?? WatchStretchNotifier(storage: storage)
        self.lastCheckDate = storage.loadLastCheckDate()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Tracking

    func startTracking() {
        updateLastCheckDate(Date())
        motionProvider.startMonitoring { stationary in
            Task { @MainActor [weak self] in
                self?.isStationary = stationary
            }
        }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stopTracking() {
        motionProvider.stopMonitoring()
        timer?.invalidate()
        timer = nil
    }

    /// Called every 60 seconds by the timer. Internal for testability.
    func tick() {
        updateLastCheckDate(Date())
        checkDateRollover()

        if isStationary {
            handleSitting()
        } else {
            handleNotSitting()
        }

        storage.saveDailyRecord(dailyRecord)
    }

    /// Called from the background refresh task to catch up on missed sitting time.
    func performBackgroundUpdate() async {
        let now = Date()
        let start = lastCheckDate ?? now

        guard start < now else {
            updateLastCheckDate(now)
            return
        }

        checkDateRollover()

        // Close orphaned open sessions from a previous app run.
        // When the app is terminated by the system, currentSession is lost
        // but the open session remains in dailyRecord.sessions.
        if currentSession == nil {
            dailyRecord.sessions = dailyRecord.sessions.map { session in
                guard session.endedAt == nil else { return session }
                var closed = session
                closed.endedAt = start
                return closed
            }
        }

        let stationarySeconds = await motionProvider.queryStationaryDuration(from: start, to: now)
        let stationaryMinutes = Int(stationarySeconds) / 60

        if stationaryMinutes > 0 {
            let additionalSeconds = stationaryMinutes * 60
            if currentSession == nil {
                // Align startedAt with stationary duration so durationSeconds
                // stays consistent with currentSessionSeconds.
                currentSession = SittingSession(startedAt: now.addingTimeInterval(TimeInterval(-additionalSeconds)))
            }
            currentSessionSeconds += additionalSeconds
            dailyRecord.sessions = updateCurrentSessionInList()

            let intervalSeconds = settings.stretchIntervalMinutes * 60
            if intervalSeconds > 0 {
                let expected = currentSessionSeconds / intervalSeconds
                if expected > notificationsSentInSession {
                    // Send at most one notification per background catch-up
                    // to avoid flooding the user after a long background period.
                    notifier.sendStretchReminder(
                        stretches: stretches,
                        hapticEnabled: watchSettings.hapticEnabled
                    )
                    notificationsSentInSession = expected
                }
            }
        }

        // Sync isStationary with recent motion so the first foreground tick
        // does not immediately reset the restored session.
        let recentStationary = await motionProvider.queryStationaryDuration(
            from: Date(timeIntervalSinceNow: -60), to: now
        )
        isStationary = recentStationary > 30

        updateLastCheckDate(now)
        storage.saveDailyRecord(dailyRecord)
    }

    // MARK: - Actions

    func markStretchDone() {
        dailyRecord.stretchCount += 1

        var sessions = dailyRecord.sessions.filter { $0.endedAt != nil }
        if let session = currentSession {
            var ended = session
            ended.endedAt = Date()
            sessions.append(ended)
        }
        dailyRecord.sessions = sessions

        currentSession = SittingSession(startedAt: Date())
        currentSessionSeconds = 0
        notificationsSentInSession = 0

        storage.saveDailyRecord(dailyRecord)
    }

    func saveSettings() {
        storage.saveSettings(settings)
    }

    // MARK: - Computed Properties

    var formattedCurrentSession: String {
        Self.formatDuration(currentSessionSeconds)
    }

    var formattedDailyTotal: String {
        Self.formatDuration(dailyRecord.totalSittingSeconds)
    }

    var progressToNextStretch: Double {
        let interval = settings.stretchIntervalMinutes * 60
        guard interval > 0 else { return 0 }
        return Double(currentSessionSeconds % interval) / Double(interval)
    }

    var minutesToNextStretch: Int {
        let interval = settings.stretchIntervalMinutes * 60
        guard interval > 0 else { return 0 }
        let remaining = interval - (currentSessionSeconds % interval)
        return remaining / 60
    }

    // MARK: - Private

    private func checkDateRollover() {
        let currentDay = today()
        guard dailyRecord.date != currentDay else { return }

        if let session = currentSession {
            var ended = session
            ended.endedAt = Date()
            dailyRecord.sessions.append(ended)
            storage.saveDailyRecord(dailyRecord)
        }
        dailyRecord = DailyRecord(date: currentDay)
        currentSession = SittingSession(startedAt: Date())
        currentSessionSeconds = 0
        notificationsSentInSession = 0
    }

    private func handleSitting() {
        if currentSession == nil {
            currentSession = SittingSession(startedAt: Date())
        }
        currentSessionSeconds += 60
        dailyRecord.sessions = updateCurrentSessionInList()

        let intervalSeconds = settings.stretchIntervalMinutes * 60
        if intervalSeconds > 0 {
            let expected = currentSessionSeconds / intervalSeconds
            if expected > notificationsSentInSession {
                notificationsSentInSession = expected
                notifier.sendStretchReminder(
                    stretches: stretches,
                    hapticEnabled: watchSettings.hapticEnabled
                )
            }
        }
    }

    private func handleNotSitting() {
        var sessions = dailyRecord.sessions.filter { $0.endedAt != nil }
        if let session = currentSession {
            var ended = session
            ended.endedAt = Date()
            sessions.append(ended)
        }
        dailyRecord.sessions = sessions
        currentSession = nil
        currentSessionSeconds = 0
        notificationsSentInSession = 0
    }

    private func updateCurrentSessionInList() -> [SittingSession] {
        guard let session = currentSession else { return dailyRecord.sessions }
        var sessions = dailyRecord.sessions.filter { $0.endedAt != nil }
        sessions.append(session)
        return sessions
    }

    private func updateLastCheckDate(_ date: Date) {
        lastCheckDate = date
        storage.saveLastCheckDate(date)
    }

    // NOTE: Identical to SittingTracker (macOS). Kept inline for simplicity.
    static func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h\(String(format: "%02d", minutes))m"
        }
        return "\(minutes)m"
    }
}
