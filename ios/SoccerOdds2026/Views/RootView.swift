import SwiftUI

struct RootView: View {
    @State private var selection = RootView.initialTab()

    var body: some View {
        TabView(selection: $selection) {
            FixturesView().tabItem { Label("Fixtures", systemImage: "list.bullet") }.tag(0)
            MyTeamView().tabItem { Label("My Team", systemImage: "star.fill") }.tag(1)
            AboutView().tabItem { Label("About", systemImage: "info.circle") }.tag(2)
        }
    }

    private static func initialTab() -> Int {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-tab"), i + 1 < args.count, let t = Int(args[i + 1]) { return t }
        #endif
        return 0
    }
}
