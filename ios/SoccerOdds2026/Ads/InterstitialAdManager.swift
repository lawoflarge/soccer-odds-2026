import SwiftUI
@preconcurrency import GoogleMobileAds

@MainActor enum RootVC {
    static func top() -> UIViewController? {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }.first { $0.isKeyWindow }?.rootViewController
    }
}
@MainActor @Observable
final class InterstitialAdManager: NSObject, FullScreenContentDelegate {
    static let testUnit = "ca-app-pub-3940256099942544/4411468910"     // Google test
    static let releaseUnit = Config.interstitialAdUnitID
    private var ad: InterstitialAd?
    private var onDismiss: (() -> Void)?
    var isReady: Bool { ad != nil }
    private var unitID: String {
        #if DEBUG
        return Self.testUnit
        #else
        return Self.releaseUnit
        #endif
    }
    func preload() {
        guard ad == nil else { return }
        Task { let loaded = try? await InterstitialAd.load(with: unitID, request: Request())
            self.ad = loaded; loaded?.fullScreenContentDelegate = self }
    }
    func present(onDismiss: @escaping () -> Void) {
        guard let ad, let vc = RootVC.top() else { onDismiss(); return }
        self.onDismiss = onDismiss; ad.present(from: vc)
    }
    private func finish() { ad = nil; preload(); let cb = onDismiss; onDismiss = nil; cb?() }
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) { Task { @MainActor in self.finish() } }
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) { Task { @MainActor in self.finish() } }
}
