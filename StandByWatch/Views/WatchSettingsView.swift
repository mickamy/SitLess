import SwiftUI

struct WatchSettingsView: View {
    @Bindable var tracker: WatchSittingTracker

    var body: some View {
        Form {
            Section("Stretch interval") {
                Stepper(
                    "\(tracker.settings.stretchIntervalMinutes) min",
                    value: $tracker.settings.stretchIntervalMinutes,
                    in: 5...120,
                    step: 5
                )
                .onChange(of: tracker.settings.stretchIntervalMinutes) {
                    tracker.saveSettings()
                }
            }

            Section("Haptic") {
                Toggle("Vibrate on reminder", isOn: $tracker.watchSettings.hapticEnabled)
                    .onChange(of: tracker.watchSettings.hapticEnabled) {
                        tracker.watchSettings.save()
                    }
            }
        }
        .navigationTitle("Settings")
    }
}
