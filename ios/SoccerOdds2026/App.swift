import SwiftUI
import AppTrackingTransparency
import GoogleMobileAds

@main
struct SoccerOdds2026App: App {
    @StateObject private var service = PredictionsService()
    @StateObject private var favorites = FavoriteStore()

    init() { GADMobileAds.sharedInstance().start(completionHandler: nil) }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(service)
                .environmentObject(favorites)
                .task { await requestTrackingIfNeeded() }
        }
    }

    private func requestTrackingIfNeeded() async {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-skipATT") { return }
        #endif
        try? await Task.sleep(for: .seconds(1))
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
    }
}
