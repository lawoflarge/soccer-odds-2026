import SwiftUI
import GoogleMobileAds
import UIKit

/// Adaptive AdMob banner. Test unit in Debug; the real release unit comes from Config.
struct AdBannerView: UIViewRepresentable {
    static let testBannerUnit = "ca-app-pub-3940256099942544/2934735716"

    func makeUIView(context: Context) -> BannerView {
        #if DEBUG
        let unit = Self.testBannerUnit
        #else
        let unit = Config.bannerAdUnitID
        #endif
        let width = UIScreen.main.bounds.width
        let banner = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(width: width))
        banner.adUnitID = unit
        banner.rootViewController = ConsentManager.topViewController()
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
