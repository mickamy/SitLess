import SwiftUI

@main
struct StandByWatchApp: App {
    @State private var tracker: WatchSittingTracker

    init() {
        let stretches = Self.loadStretches()
        tracker = WatchSittingTracker(stretches: stretches)
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchDashboardView(tracker: tracker)
            }
            .onAppear { tracker.startTracking() }
            .onDisappear { tracker.stopTracking() }
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
