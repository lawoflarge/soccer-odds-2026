import Foundation

struct TournamentSimulation: Codable {
    let generatedAt: String
    let iterations: Int
    let teams: [TeamSim]
    let groups: [String: [GroupSim]]

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case iterations, teams, groups
    }
}

struct TeamSim: Codable, Identifiable, Hashable {
    let team: String
    let win: Double
    let reach: [String: Double]

    var id: String { team }
}

struct GroupSim: Codable, Hashable {
    let team: String
    let advance: Double
    let winGroup: Double

    enum CodingKeys: String, CodingKey {
        case team, advance
        case winGroup = "win_group"
    }
}
