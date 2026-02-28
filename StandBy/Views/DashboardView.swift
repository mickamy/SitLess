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
                Text("今日の座り時間")
                Spacer()
                Text(tracker.formattedDailyTotal)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }

            HStack {
                Text("連続座り時間")
                Spacer()
                Text(tracker.formattedCurrentSession)
                    .fontWeight(.semibold)
                    .foregroundStyle(sessionColor)
                    .monospacedDigit()
            }

            HStack {
                Text("ストレッチ済み")
                Spacer()
                Text("\(tracker.dailyRecord.stretchCount) 回")
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }

            VStack(spacing: 4) {
                ProgressView(value: tracker.progressToNextStretch)
                    .tint(sessionColor)
                Text(tracker.minutesToNextStretch > 0
                    ? "次のストレッチまで \(tracker.minutesToNextStretch)分"
                    : "ストレッチの時間です！")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: { tracker.markStretchDone() }) {
                Text("ストレッチする")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)

            Divider()

            HStack {
                Button("ストレッチ一覧") {
                    showStretches = true
                }
                Spacer()
                Button("設定") {
                    showSettings = true
                }
                Spacer()
                Button("終了") {
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
