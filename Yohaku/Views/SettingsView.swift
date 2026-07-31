import SwiftUI
import SwiftData
import UIKit

enum AppInfo {
    private static var configuredSiteURL: URL {
        let configuredValue = Bundle.main.object(forInfoDictionaryKey: "YohakuSiteBaseURL") as? String
        return URL(string: configuredValue ?? "") ??
            URL(string: "https://yohaku.tmkch.io/")!
    }

    static let officialSiteURL = configuredSiteURL
    static let privacyPolicyURL = configuredSiteURL.appending(path: "privacy", directoryHint: .notDirectory)
    static let termsURL = configuredSiteURL.appending(path: "terms", directoryHint: .notDirectory)
    static let commercialTransactionsURL = configuredSiteURL.appending(
        path: "commercial-transactions",
        directoryHint: .notDirectory
    )
    static let supportEmail = "support@tmkch.io"
    static let supportEmailURL = URL(string: "mailto:support@tmkch.io?subject=Yohaku")!
    static let developerWebsiteURL = URL(string: "https://tomokichi.dev")!
    static let developerAppsURL = URL(string: "https://tmkch.io")!
    static let developerName = "Tomokichi"

    static let legalEnactedDate = DateComponents(
        calendar: .init(identifier: .gregorian),
        year: 2026,
        month: 7,
        day: 29
    ).date!
    static let legalLastUpdatedDate = legalEnactedDate

    static var appStoreID: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "YohakuAppStoreID") as? String,
              !value.isEmpty,
              value != "0000000000" else {
            return nil
        }
        return value
    }
    static var appStoreProductURL: URL? {
        appStoreID.flatMap { URL(string: "https://apps.apple.com/app/id\($0)") }
    }
    static var appStoreReviewURL: URL? {
        appStoreID.flatMap { URL(string: "https://apps.apple.com/app/id\($0)?action=write-review") }
    }

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(SupportPurchaseStore.self) private var purchaseStore
    @Environment(AdConsentManager.self) private var adConsentManager
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @State private var isShowingDeniedAlert = false
    @Query private var blocks: [YohakuBlock]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    appHeader
                    supportCard

                    settingsSection("settings.app") {
                        appearanceRow
                        rowDivider
                        notificationRow
                        if !purchaseStore.hasRemovedAds && adConsentManager.privacyOptionsRequired {
                            rowDivider
                            Button {
                                Task { await adConsentManager.presentPrivacyOptions() }
                            } label: {
                                row(
                                    title: "ads.privacy_settings",
                                    subtitle: "ads.privacy_settings.subtitle",
                                    systemImage: "hand.raised"
                                )
                            }
                        }
                    }

                    settingsSection("settings.help") {
                        NavigationLink {
                            ContactView()
                        } label: {
                            row(
                                title: "settings.contact",
                                subtitle: "settings.contact.subtitle",
                                systemImage: "bubble.left.and.bubble.right"
                            )
                        }

                        if let reviewURL = AppInfo.appStoreReviewURL {
                            rowDivider

                            Button {
                                openURL(reviewURL)
                            } label: {
                                row(
                                    title: "settings.rate",
                                    subtitle: "settings.rate.subtitle",
                                    systemImage: "star"
                                )
                            }
                        }

                        if let productURL = AppInfo.appStoreProductURL {
                            rowDivider

                            ShareLink(item: productURL) {
                                row(
                                    title: "settings.share",
                                    subtitle: "settings.share.subtitle",
                                    systemImage: "square.and.arrow.up"
                                )
                            }
                        }
                    }

                    settingsSection("settings.legal") {
                        NavigationLink {
                            LegalDocumentView(
                                titleKey: "settings.privacy",
                                bodyKey: "privacy.body",
                                url: AppInfo.privacyPolicyURL
                            )
                        } label: {
                            compactRow("settings.privacy")
                        }

                        rowDivider

                        NavigationLink {
                            LegalDocumentView(
                                titleKey: "settings.terms",
                                bodyKey: "terms.body",
                                url: AppInfo.termsURL
                            )
                        } label: {
                            compactRow("settings.terms")
                        }

                        rowDivider

                        NavigationLink {
                            LegalDocumentView(
                                titleKey: "settings.commercial_transactions",
                                bodyKey: nil,
                                url: AppInfo.commercialTransactionsURL
                            )
                        } label: {
                            compactRow("settings.commercial_transactions")
                        }
                    }

                    settingsSection("settings.about") {
                        Button {
                            openURL(AppInfo.officialSiteURL)
                        } label: {
                            externalRow(
                                "settings.official_site",
                                value: AppInfo.officialSiteURL.host() ?? "Yohaku"
                            )
                        }

                        rowDivider

                        Button {
                            openURL(AppInfo.supportEmailURL)
                        } label: {
                            externalRow("settings.support_email", value: AppInfo.supportEmail)
                        }

                        rowDivider

                        Button {
                            openURL(AppInfo.developerWebsiteURL)
                        } label: {
                            externalRow("settings.developer", value: AppInfo.developerName)
                        }

                        rowDivider

                        Button {
                            openURL(AppInfo.developerAppsURL)
                        } label: {
                            externalRow("settings.other_apps", value: "tmkch.io")
                        }
                    }

                    Text(verbatim: "© \(currentYear) \(AppInfo.developerName)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.medium))
                    }
                    .accessibilityLabel(Text("action.close"))
                }
            }
            .alert("notification.denied.title", isPresented: $isShowingDeniedAlert) {
                Button("action.open_settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                Button("action.close", role: .cancel) {}
            } message: {
                Text("notification.denied.message")
            }
            .alert(
                "purchase.error",
                isPresented: Binding(
                    get: { purchaseStore.errorMessage != nil },
                    set: { if !$0 { purchaseStore.clearError() } }
                )
            ) {
                Button("action.close", role: .cancel) {
                    purchaseStore.clearError()
                }
            } message: {
                Text(purchaseStore.errorMessage ?? "")
            }
        }
        .tint(.primary)
    }

    private var appHeader: some View {
        HStack(spacing: 14) {
            Image("AppIconPreview")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 4) {
                BrandMark()
                Text("settings.tagline")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(verbatim: "Version \(AppInfo.version)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(
                purchaseStore.hasRemovedAds ? "purchase.thanks.title" : "purchase.title",
                systemImage: purchaseStore.hasRemovedAds ? "cup.and.saucer.fill" : "cup.and.saucer"
            )
            .font(.headline)

            Text(purchaseStore.hasRemovedAds ? "purchase.thanks.message" : "purchase.message")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)

            if !purchaseStore.hasRemovedAds {
                Button {
                    Task { await purchaseStore.purchase() }
                } label: {
                    HStack {
                        if purchaseStore.isLoading {
                            ProgressView()
                                .tint(Color(.systemBackground))
                        }
                        Text("purchase.button")
                        Spacer()
                        if let displayPrice = purchaseStore.product?.displayPrice {
                            Text(verbatim: displayPrice)
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.systemBackground))
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Color.primary, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(purchaseStore.isLoading)
            }

            Button("purchase.restore") {
                Task { await purchaseStore.restore() }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .disabled(purchaseStore.isLoading)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private var appearanceRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("appearance.title", systemImage: "circle.lefthalf.filled")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 8) {
                ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                    let isSelected = appearanceMode == mode.rawValue
                    Button {
                        appearanceMode = mode.rawValue
                    } label: {
                        Text(mode.labelKey)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(isSelected ? Color(.systemBackground) : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.primary : Color.clear, in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(Color.primary.opacity(isSelected ? 0 : 0.15), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(15)
    }

    private var notificationRow: some View {
        Toggle(isOn: $notificationsEnabled) {
            Label("notification.title", systemImage: "bell")
                .font(.subheadline.weight(.medium))
        }
        .toggleStyle(MonoToggleStyle())
        .padding(15)
        .onChange(of: notificationsEnabled) { _, enabled in
            if enabled {
                NotificationManager.requestAuthorization { granted in
                    if granted {
                        NotificationManager.rescheduleAll(blocks)
                    } else {
                        notificationsEnabled = false
                        isShowingDeniedAlert = true
                    }
                }
            } else {
                NotificationManager.cancelAll()
            }
        }
    }

    private func settingsSection<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 5)

            VStack(spacing: 0, content: content)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
                .buttonStyle(.plain)
        }
    }

    private func row(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        systemImage: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(15)
        .contentShape(Rectangle())
    }

    private func compactRow(_ title: LocalizedStringKey) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(15)
        .contentShape(Rectangle())
    }

    private func externalRow(_ title: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(verbatim: value)
                .font(.caption)
                .foregroundStyle(.secondary)
            Image(systemName: "arrow.up.forward.square")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(15)
        .contentShape(Rectangle())
    }

    private var rowDivider: some View {
        Divider()
            .padding(.leading, 15)
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
}

struct MonoToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                Spacer()
                Capsule()
                    .fill(configuration.isOn ? Color.primary : Color.primary.opacity(0.15))
                    .frame(width: 52, height: 32)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle()
                            .fill(Color(.systemBackground))
                            .overlay {
                                Circle()
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            }
                            .padding(3)
                    }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: configuration.isOn)
    }
}

