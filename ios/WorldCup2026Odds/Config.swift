import Foundation

enum Config {
    /// Live feed (Plan 1). Public, CORS-enabled, refreshed every 6h.
    static let predictionsURL = URL(string: "https://world-cup-2026-odds.vercel.app/predictions.json")!

    /// AdMob unit IDs — Google's official TEST IDs. Replace with real IDs before release.
    static let adMobAppID = "ca-app-pub-3940256099942544~1458002511"
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
}
