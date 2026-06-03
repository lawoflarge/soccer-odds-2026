import XCTest
@testable import SoccerOdds2026

@MainActor
final class PredictionsServiceTests: XCTestCase {
    private func fixtureData() throws -> Data {
        let url = Bundle(for: Self.self).url(forResource: "sample-predictions", withExtension: "json")!
        return try Data(contentsOf: url)
    }

    func testDecodeStaticHelperParsesMatches() throws {
        let file = try PredictionsService.decode(fixtureData())
        XCTAssertEqual(file.matches.count, 1)
        XCTAssertEqual(file.matches.first?.teams.away, "Poland")
    }

    func testApplyingDataPopulatesPublishedMatches() throws {
        let service = PredictionsService()
        try service.apply(fixtureData())
        XCTAssertEqual(service.matches.count, 1)
    }
}
