import SwiftUI

// 初回起動時に一度だけ表示する、単一ページの簡単な説明
struct OnboardingView: View {
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("AppIconPreview")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                }
                .accessibilityHidden(true)

            VStack(spacing: 14) {
                Text("onboarding.title")
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .multilineTextAlignment(.center)

                Text("onboarding.body")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 12)
            }
            .padding(.top, 28)

            Spacer()
            Spacer()

            Button(action: onFinish) {
                Text("onboarding.button")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.primary, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
            .accessibilityIdentifier("onboarding-finish-button")
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
