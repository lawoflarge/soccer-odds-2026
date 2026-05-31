import Foundation

enum Config {
    /// Live feed (Plan 1). Public, CORS-enabled, refreshed every 6h.
    static let predictionsURL = URL(string: "https://world-cup-2026-odds.vercel.app/predictions.json")!

    /// AdMob unit IDs — real AdMob IDs (App "World Cup 2026 Odds" / Fixtures Banner).
    static let adMobAppID = "ca-app-pub-6563643868702361~1733904595"
    static let bannerAdUnitID = "ca-app-pub-6563643868702361/1494761678"
}
