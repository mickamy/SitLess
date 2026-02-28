import SwiftUI

struct WatchDashboardView: View {
    @Bindable var tracker: WatchSittingTracker

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text(tracker.formattedCurrentSession)
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(sessionColor)
                        .monospacedDigit()
                    Text("Sitting time")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: tracker.progressToNextStretch)
                    .tint(sessionColor)

                Text(tracker.minutesToNextStretch > 0
                    ? "\(tracker.minutesToNextStretch) min to stretch"
                    : "Time to stretch!")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button(action: { tracker.markStretchDone() }) {
                    Label("Stretch", systemImage: "figure.cooldown")
                }

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

                Divider()

                HStack {
                    NavigationLink("Stretches", destination: WatchStretchListView(stretches: tracker.stretches))
                    Spacer()
                    NavigationLink("Settings", destination: WatchSettingsView(tracker: tracker))
                }
                .font(.caption)
            }
            .padding(.horizontal)
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