struct ContactView: View {
    @State private var viewModel = SupportViewModel()

    var body: some View {
        Group {
            if case .success(let response) = viewModel.state {
                ContentUnavailableView {
                    Label("support.success.title", systemImage: "checkmark.circle")
                } description: {
                    Text("support.success.message")
                } actions: {
                    Button("support.new_inquiry") {
                        viewModel.startNewInquiry()
                    }
                }
                .accessibilityValue(Text(verbatim: response.requestId.uuidString))
            } else {
                Form {
                    Section {
                        Picker("settings.contact.category", selection: $viewModel.category) {
                            ForEach(SupportCategory.allCases) { category in
                                Text(LocalizedStringKey(category.localizationKey))
                                    .tag(category)
                            }
                        }

                        TextField("support.name", text: $viewModel.name)
                            .textContentType(.name)
                        TextField("settings.contact.subject", text: $viewModel.subject)
                        TextField("settings.contact.email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)

                        TextEditor(text: $viewModel.message)
                            .frame(minHeight: 180)
                            .overlay(alignment: .topLeading) {
                                if viewModel.message.isEmpty {
                                    Text("settings.contact.message")
                                        .foregroundStyle(.tertiary)
                                        .padding(.top, 8)
                                        .allowsHitTesting(false)
                                }
                            }
                    } footer: {
                        Text("settings.contact.api_privacy")
                    }

                    if case .failure(let error) = viewModel.state {
                        Section {
                            Label {
                                Text(error.localizedDescription)
                            } icon: {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    Section {
                        Button {
                            Task { await viewModel.submit() }
                        } label: {
                            HStack {
                                if viewModel.isSubmitting {
                                    ProgressView()
                                } else {
                                    Image(systemName: "paperplane")
                                }
                                Text(viewModel.isSubmitting ? "support.submitting" : "support.submit")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(!viewModel.canSubmit)
                    }
                }
            }
        }
        .navigationTitle("settings.contact")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environment(SupportPurchaseStore())
        .environment(AdConsentManager())
        .modelContainer(for: YohakuBlock.self, inMemory: true)
}
