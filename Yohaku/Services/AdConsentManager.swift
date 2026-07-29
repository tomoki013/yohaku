import Foundation
import GoogleMobileAds
import Observation
import UIKit
import UserMessagingPlatform

enum AdConfiguration {
    static var bannerUnitID: String {
        Bundle.main.object(forInfoDictionaryKey: "AdMobBannerAdUnitID") as? String ?? ""
    }
}

/// Owns the whole ad lifecycle. No ad SDK call occurs until StoreKit has
/// finished checking the entitlement and UMP says requesting ads is allowed.
@MainActor
@Observable
final class AdConsentManager {
    private(set) var consentCheckCompleted = false
    private(set) var canRequestAds = false
    private(set) var mobileAdsInitialized = false
    private(set) var privacyOptionsRequired = false

    private var hasStarted = false

    var isReadyForAds: Bool {
        consentCheckCompleted && canRequestAds && mobileAdsInitialized
    }

    func prepareIfEligible(
        entitlementCheckCompleted: Bool,
        hasRemovedAds: Bool
    ) async {
        guard entitlementCheckCompleted, !hasRemovedAds, !hasStarted else { return }
        hasStarted = true

        let parameters = RequestParameters()
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
            if let controller = await Self.presentingViewController() {
                try? await ConsentForm.loadAndPresentIfRequired(from: controller)
            }
        } catch {
            // A failed consent update must fail closed: no SDK initialization or
            // ad request is allowed for this launch.
            consentCheckCompleted = true
            canRequestAds = false
            privacyOptionsRequired = false
            return
        }

        consentCheckCompleted = true
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        guard ConsentInformation.shared.canRequestAds else { return }

        canRequestAds = true
        _ = await MobileAds.shared.start()
        mobileAdsInitialized = true
    }

    func presentPrivacyOptions() async {
        guard privacyOptionsRequired,
              let controller = await Self.presentingViewController() else { return }

        try? await ConsentForm.presentPrivacyOptionsForm(from: controller)
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        canRequestAds = ConsentInformation.shared.canRequestAds
    }

    private static func presentingViewController() async -> UIViewController? {
        for _ in 0..<20 {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
            var controller = scene?.keyWindow?.rootViewController
            while let presented = controller?.presentedViewController {
                controller = presented
            }
            if let controller { return controller }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return nil
    }
}
