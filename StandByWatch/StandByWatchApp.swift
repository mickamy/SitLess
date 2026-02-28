import SwiftUI

@main
struct StandByWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchDashboardView(tracker: delegate.tracker)
            }
        }
    }
}
