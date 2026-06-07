import Foundation

struct TrackRecord: Codable {
    let updatedAt: String
    let settledMatches: Int
    let byMarket: [String: MarketRecord]

    enum CodingKeys: String, CodingKey {
        case updatedAt = "updated_at"
        case settledMatches = "settled_matches"
        case byMarket = "by_market"
    }
}

struct MarketRecord: Codable, Hashable {
    let n: Int
    let brier: Double
    let hitRate: Double

    enum CodingKeys: String, CodingKey {
        case n, brier
        case hitRate = "hit_rate"
    }
}
