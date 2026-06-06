import Foundation
import GoogleMobileAds
import UserMessagingPlatform
import AppTrackingTransparency
import UIKit

/// Drives the EEA consent + ATT flow, then starts the Mobile Ads SDK.
/// Order: UMP consent form (GDPR) → ATT prompt → start ads when consent allows.
@MainActor
@Observable
final class ConsentManager {
    private(set) var canRequestAds = false
    private var started = false

    func bootstrap() async {
        let params = RequestParameters()
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            ConsentInformation.shared.requestConsentInfoUpdate(with: params) { _ in
                cont.resume()
            }
        }

        if let root = Self.topViewController() {
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                ConsentForm.loadAndPresentIfRequired(from: root) { _ in cont.resume() }
            }
        }

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            ATTrackingManager.requestTrackingAuthorization { _ in cont.resume() }
        }

        if ConsentInformation.shared.canRequestAds {
            startAdsIfNeeded()
        }
    }

    func startAdsIfNeeded() {
        guard !started else { return }
        started = true
        MobileAds.shared.start(completionHandler: { _ in })
        canRequestAds = true
    }

    static func topViewController() -> UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .rootViewController
        var top = root
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
