# App Review Notes

Yohaku is an account-free, on-device app for setting aside unplanned time. No login is required.

Local notifications, when enabled, are scheduled shortly before a space begins. The app does not enter a timer or dedicated mode while a space is in progress. After a space ends, the next app open may show one small, non-modal check-in card on Today. It can be answered, closed, or swiped away and is never required or shown again for that space. Responses stay on device.

The system App Store review request is considered only after at least 3 launches, 5 created spaces, and 3 ended spaces, following a later successful creation. It is suppressed whenever the post-space check-in appeared in the same session and is requested at most once per app version. Apple retains final control over whether the sheet appears.

The free version shows an anchored AdMob banner on Today, Week, and Month. On first eligible launch, Google UMP gathers the applicable regional consent, then the app presents Apple’s App Tracking Transparency prompt if the status is not determined. Ads can still load without IDFA when ATT is denied. If consent information cannot be updated, the app fails closed and sends no ad request for that launch.

The non-consumable In-App Purchase `io.tmkch.yohaku.removeads` is available from the gear icon → the purchase card at the top of Settings. Its StoreKit-localized price is shown in the button. The purchase permanently removes ads. “Restore Purchase” is directly below it. Purchased users do not receive the ATT prompt and the ads SDK is not started after entitlement verification.

Privacy Policy, Terms of Use, Commercial Transactions disclosure, support, and—where required—ad privacy choices are available in Settings.

No review account or special hardware is required.
