import SwiftUI

struct WatchSettingsView: View {
    @Bindable var tracker: WatchSittingTracker

    private let intervalOptions = Array(stride(from: 5, through: 120, by: 5))

    var body: some View {
        List {
            Section("Stretch interval") {
                Picker("Interval", selection: $tracker.settings.stretchIntervalMinutes) {
                    ForEach(intervalOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
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
