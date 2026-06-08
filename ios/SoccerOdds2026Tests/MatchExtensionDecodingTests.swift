import XCTest
@testable import SoccerOdds2026

final class MatchExtensionDecodingTests: XCTestCase {

    private func fixtureData() throws -> Data {
        let url = Bundle(for: Self.self).url(forResource: "sample-predictions-ext", withExtension: "json")
        return try Data(contentsOf: XCTUnwrap(url))
    }

    // Match WITH all new optional fields — they must decode correctly.
    func testDecodesMatchWithExtendedFields() throws {
        let file = try JSONDecoder().decode(PredictionsFile.self, from: fixtureData())
        let m = try XCTUnwrap(file.matches.first)

        XCTAssertEqual(m.phase, "group")
        XCTAssertEqual(m.group, "C")

        let xg = try XCTUnwrap(m.xg)
        XCTAssertEqual(xg.home, 1.52, accuracy: 0.001)
        XCTAssertEqual(xg.away, 1.21, accuracy: 0.001)

        let ext = try XCTUnwrap(m.marketsExt)
        XCTAssertEqual(ext.over15, 79.4, accuracy: 0.01)
        XCTAssertEqual(ext.over35, 26.1, accuracy: 0.01)
        XCTAssertEqual(ext.correctScore.count, 10)
        XCTAssertEqual(ext.correctScore.first?.score, "1:0")

        let edge = try XCTUnwrap(m.edge)
        XCTAssertEqual(edge.side, "away")
        XCTAssertEqual(edge.valuePct, 4.2, accuracy: 0.01)
    }

    // Match WITHOUT new optional fields — must decode without throwing, all new fields nil.
    func testDecodesLegacyMatchWithoutExtendedFields() throws {
        let file = try JSONDecoder().decode(PredictionsFile.self, from: fixtureData())
        XCTAssertEqual(file.matches.count, 2)
        let legacy = file.matches[1]

        XCTAssertNil(legacy.phase)
        XCTAssertNil(legacy.group)
        XCTAssertNil(legacy.xg)
        XCTAssertNil(legacy.marketsExt)
        XCTAssertNil(legacy.edge)
    }

    // Existing fields on the extended match must still decode correctly.
    func testExistingFieldsStillDecodeOnExtendedMatch() throws {
        let file = try JSONDecoder().decode(PredictionsFile.self, from: fixtureData())
        let m = try XCTUnwrap(file.matches.first)
        XCTAssertEqual(m.id, "evt_ext_001")
        XCTAssertEqual(m.teams.home, "Brazil")
        XCTAssertEqual(m.probs1x2.home, 52.1, accuracy: 0.01)
        XCTAssertEqual(m.goalMarkets.overUnder2_5, 51.2, accuracy: 0.01)
    }
}
