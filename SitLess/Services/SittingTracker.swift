import Foundation
import Observation

@Observable
final class SittingTracker {
    // MARK: - Observed State

    private(set) var currentSessionSeconds: Int = 0
    private(set) var dailyRecord: DailyRecord
    var settings: Settings
    let stretches: [Stretch]

    // MARK: - Dependencies

    private let idleTimeProvider: any IdleTimeProviding
    private let storage: any StorageProviding
    private let notifier: StretchNotifier

    // MARK: - Private State

    private var timer: Timer?
    private var currentSession: SittingSession?
    private var notificationsSentInSession: Int = 0

    init(
        idleTimeProvider: any IdleTimeProviding = IOKitIdleTimeProvider(),
        storage: any StorageProviding = UserDefaultsStorageProvider(),
        notifier: StretchNotifier? = nil,
        stretches: [Stretch] = []
    ) {
        self.idleTimeProvider = idleTimeProvider
        self.storage = storage
        self.settings = storage.loadSettings()
        self.dailyRecord = storage.loadDailyRecord(for: CalendarDay())
        self.stretches = stretches
        self.notifier = notifier ?? StretchNotifier(storage: storage)
        startTracking()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Tracking

    func startTracking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    /// Called every 60 seconds by the timer. Internal for testability.
    func tick() {
        checkDateRollover()

        let idleSeconds = idleTimeProvider.systemIdleTime() ?? 0
        let thresholdSeconds = TimeInterval(settings.idleThresholdMinutes * 60)

        if idleSeconds < thresholdSeconds {
            handleActiveState()
        } else {
            handleIdleState(idleSeconds: idleSeconds)
        }

        storage.saveDailyRecord(dailyRecord)
    }

    // MARK: - Actions

    func markStretchDone() {
        dailyRecord.stretchCount += 1

        if let session = currentSession {
            var ended = session
            ended.endedAt = Date()
            dailyRecord.sessions.append(ended)
        }
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
        let today = CalendarDay()
        guard dailyRecord.date != today else { return }

        if let session = currentSession {
            var ended = session
            ended.endedAt = Date()
            dailyRecord.sessions.append(ended)
            storage.saveDailyRecord(dailyRecord)
        }
        dailyRecord = DailyRecord(date: today)
        currentSession = SittingSession(startedAt: Date())
        currentSessionSeconds = 0
        notificationsSentInSession = 0
    }

    private func handleActiveState() {
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
                notifier.sendStretchReminder(stretches: stretches)
            }
        }
    }

    private func handleIdleState(idleSeconds: TimeInterval) {
        var sessions = dailyRecord.sessions.filter { $0.endedAt != nil }
        if let session = currentSession {
            var ended = session
            ended.endedAt = Date().addingTimeInterval(-idleSeconds)
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

    static func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h\(String(format: "%02d", minutes))m"
        }
        return "\(minutes)m"
    }
}
