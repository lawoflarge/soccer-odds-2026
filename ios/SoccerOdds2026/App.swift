import SwiftUI

@main
struct SoccerOdds2026App: App {
    @StateObject private var service = PredictionsService()
    @StateObject private var favorites = FavoriteStore()
    @State private var consent = ConsentManager()
    @State private var gate = AdGate()
    @State private var interstitial = InterstitialAdManager()
    @State private var proStore = ProStore()
    @State private var simService = SimulationService()
    @State private var trackService = TrackRecordService()
    @State private var oddsHistory = OddsHistoryService()

    var body: some Scene {
        WindowGroup {
            RootView()
                // Die Palette ist fest dunkel (Theme.depthBase #0f1419), die
                // Oberflaeche benutzt aber an 36 Stellen .primary und .secondary.
                // Ohne dieses Pinning stehen sie im hellen Systemmodus fast
                // schwarz auf fast schwarz.
                .preferredColorScheme(.dark)
                .environmentObject(service)
                .environmentObject(favorites)
                .environment(consent)
                .environment(gate)
                .environment(interstitial)
                .environment(proStore)
                .environment(simService)
                .environment(trackService)
                .environment(oddsHistory)
                .task {
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("-screenshotData") {
                        consent.bootstrapForScreenshots()
                        return
                    }
                    #endif
                    await consent.bootstrap()
                    AdGate.bumpSession()
                    if consent.canRequestAds && !proStore.isPro { interstitial.preload() }
                }
                .task { await proStore.refreshEntitlements() }
                .task { await simService.refresh() }
                .task { await trackService.refresh() }
                .task { await oddsHistory.refresh() }
        }
    }
}
