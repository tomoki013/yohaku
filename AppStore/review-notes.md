# App Review Notes

Reply to Guideline 2.1 (Information Needed) — paste this into the Notes field of the App Review Information section in App Store Connect. Items 1 and 2 must be filled in by hand right before submission (they depend on the actual device/build used); everything else below is ready to paste as-is.

## 1. Screen recording

⚠️ TODO before submitting: record a screen capture on a physical device running the latest iOS, starting from launching the app, showing: Today → create a space (name, date, start/end time) → Week → Month → local notification permission prompt → Settings (Privacy Policy / Terms of Use / Commercial Transactions disclosure / support) → the purchase card and the ATT prompt on first eligible launch → completing the `io.tmkch.yohaku.removeads` purchase and seeing the banner ad disappear → Restore Purchase. Yohaku has no account registration, login, account deletion, or user-generated content shared with other users, so those flows do not need to appear. Upload the recording as an attachment in the same App Store Connect submission (Notes field only accepts text).

## 2. Devices and OS versions tested

⚠️ TODO before submitting: list the actual physical devices and iOS versions used for this build's QA pass, e.g.:
`Tested on iPhone <model>, iOS <version>; iPhone <model>, iOS <version>.`
See [qa-checklist.md](qa-checklist.md) for the checklist to run on each device before filling this in.

## 3. What the app does and who it's for

Yohaku is an account-free, on-device app for deliberately setting aside unplanned, unscheduled time ("ma"/"yohaku" — blank space) rather than filling every slot in a calendar. Users create a "space" with a name, date, start time, and end time (e.g. "just sit and drink tea"), then review their spaces on Today, Week, and Month views. The target audience is people who over-schedule themselves and want a simple, calm way to protect unstructured time — it solves the problem of calendars that only support adding commitments, never protecting the absence of them.

## 4. Setup and accessing main features

No account, login, or sample files are required. Install and launch the app; the Today screen is the entry point. Tap the "+" control to create a space (name, date, start time, end time — past times cannot be selected, default start time snaps to the next 15-minute mark). Swipe between Today, Week, and Month via the tab bar. No review account credentials are needed.

## 5. External services used

- Google Mobile Ads SDK (AdMob) — banner ads on Today, Week, and Month for free-tier users.
- Google User Messaging Platform (UMP) — regional (GDPR/consent) messaging gate before ad requests.
- Apple StoreKit 2 — the non-consumable in-app purchase and purchase restore.
- Apple App Tracking Transparency — requested only when ad consent applies and only for non-purchasing users.

No backend server, no analytics SDK beyond what ships inside Google Mobile Ads, no third-party auth, and no AI services. All space data is stored locally on-device only; there is no cloud sync.

## 6. Regional differences

The app's features and content are the same in every region. The only regional variation is consent handling: Google UMP gathers the applicable regional consent (e.g. GDPR in the EEA/UK) before any ad request, and the App Tracking Transparency prompt only appears where Apple requires it. Ads can still load without IDFA when ATT is denied or not applicable. No feature, screen, or content is hidden or added based on region.

## 7. Regulated industry / protected third-party material

Not applicable. Yohaku does not operate in a regulated industry (no health, finance, legal, or similar regulated content) and does not include any third-party protected material requiring authorization documentation.

## 8. In-App Purchase: what and where

The only in-app purchase is the non-consumable `io.tmkch.yohaku.removeads` ("Remove ads permanently"), a one-time purchase that permanently removes the banner ads shown to free-tier users. There is no subscription and no other purchasable item. To reach it: tap the gear icon (top-right) to open Settings, then use the purchase card at the top of the screen — its button shows the StoreKit-localized price. "Restore Purchase" is directly below it. After purchase (or restore), the ATT prompt and ad SDK are not started for that user.

## Additional context (background, not one of the 8 requested items)

Local notifications, when enabled, are scheduled shortly before a space begins. The app does not enter a timer or dedicated mode while a space is in progress. After a space ends, the next app open may show one small, non-modal check-in card on Today. It can be answered, closed, or swiped away and is never required or shown again for that space. Responses stay on device.

The system App Store review request is considered only after at least 3 launches, 5 created spaces, and 3 ended spaces, following a later successful creation. It is suppressed whenever the post-space check-in appeared in the same session and is requested at most once per app version. Apple retains final control over whether the sheet appears.

If consent information cannot be updated, the app fails closed and sends no ad request for that launch.

Privacy Policy, Terms of Use, Commercial Transactions disclosure, support, and—where required—ad privacy choices are available in Settings.

No review account or special hardware is required.
