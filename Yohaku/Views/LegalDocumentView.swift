import SwiftUI
import WebKit

/// The official website is canonical. A bundled localized copy remains
/// available when the website cannot be reached.
struct LegalDocumentView: View {
    let titleKey: LocalizedStringKey
    let bodyKey: LocalizedStringKey
    let url: URL

    @State private var availability: Availability = .checking

    private enum Availability {
        case checking
        case online
        case offline
    }

    private static let webLanguages: Set<String> = ["en", "ja"]

    private var appLanguage: String {
        String((Bundle.main.preferredLocalizations.first ?? "en").prefix(2)).lowercased()
    }

    private var webLanguage: String {
        Self.webLanguages.contains(appLanguage) ? appLanguage : "en"
    }

    private var didFallBackToEnglish: Bool {
        webLanguage != appLanguage
    }

    private var localizedURL: URL {
        guard webLanguage != "en",
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              !components.path.hasPrefix("/\(webLanguage)/") else {
            return url
        }
        components.path = "/\(webLanguage)" + components.path
        return components.url ?? url
    }

    var body: some View {
        Group {
            switch availability {
            case .checking:
                VStack(spacing: 14) {
                    ProgressView()
                    Text("legal.checking")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            case .online:
                VStack(spacing: 0) {
                    if didFallBackToEnglish {
                        Label("legal.english_fallback", systemImage: "globe")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(.regularMaterial)
                    }
                    LegalWebView(url: localizedURL, language: webLanguage)
                }
            case .offline:
                OfflineLegalDocument(titleKey: titleKey, bodyKey: bodyKey)
            }
        }
        .navigationTitle(titleKey)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await checkAvailability()
        }
    }

    private func checkAvailability() async {
        var request = URLRequest(url: localizedURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        request.setValue(webLanguage, forHTTPHeaderField: "Accept-Language")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let response = response as? HTTPURLResponse,
               (200..<400).contains(response.statusCode) {
                availability = .online
            } else {
                availability = .offline
            }
        } catch {
            availability = .offline
        }
    }
}

private struct LegalWebView: UIViewRepresentable {
    let url: URL
    let language: String

    private static let hideSiteChrome = """
    var style = document.createElement('style');
    style.textContent = `
      .app-site-header,
      .app-site-footer,
      .mock-header,
      .mock-footer {
        display: none !important;
      }
      .content-page {
        min-height: 0 !important;
        padding-top: 24px !important;
        padding-bottom: 40px !important;
      }
    `;
    document.documentElement.appendChild(style);
    """

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(
            WKUserScript(
                source: Self.hideSiteChrome,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )
        let webView = WKWebView(frame: .zero, configuration: configuration)
        var request = URLRequest(url: url)
        request.setValue(language, forHTTPHeaderField: "Accept-Language")
        webView.load(request)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}

private struct OfflineLegalDocument: View {
    let titleKey: LocalizedStringKey
    let bodyKey: LocalizedStringKey

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Label("legal.offline", systemImage: "wifi.slash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

                Text(titleKey)
                    .font(.title2)
                    .fontWeight(.medium)

                HStack(spacing: 20) {
                    legalDate("legal.enacted", AppInfo.legalEnactedDate)
                    legalDate("legal.updated", AppInfo.legalLastUpdatedDate)
                }

                Text(bodyKey)
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.85))
                    .lineSpacing(8)
                    .textSelection(.enabled)

                Link(destination: AppInfo.officialSiteURL) {
                    Label("legal.retry_online", systemImage: "arrow.clockwise")
                        .font(.footnote.weight(.medium))
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemBackground))
    }

    private func legalDate(_ label: LocalizedStringKey, _ date: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(date, format: .dateTime.year().month().day())
                .font(.caption)
        }
    }
}
