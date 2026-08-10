import SwiftUI

struct ReflectionPromptCard: View {
    let block: YohakuBlock
    let onRespond: (YohakuReflectionResponse) -> Void
    let onDismiss: () -> Void

    @State private var horizontalOffset: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("reflection.question")
                        .font(.headline)
                        .accessibilityIdentifier("reflection-question")
                    Text(block.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color.primary.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("action.close"))
            }

            HStack(spacing: 8) {
                ForEach(YohakuReflectionResponse.allCases) { response in
                    Button {
                        onRespond(response)
                    } label: {
                        Text(LocalizedStringKey(response.titleKey))
                            .font(.caption.weight(.medium))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 38)
                            .padding(.horizontal, 4)
                            .background(Color.primary.opacity(0.055), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .offset(x: horizontalOffset)
        .opacity(Double(1 - min(abs(horizontalOffset) / CGFloat(240), CGFloat(0.7))))
        .gesture(
            DragGesture(minimumDistance: 18)
                .onChanged { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    horizontalOffset = value.translation.width
                }
                .onEnded { value in
                    if abs(value.translation.width) > 90 {
                        onDismiss()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            horizontalOffset = 0
                        }
                    }
                }
        )
        .accessibilityElement(children: .contain)
    }
}
