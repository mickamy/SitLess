import WatchKit

final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    let tracker: WatchSittingTracker

    override init() {
        let stretches = Self.loadStretches()
        tracker = WatchSittingTracker(stretches: stretches)
        super.init()
    }

    func applicationDidBecomeActive() {
        Task { @MainActor in
            await tracker.performBackgroundUpdate()
            tracker.startTracking()
        }
    }

    func applicationWillResignActive() {
        tracker.stopTracking()
        scheduleBackgroundRefresh()
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                var backgroundTask: Task<Void, Never>?

                refreshTask.expirationHandler = {
                    backgroundTask?.cancel()
                }

                backgroundTask = Task { @MainActor in
                    defer { refreshTask.setTaskCompletedWithSnapshot(false) }
                    await tracker.performBackgroundUpdate()
                    scheduleBackgroundRefresh()
                }
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    private func scheduleBackgroundRefresh() {
        let preferredDate = Date(timeIntervalSinceNow: 15 * 60)
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: preferredDate,
            userInfo: nil
        ) { error in
            if let error {
                assertionFailure("Failed to schedule background refresh: \(error)")
            }
        }
    }

    private static func loadStretches() -> [Stretch] {
        guard let url = Bundle.main.url(forResource: "Stretches", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let stretches = try? JSONDecoder().decode([Stretch].self, from: data)
        else { return [] }
        return stretches
    }
}
