import XCTest
@testable import SoccerOdds2026

final class TrackRecordDecodingTests: XCTestCase {

    private func fixtureData() throws -> Data {
        let url = Bundle(for: Self.self).url(forResource: "sample-track-record", withExtension: "json")
        return try Data(contentsOf: XCTUnwrap(url))
    }

    func testDecodesTrackRecord() throws {
        let tr = try JSONDecoder().decode(TrackRecord.self, from: fixtureData())
        XCTAssertEqual(tr.updatedAt, "2026-06-15T06:00:00Z")
        XCTAssertEqual(tr.settledMatches, 8)
        XCTAssertEqual(tr.byMarket.count, 3)
    }

    func testDecodesMarketRecord() throws {
        let tr = try JSONDecoder().decode(TrackRecord.self, from: fixtureData())
        let rec = try XCTUnwrap(tr.byMarket["1x2"])
        XCTAssertEqual(rec.n, 8)
        XCTAssertEqual(rec.brier, 0.61, accuracy: 0.001)
        XCTAssertEqual(rec.hitRate, 0.625, accuracy: 0.001)
    }

    func testDecodesOver25Market() throws {
        let tr = try JSONDecoder().decode(TrackRecord.self, from: fixtureData())
        let rec = try XCTUnwrap(tr.byMarket["over_2_5"])
        XCTAssertEqual(rec.hitRate, 0.75, accuracy: 0.001)
    }
}
