import Foundation

struct PredictionsFile: Codable {
    let updated: String
    let count: Int
    let matches: [Match]
}

struct Match: Codable, Identifiable, Hashable {
    let id: String
    let teams: Teams
    let kickoff: String          // ISO 8601 UTC
    let probs1x2: Probs1x2
    let topScores: [ScoreProb]
    let goalMarkets: GoalMarkets
    // Optional Pro-fields — absent in legacy JSON, decoded as nil without error.
    let phase: String?
    let group: String?
    let xg: XG?
    let marketsExt: MarketsExt?
    let edge: Edge?

    enum CodingKeys: String, CodingKey {
        case id, teams, kickoff
        case probs1x2 = "probs_1x2"
        case topScores = "top_scores"
        case goalMarkets = "goal_markets"
        case phase, group, xg
        case marketsExt = "markets_ext"
        case edge
    }

    var kickoffDate: Date? { ISO8601DateFormatter().date(from: kickoff) }
}

struct Teams: Codable, Hashable {
    let home: String
    let away: String
}

struct Probs1x2: Codable, Hashable {
    let home: Double
    let draw: Double
    let away: Double
}

struct ScoreProb: Codable, Identifiable, Hashable {
    let score: String
    let pct: Double
    var id: String { score }
}

struct GoalMarkets: Codable, Hashable {
    let overUnder2_5: Double
    let btts: Double

    enum CodingKeys: String, CodingKey {
        case overUnder2_5 = "over_under_2_5"
        case btts
    }
}

struct XG: Codable, Hashable {
    let home: Double
    let away: Double
}

struct MarketsExt: Codable, Hashable {
    let over15: Double
    let over35: Double
    let correctScore: [ScoreProb]

    enum CodingKeys: String, CodingKey {
        case over15 = "over_1_5"
        case over35 = "over_3_5"
        case correctScore = "correct_score"
    }
}

struct Edge: Codable, Hashable {
    let side: String
    let valuePct: Double

    enum CodingKeys: String, CodingKey {
        case side
        case valuePct = "value_pct"
    }
}
