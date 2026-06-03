import XCTest
@testable import SoccerOdds2026

final class FavoriteStoreTests: XCTestCase {
    func testPersistsFavoriteAcrossInstances() {
        let defaults = UserDefaults(suiteName: "test.favorite")!
        defaults.removePersistentDomain(forName: "test.favorite")

        let store = FavoriteStore(defaults: defaults)
        store.favoriteTeam = "Brazil"

        let reloaded = FavoriteStore(defaults: defaults)
        XCTAssertEqual(reloaded.favoriteTeam, "Brazil")
    }
}
