import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    Text("Soccer Odds 2026 shows the betting-market consensus for each match of the 2026 tournament, to help you make informed predictions.")
                }
                Section("Important") {
                    Text("This app offers no real-money gaming and accepts no bets. All information is for entertainment and informational purposes only.")
                    Text("Independent app. Not affiliated with, endorsed by, or connected to any football organisation or governing body.")
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
