import SwiftUI

struct YohakuBlockCard: View {
    let block: YohakuBlock
    @State private var isBreathing = false

    var body: some View {
        TimelineView(.everyMinute) { context in
            let isActive = block.startTime <= context.date && context.date < block.endTime

            HStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isActive ? Color.primary : Color.clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.primary.opacity(isActive ? 1 : 0.5), lineWidth: 1.5)
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
                    .stroke(
                        Color.primary.opacity(isActive ? (isBreathing ? 0.4 : 0.18) : 0.12),
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
            .onAppear {
                updateBreathing(isActive: isActive)
            }
            .onChange(of: isActive) { _, nowActive in
                updateBreathing(isActive: nowActive)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func updateBreathing(isActive: Bool) {
        if isActive {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        } else {
            withAnimation(nil) {
                isBreathing = false
            }
        }
    }
}
