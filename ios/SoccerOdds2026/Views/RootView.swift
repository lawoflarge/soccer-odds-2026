// ios/SoccerOdds2026/Views/RootView.swift
import SwiftUI

struct RootView: View {
    @State private var selection = RootView.initialTab()
    @State private var tabScale: [CGFloat] = [1, 1, 1, 1]

    var body: some View {
        TabView(selection: $selection) {
            FixturesView()
                .tabItem { Label("Fixtures", systemImage: "soccerball") }
                .tag(0)

            TournamentView()
                .tabItem { Label("Tournament", systemImage: "trophy.fill") }
                .tag(1)

            MyTeamView()
                .tabItem { Label("My Team", systemImage: "star.fill") }
                .tag(2)

            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
                .tag(3)
        }
        // Spring-Tap-Feedback beim Tab-Wechsel
        .onChange(of: selection) { old, new in
            withAnimation(.spring(duration: 0.25, bounce: 0.5)) {
                tabScale[new] = 1.15
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(duration: 0.2)) { tabScale[new] = 1.0 }
            }
        }
    }

    private static func initialTab() -> Int {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-tab"), i + 1 < args.count,
           let t = Int(args[i + 1]) { return t }
        #endif
        return 0
    }
}
