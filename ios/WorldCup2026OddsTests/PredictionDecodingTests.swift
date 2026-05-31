import XCTest
@testable import WorldCup2026Odds

final class PredictionDecodingTests: XCTestCase {
    private func fixtureData() throws -> Data {
        let url = Bundle(for: Self.self).url(forResource: "sample-predictions", withExtension: "json")
        return try Data(contentsOf: XCTUnwrap(url))
    }

    func testDecodesPredictionsFile() throws {
        let file = try JSONDecoder().decode(PredictionsFile.self, from: fixtureData())
        XCTAssertEqual(file.count, 1)
        let m = try XCTUnwrap(file.matches.first)
        XCTAssertEqual(m.id, "evt_demo_001")
        XCTAssertEqual(m.teams.home, "Mexico")
        XCTAssertEqual(m.probs1x2.home, 48.3, accuracy: 0.01)
        XCTAssertEqual(m.topScores.first?.score, "1:1")
        XCTAssertEqual(m.goalMarkets.overUnder2_5, 47.4, accuracy: 0.01)
        XCTAssertEqual(m.goalMarkets.btts, 51.4, accuracy: 0.01)
    }

    func testKickoffParsesToDate() throws {
        let file = try JSONDecoder().decode(PredictionsFile.self, from: fixtureData())
        let m = try XCTUnwrap(file.matches.first)
        XCTAssertNotNil(m.kickoffDate)
    }
}
