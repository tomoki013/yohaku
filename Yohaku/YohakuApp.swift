import SwiftUI
import SwiftData

@main
struct YohakuApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var purchaseStore = SupportPurchaseStore()
    @State private var adConsentManager = AdConsentManager()

    private var isOnboardingPresented: Binding<Bool> {
        Binding(
            get: {
                !hasCompletedOnboarding && !ProcessInfo.processInfo.arguments.contains("-ScreenshotMode")
            },
            set: { isPresented in
                if !isPresented {
                    hasCompletedOnboarding = true
                }
            }
        )
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(purchaseStore)
                .environment(adConsentManager)
                .background(
                    AppearanceApplier(
                        mode: AppearanceMode(rawValue: appearanceMode) ?? .system
                    )
                )
                .task(id: "\(purchaseStore.entitlementCheckCompleted)-\(purchaseStore.hasRemovedAds)") {
                    await prepareAds()
                }
                // Consent that failed to resolve at launch leaves the session
                // with no ads at all. Returning to the foreground is the next
                // honest chance to ask again.
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task { await prepareAds() }
                }
                .fullScreenCover(isPresented: isOnboardingPresented) {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                }
        }
        .modelContainer(for: YohakuBlock.self)
    }

    private func prepareAds() async {
        await adConsentManager.prepareIfEligible(
            entitlementCheckCompleted: purchaseStore.entitlementCheckCompleted,
            hasRemovedAds: purchaseStore.hasRemovedAds
        )
    }
}
