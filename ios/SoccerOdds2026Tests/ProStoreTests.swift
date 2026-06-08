// ios/SoccerOdds2026Tests/ProStoreTests.swift
import XCTest
import StoreKitTest
@testable import SoccerOdds2026

@MainActor
final class ProStoreTests: XCTestCase {

    var session: SKTestSession!

    override func setUp() async throws {
        try await super.setUp()
        session = try SKTestSession(configurationFileNamed: "SoccerOdds2026")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
    }

    override func tearDown() async throws {
        session.clearTransactions()
        try await super.tearDown()
    }

    // MARK: - Initial state

    func testInitialStateIsNotPro() async throws {
        let store = ProStore()
        await store.refreshEntitlements()
        XCTAssertFalse(store.isPro, "Fresh store must not be Pro before any purchase")
    }

    // MARK: - Purchase sets isPro

    func testPurchaseSetsIsPro() async throws {
        let store = ProStore()
        await store.loadProducts()
        XCTAssertFalse(store.products.isEmpty, "products must not be empty after loadProducts")

        try await store.purchase()
        XCTAssertTrue(store.isPro, "isPro must be true after successful purchase")
    }

    // MARK: - Restore works

    func testRestoreAfterPurchase() async throws {
        // Simulate a prior purchase via SKTestSession, then restore.
        try await session.buyProduct(productIdentifier: ProStore.productID)

        let store = ProStore()
        try await store.restore()
        XCTAssertTrue(store.isPro, "isPro must be true after restore when entitlement exists")
    }

    // MARK: - refreshEntitlements reflects existing entitlement

    func testRefreshEntitlementsPicksUpExistingEntitlement() async throws {
        try await session.buyProduct(productIdentifier: ProStore.productID)

        let store = ProStore()
        await store.refreshEntitlements()
        XCTAssertTrue(store.isPro, "refreshEntitlements must set isPro when currentEntitlements contains pro_unlock")
    }
}
