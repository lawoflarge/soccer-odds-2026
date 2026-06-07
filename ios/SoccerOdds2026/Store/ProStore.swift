// ios/SoccerOdds2026/Store/ProStore.swift
import StoreKit
import Observation

/// On-device Pro-unlock state driven by StoreKit 2.
/// Inject via .environment(proStore) in App.swift; read as @Environment(ProStore.self).
@MainActor
@Observable
final class ProStore {

    // MARK: - Public interface

    static let productID = "pro_unlock"

    /// True when the user has a verified non-consumable entitlement for pro_unlock.
    private(set) var isPro: Bool = false

    /// Loaded StoreKit products (populated by loadProducts()).
    var products: [Product] = []

    // MARK: - Private

    private nonisolated(unsafe) var updatesTask: Task<Void, Never>?

    // MARK: - Init / deinit

    init() {
        updatesTask = observeTransactions()
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Load products

    /// Fetches the pro_unlock Product from StoreKit (sandbox or production).
    func loadProducts() async {
        do {
            products = try await Product.products(for: [Self.productID])
        } catch {
            products = []
        }
    }

    // MARK: - Purchase

    /// Initiates purchase of pro_unlock. Throws on user cancellation or failure.
    /// On success sets isPro = true immediately.
    func purchase() async throws {
        if products.isEmpty { await loadProducts() }
        guard let product = products.first(where: { $0.id == Self.productID }) else {
            throw ProStoreError.productNotFound
        }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                isPro = true
            case .unverified:
                throw ProStoreError.verificationFailed
            }
        case .pending:
            break // Deferred — isPro stays false until transaction completes via updates listener.
        case .userCancelled:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Restore

    /// Forces an App Store sync and re-checks entitlements. Apple-required restore path.
    func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    // MARK: - Entitlement refresh

    /// Iterates currentEntitlements to derive isPro. Safe to call on cold start.
    func refreshEntitlements() async {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.productID == Self.productID {
                hasPro = true
            }
        }
        isPro = hasPro
    }

    // MARK: - Transaction observer

    /// Long-lived Task that processes Transaction.updates for the lifetime of ProStore.
    @discardableResult
    func observeTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { break }
                if case .verified(let tx) = result, tx.productID == Self.productID {
                    await tx.finish()
                    await MainActor.run { self.isPro = true }
                }
            }
        }
    }
}

// MARK: - Errors

enum ProStoreError: Error {
    case productNotFound
    case verificationFailed
}
