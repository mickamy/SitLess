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
                Text("ストレッチ一覧")
                    .fontWeight(.semibold)
                Spacer()
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(stretches) { stretch in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(stretch.name)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(stretch.durationSeconds)秒")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(stretch.instruction)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(stretch.targetArea)
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
