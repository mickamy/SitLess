import SwiftUI
import UserNotifications

@main
struct SitLessApp: App {
    @State private var tracker = SittingTracker(
        stretches: loadBundledStretches()
    )

    var body: some Scene {
        MenuBarExtra {
            DashboardView(tracker: tracker)
        } label: {
            MenuBarLabel(tracker: tracker)
        }
        .menuBarExtraStyle(.window)
    }

    init() {
        Task {
            try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        }
    }
}

private func loadBundledStretches() -> [Stretch] {
    guard let url = Bundle.main.url(forResource: "Stretches", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let stretches = try? JSONDecoder().decode([Stretch].self, from: data)
    else {
        assertionFailure("Failed to load Stretches.json from bundle")
        return []
    }
    return stretches
}
