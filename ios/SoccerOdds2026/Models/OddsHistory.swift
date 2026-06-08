import Foundation

/// Keyed by match ID; each value is a chronologically ordered array of daily snapshots.
typealias OddsHistory = [String: [OddsSnapshot]]

struct OddsSnapshot: Codable, Hashable {
    let t: String      // "YYYY-MM-DD"
    let home: Double
    let draw: Double
    let away: Double
}
