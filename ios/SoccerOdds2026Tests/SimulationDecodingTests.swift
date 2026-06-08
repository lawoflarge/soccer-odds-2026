import XCTest
@testable import SoccerOdds2026

final class SimulationDecodingTests: XCTestCase {

    private func fixtureData() throws -> Data {
        let url = Bundle(for: Self.self).url(forResource: "sample-simulation", withExtension: "json")
        return try Data(contentsOf: XCTUnwrap(url))
    }

    func testDecodesTournamentSimulation() throws {
        let sim = try JSONDecoder().decode(TournamentSimulation.self, from: fixtureData())
        XCTAssertEqual(sim.generatedAt, "2026-06-15T06:00:00Z")
        XCTAssertEqual(sim.iterations, 10000)
        XCTAssertEqual(sim.teams.count, 2)
    }

    func testDecodesTeamSim() throws {
        let sim = try JSONDecoder().decode(TournamentSimulation.self, from: fixtureData())
        let brazil = try XCTUnwrap(sim.teams.first(where: { $0.team == "Brazil" }))
        XCTAssertEqual(brazil.win, 18.4, accuracy: 0.01)
        XCTAssertEqual(brazil.id, "Brazil")
        let r16 = try XCTUnwrap(brazil.reach["r16"])
        XCTAssertEqual(r16, 99.1, accuracy: 0.01)
    }

    func testDecodesGroupSim() throws {
        let sim = try JSONDecoder().decode(TournamentSimulation.self, from: fixtureData())
        let groupC = try XCTUnwrap(sim.groups["C"])
        XCTAssertEqual(groupC.count, 2)
        let brazil = try XCTUnwrap(groupC.first(where: { $0.team == "Brazil" }))
        XCTAssertEqual(brazil.advance, 94.0, accuracy: 0.01)
        XCTAssertEqual(brazil.winGroup, 61.0, accuracy: 0.01)
    }
}
