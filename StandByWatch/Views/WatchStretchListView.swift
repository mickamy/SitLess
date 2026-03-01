import SwiftUI

struct WatchStretchListView: View {
    let stretches: [Stretch]

    var body: some View {
        List(stretches) { stretch in
            NavigationLink(destination: StretchDetailView(stretch: stretch)) {
                VStack(alignment: .leading) {
                    Text(stretch.localizedName)
                        .font(.caption)
                    Text("\(stretch.durationSeconds)s")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Stretches")
    }
}

private struct StretchDetailView: View {
    let stretch: Stretch

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(stretch.localizedName)
                    .font(.headline)
                Text("\(stretch.durationSeconds) seconds")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Divider()
                Text(stretch.localizedInstruction)
                    .font(.caption2)
            }
            .padding(.horizontal)
        }
        .navigationTitle(stretch.localizedName)
    }
}
