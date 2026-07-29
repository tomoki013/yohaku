import XCTest
@testable import Yohaku

final class AdDisplayPolicyTests: XCTestCase {
    func testShowsOnlyWhenEveryConditionIsSatisfied() {
        XCTAssertTrue(shouldShow())
    }

    func testDoesNotShowBeforeEntitlementCheckCompletes() {
        XCTAssertFalse(shouldShow(entitlementCheckCompleted: false))
    }

    func testDoesNotShowAfterCoffeePurchase() {
        XCTAssertFalse(shouldShow(hasRemovedAds: true))
    }

    func testDoesNotShowBeforeConsentCheckCompletes() {
        XCTAssertFalse(shouldShow(consentCheckCompleted: false))
    }

    func testDoesNotShowWhenConsentDisallowsAdRequests() {
        XCTAssertFalse(shouldShow(canRequestAds: false))
    }

    func testDoesNotShowBeforeMobileAdsStarts() {
        XCTAssertFalse(shouldShow(mobileAdsInitialized: false))
    }

    func testDoesNotShowOnAnIneligibleScreen() {
        XCTAssertFalse(shouldShow(isScreenEligible: false))
    }

    func testDoesNotShowWhileKeyboardIsVisible() {
        XCTAssertFalse(shouldShow(isKeyboardVisible: true))
    }

    func testDoesNotShowWhileAModalIsPresented() {
        XCTAssertFalse(shouldShow(isModalPresented: true))
    }

    func testDoesNotShowAfterBannerLoadFailure() {
        XCTAssertFalse(shouldShow(bannerLoadFailed: true))
    }

    private func shouldShow(
        entitlementCheckCompleted: Bool = true,
        hasRemovedAds: Bool = false,
        consentCheckCompleted: Bool = true,
        canRequestAds: Bool = true,
        mobileAdsInitialized: Bool = true,
        isScreenEligible: Bool = true,
        isKeyboardVisible: Bool = false,
        isModalPresented: Bool = false,
        bannerLoadFailed: Bool = false
    ) -> Bool {
        AdDisplayPolicy.shouldShowBanner(for: .init(
            entitlementCheckCompleted: entitlementCheckCompleted,
            hasRemovedAds: hasRemovedAds,
            consentCheckCompleted: consentCheckCompleted,
            canRequestAds: canRequestAds,
            mobileAdsInitialized: mobileAdsInitialized,
            isScreenEligible: isScreenEligible,
            isKeyboardVisible: isKeyboardVisible,
            isModalPresented: isModalPresented,
            bannerLoadFailed: bannerLoadFailed
        ))
    }
}
