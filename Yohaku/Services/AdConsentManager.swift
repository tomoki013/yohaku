import Foundation
import AppTrackingTransparency
import GoogleMobileAds
import Observation
import OSLog
import UIKit
import UserMessagingPlatform

enum AdConfiguration {
    static var bannerUnitID: String {
        Bundle.main.object(forInfoDictionaryKey: "AdMobBannerAdUnitID") as? String ?? ""
    }

    static var applicationID: String {
        Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String ?? ""
    }

    /// Ad problems only ever reproduce in a distribution build against the live
    /// unit, where `print` goes nowhere. Everything the ad path decides is
    /// logged here so a TestFlight run can be read back in Console.app.
    static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "io.tmkch.yohaku", category: "Ads")
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

    /// The last reason ads are not on screen, in the operator's words. Shown in
    /// Settings on TestFlight builds only — see `AppInfo.isTestFlightBuild`.
    private(set) var consentFailure: String?
    private(set) var bannerFailure: String?

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

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ScreenshotMode") {
            consentCheckCompleted = true
            return
        }
        #endif

        AdConfiguration.log.notice(
            "Preparing ads. appID=\(AdConfiguration.applicationID, privacy: .public) unit=\(AdConfiguration.bannerUnitID, privacy: .public)"
        )

        let parameters = RequestParameters()
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
            if let controller = await Self.presentingViewController() {
                do {
                    try await ConsentForm.loadAndPresentIfRequired(from: controller)
                } catch {
                    // A form that will not load is not by itself a reason to
                    // withhold ads: `canRequestAds` below still decides.
                    AdConfiguration.log.error("Consent form failed: \(error.localizedDescription, privacy: .public)")
                }
            }
        } catch {
            // A failed consent update must fail closed: no SDK initialization or
            // ad request is allowed while consent is unknown. It must not be
            // permanent though — a dropped request at launch would otherwise
            // cost every ad for the whole session, so allow the next foreground
            // to try again.
            AdConfiguration.log.error("Consent update failed: \(error.localizedDescription, privacy: .public)")
            consentFailure = error.localizedDescription
            consentCheckCompleted = true
            canRequestAds = false
            privacyOptionsRequired = false
            hasStarted = false
            return
        }

        consentFailure = nil

        // UMP presents the configured IDFA explainer before ATT. If no UMP
        // message applies in this region, still make the system ATT choice
        // explicit before the ads SDK can access the advertising identifier.
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }

        consentCheckCompleted = true
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        guard ConsentInformation.shared.canRequestAds else {
            AdConfiguration.log.notice("Consent resolved but ads may not be requested.")
            consentFailure = "canRequestAds == false"
            return
        }

        canRequestAds = true
        _ = await MobileAds.shared.start()
        mobileAdsInitialized = true
        AdConfiguration.log.notice("Mobile Ads started.")
    }

    /// Recorded so a no-fill or a misconfigured unit is distinguishable after
    /// the fact. The banner itself only knows to collapse and retry.
    func recordBannerFailure(_ error: Error) {
        bannerFailure = error.localizedDescription
        AdConfiguration.log.error("Banner failed: \(error.localizedDescription, privacy: .public)")
    }

    func recordBannerLoaded() {
        bannerFailure = nil
        AdConfiguration.log.notice("Banner loaded.")
    }

    /// A developer-facing readout of why the banner is or is not on screen.
    /// Surfaced in Settings on TestFlight builds only: the live ad unit only
    /// ever misbehaves in a distribution build, where there is no debugger.
    var diagnosticSummary: String {
        var lines = [
            "appID: \(AdConfiguration.applicationID)",
            "unit: \(AdConfiguration.bannerUnitID)",
            "consentCheckCompleted: \(consentCheckCompleted)",
            "canRequestAds: \(canRequestAds)",
            "mobileAdsInitialized: \(mobileAdsInitialized)",
            "privacyOptionsRequired: \(privacyOptionsRequired)"
        ]
        if let consentFailure {
            lines.append("consent error: \(consentFailure)")
        }
        if let bannerFailure {
            lines.append("banner error: \(bannerFailure)")
        }
        return lines.joined(separator: "\n")
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
