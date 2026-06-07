import Foundation

enum Config {
    /// Live feed (Plan 1). Public, CORS-enabled, refreshed every 6h.
    static let predictionsURL = URL(string: "https://soccer-odds-2026.vercel.app/predictions.json")!
    static let simulationURL = URL(string: "https://soccer-odds-2026.vercel.app/simulation.json")!
    static let trackRecordURL = URL(string: "https://soccer-odds-2026.vercel.app/track_record.json")!
    static let oddsHistoryURL = URL(string: "https://soccer-odds-2026.vercel.app/odds_history.json")!

    /// AdMob unit IDs — real AdMob IDs (App "Soccer Odds 2026" / Fixtures Banner).
    static let adMobAppID = "ca-app-pub-6563643868702361~1733904595"
    static let bannerAdUnitID = "ca-app-pub-6563643868702361/1494761678"
}
