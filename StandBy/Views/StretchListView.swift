import SwiftUI

struct StretchListView: View {
    let stretches: [Stretch]
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { isPresented = false }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                Text("Stretches")
                    .fontWeight(.semibold)
                Spacer()
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(stretches) { stretch in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(stretch.localizedName)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(stretch.durationSeconds)s")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(stretch.localizedInstruction)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(stretch.localizedTargetArea)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.quaternary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
    }
}
