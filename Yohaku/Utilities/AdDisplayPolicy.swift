import Foundation

/// The deliberately strict conditions under which Yohaku may reserve space for
/// an ad. Keeping this separate makes the no-ad states easy to test.
struct AdDisplayState {
    let entitlementCheckCompleted: Bool
    let hasRemovedAds: Bool
    let consentCheckCompleted: Bool
    let canRequestAds: Bool
    let mobileAdsInitialized: Bool
    let isHomeScreen: Bool
    let isKeyboardVisible: Bool
    let isModalPresented: Bool
    let bannerLoadFailed: Bool
}

enum AdDisplayPolicy {
    static func shouldShowBanner(for state: AdDisplayState) -> Bool {
        state.entitlementCheckCompleted &&
            !state.hasRemovedAds &&
            state.consentCheckCompleted &&
            state.canRequestAds &&
            state.mobileAdsInitialized &&
            state.isHomeScreen &&
            !state.isKeyboardVisible &&
            !state.isModalPresented &&
            !state.bannerLoadFailed
    }
}
