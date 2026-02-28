import SwiftUI

struct MenuBarLabel: View {
    var tracker: SittingTracker

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "chair.lounge.fill")
            Text(tracker.formattedCurrentSession)
                .monospacedDigit()
        }
    }
}
