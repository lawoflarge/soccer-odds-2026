import SwiftUI

@main
struct SoccerOdds2026App: App {
    @StateObject private var service = PredictionsService()
    @StateObject private var favorites = FavoriteStore()
    @State private var consent = ConsentManager()
    @State private var proStore = ProStore()
    @State private var simService = SimulationService()
    @State private var trackService = TrackRecordService()
    @State private var oddsHistory = OddsHistoryService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(service)
                .environmentObject(favorites)
                .environment(consent)
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
                }
                .task { await proStore.refreshEntitlements() }
                .task { await simService.refresh() }
                .task { await trackService.refresh() }
                .task { await oddsHistory.refresh() }
        }
    }
}
