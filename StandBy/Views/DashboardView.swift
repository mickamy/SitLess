import SwiftUI

struct DashboardView: View {
    var tracker: SittingTracker
    @State private var showSettings = false
    @State private var showStretches = false

    var body: some View {
        VStack(spacing: 16) {
            if showSettings {
                SettingsView(tracker: tracker, isPresented: $showSettings)
            } else if showStretches {
                StretchListView(stretches: tracker.stretches, isPresented: $showStretches)
            } else {
                mainDashboard
            }
        }
        .padding()
        .frame(width: 280)
    }

    private var mainDashboard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Today's sitting time")
                Spacer()
                Text(tracker.formattedDailyTotal)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }

            HStack {
                Text("Continuous sitting time")
                Spacer()
                Text(tracker.formattedCurrentSession)
                    .fontWeight(.semibold)
                    .foregroundStyle(sessionColor)
                    .monospacedDigit()
            }

            HStack {
                Text("Stretches done")
                Spacer()
                Text("\(tracker.dailyRecord.stretchCount) times")
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }

            VStack(spacing: 4) {
                ProgressView(value: tracker.progressToNextStretch)
                    .tint(sessionColor)
                Text(tracker.minutesToNextStretch > 0
                    ? "\(tracker.minutesToNextStretch) min to stretch"
                    : "Time to stretch!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: { tracker.markStretchDone() }) {
                Text("Do a stretch")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)

            Divider()

            HStack {
                Button("Stretches") {
                    showStretches = true
                }
                Spacer()
                Button("Settings") {
                    showSettings = true
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .font(.caption)
        }
    }

    private var sessionColor: Color {
        let progress = tracker.progressToNextStretch
        if progress < 0.5 {
            return .green
        } else if progress < 0.8 {
            return .orange
        } else {
            return .red
        }
    }
}
