import SwiftUI

struct YohakuBlockCard: View {
    let block: YohakuBlock

    var body: some View {
        HStack(spacing: 24) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.clear)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.primary.opacity(0.5), lineWidth: 1.5)
                }
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 10) {
                Text(block.title)
                    .font(.body)
                    .foregroundStyle(.primary)

                HStack(spacing: 5) {
                    Text(block.startTime, format: .dateTime.hour().minute())
                    Text(verbatim: "–")
                    Text(block.endTime, format: .dateTime.hour().minute())
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
