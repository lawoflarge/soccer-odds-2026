import SwiftUI

@main
struct SoccerOdds2026App: App {
    @StateObject private var service = PredictionsService()
    @StateObject private var favorites = FavoriteStore()
    @State private var consent = ConsentManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(service)
                .environmentObject(favorites)
                .environment(consent)
                .task { await consent.bootstrap() }
        }
    }
}
