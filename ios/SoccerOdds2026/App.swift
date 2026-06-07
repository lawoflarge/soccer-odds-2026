import SwiftUI

@main
struct SoccerOdds2026App: App {
    @StateObject private var service = PredictionsService()
    @StateObject private var favorites = FavoriteStore()
    @State private var consent = ConsentManager()
    @State private var proStore = ProStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(service)
                .environmentObject(favorites)
                .environment(consent)
                .environment(proStore)
                .task { await consent.bootstrap() }
                .task { await proStore.refreshEntitlements() }
        }
    }
}
