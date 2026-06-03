import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    Text("World Cup 2026 Odds shows the betting-market consensus for each match of the 2026 World Cup, to help you make informed predictions.")
                }
                Section("Important") {
                    Text("This app offers no real-money gaming and accepts no bets. All information is for entertainment and informational purposes only.")
                    Text("Unofficial. Not affiliated with, endorsed by, or connected to FIFA.")
                }
                Section("Play responsibly") {
                    Link("BeGambleAware.org", destination: URL(string: "https://www.begambleaware.org")!)
                    Link("ncpgambling.org (US)", destination: URL(string: "https://www.ncpgambling.org")!)
                }
                Section("Data") {
                    Text("Predictions are derived from aggregated bookmaker odds and a statistical goal model. Accuracy reflects the market and is not guaranteed.")
                }
            }
            .navigationTitle("About")
        }
    }
}
