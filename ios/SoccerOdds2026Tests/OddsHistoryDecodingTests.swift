import XCTest
@testable import SoccerOdds2026

final class OddsHistoryDecodingTests: XCTestCase {

    private func fixtureData() throws -> Data {
        let url = Bundle(for: Self.self).url(forResource: "sample-odds-history", withExtension: "json")
        return try Data(contentsOf: XCTUnwrap(url))
    }

    func testDecodesOddsHistory() throws {
        let history = try JSONDecoder().decode(OddsHistory.self, from: fixtureData())
        XCTAssertEqual(history.keys.count, 2)
        let series = try XCTUnwrap(history["evt_demo_001"])
        XCTAssertEqual(series.count, 3)
    }

    func testDecodesOddsSnapshot() throws {
        let history = try JSONDecoder().decode(OddsHistory.self, from: fixtureData())
        let snap = try XCTUnwrap(history["evt_demo_001"]?.first)
        XCTAssertEqual(snap.t, "2026-06-11")
        XCTAssertEqual(snap.home, 44.0, accuracy: 0.01)
        XCTAssertEqual(snap.draw, 28.0, accuracy: 0.01)
        XCTAssertEqual(snap.away, 28.0, accuracy: 0.01)
    }

    func testSnapshotsAreChronologicallyOrdered() throws {
        // Series in fixture is already ascending by date; test that the dates differ.
        let history = try JSONDecoder().decode(OddsHistory.self, from: fixtureData())
        let series = try XCTUnwrap(history["evt_demo_001"])
        let dates = series.map(\.t)
        XCTAssertEqual(dates, dates.sorted())
    }
}
