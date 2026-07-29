import SwiftUI
import SwiftData

@main
struct YohakuApp: App {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @State private var purchaseStore = SupportPurchaseStore()
    @State private var adConsentManager = AdConsentManager()

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
                    await adConsentManager.prepareIfEligible(
                        entitlementCheckCompleted: purchaseStore.entitlementCheckCompleted,
                        hasRemovedAds: purchaseStore.hasRemovedAds
                    )
                }
        }
        .modelContainer(for: YohakuBlock.self)
    }
}
