import Foundation
@MainActor @Observable final class AdGate {
    private let minInterval: TimeInterval = 180
    private let lastKey = "ad_last_interstitial"
    private let sessKey = "ad_session_count"
    /// true nur ab 2. Session UND wenn >=180s seit letztem Interstitial.
    var canShowInterstitial: Bool {
        guard UserDefaults.standard.integer(forKey: sessKey) >= 2 else { return false }
        let last = UserDefaults.standard.double(forKey: lastKey)
        return Date().timeIntervalSince1970 - last >= minInterval
    }
    func recordInterstitial() { UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastKey) }
    static func bumpSession() {
        let d = UserDefaults.standard
        d.set(d.integer(forKey: "ad_session_count") + 1, forKey: "ad_session_count")
    }
}
