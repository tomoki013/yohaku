import GoogleMobileAds
import SwiftUI

/// A bottom-anchored banner for the home screen only. It reserves the adaptive
/// size while loading, then collapses entirely if the request fails.
struct AdaptiveBannerAd: View {
    let unitID: String
    let onFailure: () -> Void

    @State private var loadState: LoadState = .loading
    @State private var availableWidth: CGFloat = UIScreen.main.bounds.width

    private enum LoadState {
        case loading
        case loaded
        case failed
    }

    var body: some View {
        Group {
            if isRunningInPreview || loadState == .failed || availableWidth <= 0 {
                EmptyView()
            } else {
                let adSize = largeAnchoredAdaptiveBanner(width: availableWidth)
                AdaptiveBannerView(
                    unitID: unitID,
                    adSize: adSize,
                    onLoaded: { loadState = .loaded },
                    onFailed: {
                        #if DEBUG
                        print("Yohaku banner ad failed to load")
                        #endif
                        loadState = .failed
                        onFailure()
                    }
                )
                .frame(width: adSize.size.width, height: adSize.size.height)
                .frame(maxWidth: .infinity)
                .frame(height: adSize.size.height)
            }
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { availableWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, newValue in availableWidth = newValue }
            }
        }
    }

    private var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

private struct AdaptiveBannerView: UIViewRepresentable {
    let unitID: String
    let adSize: AdSize
    let onLoaded: () -> Void
    let onFailed: () -> Void

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = unitID
        banner.delegate = context.coordinator
        context.coordinator.load(banner: banner, size: adSize)
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        context.coordinator.load(banner: banner, size: adSize)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onLoaded: onLoaded, onFailed: onFailed)
    }

    @MainActor
    final class Coordinator: NSObject, BannerViewDelegate {
        private let onLoaded: () -> Void
        private let onFailed: () -> Void
        private var requestedSize: CGSize?

        init(onLoaded: @escaping () -> Void, onFailed: @escaping () -> Void) {
            self.onLoaded = onLoaded
            self.onFailed = onFailed
        }

        func load(banner: BannerView, size: AdSize) {
            let nextSize = size.size
            guard requestedSize != nextSize else { return }
            requestedSize = nextSize
            banner.adSize = size
            banner.load(Request())
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            onLoaded()
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            #if DEBUG
            print("Yohaku banner error: \(error.localizedDescription)")
            #endif
            onFailed()
        }

        func bannerViewDidRecordClick(_ bannerView: BannerView) {
            #if DEBUG
            print("Yohaku banner clicked")
            #endif
        }

        func bannerViewWillPresentScreen(_ bannerView: BannerView) {
            #if DEBUG
            print("Yohaku banner will present")
            #endif
        }

        func bannerViewDidDismissScreen(_ bannerView: BannerView) {
            #if DEBUG
            print("Yohaku banner dismissed")
            #endif
        }
    }
}
