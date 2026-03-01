import SwiftUI

struct WatchDashboardView: View {
    @Bindable var tracker: WatchSittingTracker

    var body: some View {
        List {
            Section {
                VStack(spacing: 4) {
                    Text(tracker.formattedCurrentSession)
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(sessionColor)
                        .monospacedDigit()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(tracker.isStationary ? Color.green : Color.gray)
                            .frame(width: 6, height: 6)
                        Text(tracker.isStationary ? "Sitting" : "Active")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                ProgressView(value: tracker.progressToNextStretch)
                    .tint(sessionColor)

                Text(tracker.minutesToNextStretch > 0
                    ? "\(tracker.minutesToNextStretch) min to stretch"
                    : "Time to stretch!")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }

            Section {
                Button(action: { tracker.markStretchDone() }) {
                    Label("Stretch", systemImage: "figure.cooldown")
                        .frame(maxWidth: .infinity)
                }
            }

            Section {
                HStack {
                    VStack {
                        Text(tracker.formattedDailyTotal)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                        Text("Daily total")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack {
                        Text("\(tracker.dailyRecord.stretchCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                        Text("Stretches")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                NavigationLink(destination: WatchStretchListView(stretches: tracker.stretches)) {
                    Label("Stretches", systemImage: "list.bullet")
                }
                NavigationLink(destination: WatchSettingsView(tracker: tracker)) {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .navigationTitle("StandBy")
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
