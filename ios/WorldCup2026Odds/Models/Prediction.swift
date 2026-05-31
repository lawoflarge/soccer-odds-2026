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

    enum CodingKeys: String, CodingKey {
        case id, teams, kickoff
        case probs1x2 = "probs_1x2"
        case topScores = "top_scores"
        case goalMarkets = "goal_markets"
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
