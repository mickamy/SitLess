import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Bindable var tracker: SittingTracker
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { isPresented = false }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                Text("Settings")
                    .fontWeight(.semibold)
                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Stepper(
                    "Stretch interval: \(tracker.settings.stretchIntervalMinutes) min",
                    value: $tracker.settings.stretchIntervalMinutes,
                    in: Settings.stretchIntervalRange,
                    step: 5
                )

                Stepper(
                    "Idle threshold: \(tracker.settings.idleThresholdMinutes) min",
                    value: $tracker.settings.idleThresholdMinutes,
                    in: Settings.idleThresholdRange
                )

                Toggle("Launch at login", isOn: $tracker.settings.launchAtLogin)
            }
        }
        .onChange(of: tracker.settings) {
            tracker.saveSettings()
        }
        .onChange(of: tracker.settings.launchAtLogin) {
            updateLoginItem()
        }
    }

    private func updateLoginItem() {
        do {
            if tracker.settings.launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            assertionFailure("Failed to update login item: \(error)")
        }
    }
}
