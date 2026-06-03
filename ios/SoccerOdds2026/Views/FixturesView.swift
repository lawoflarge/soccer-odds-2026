import SwiftUI

struct FixturesView: View {
    @EnvironmentObject var service: PredictionsService
    @EnvironmentObject var favorites: FavoriteStore
    @State private var filter: Filter = .all
    @State private var path: [Match] = []

    enum Filter: String, CaseIterable { case all = "All", today = "Today", myTeam = "My Team" }

    private var filtered: [Match] {
        service.matches.filter { m in
            switch filter {
            case .all: return true
            case .today:
                guard let d = m.kickoffDate else { return false }
                return Calendar.current.isDateInToday(d)
            case .myTeam:
                guard let t = favorites.favoriteTeam else { return false }
                return m.teams.home == t || m.teams.away == t
            }
        }
    }

    private var grouped: [(String, [Match])] {
        let fmt = DateFormatter(); fmt.dateFormat = "EEE, d MMM"
        let groups = Dictionary(grouping: filtered) { (m: Match) -> String in
            guard let d = m.kickoffDate else { return "TBD" }
            return fmt.string(from: d)
        }
        return groups.sorted { ($0.value.first?.kickoff ?? "") < ($1.value.first?.kickoff ?? "") }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if service.matches.isEmpty {
                    ContentUnavailableView(
                        "No predictions yet",
                        systemImage: "soccerball",
                        description: Text("Pull to refresh once the tournament odds are live.")
                    )
                } else {
                    List {
                        ForEach(grouped, id: \.0) { day, matches in
                            Section(day) {
                                ForEach(matches) { m in
                                    NavigationLink(value: m) { MatchRow(match: m) }
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: Theme.s1, leading: Theme.s4, bottom: Theme.s1, trailing: Theme.s4))
                                        .listRowBackground(Color.clear)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("World Cup 2026")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Filter", selection: $filter) {
                        ForEach(Filter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                }
            }
            .navigationDestination(for: Match.self) { MatchDetailView(match: $0) }
            .refreshable { await service.refresh() }
            .safeAreaInset(edge: .bottom) { AdBannerView().frame(height: 50) }
        }
        .task {
            await service.refresh()
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-openFirst"), let first = service.matches.first {
                path = [first]
            }
            #endif
        }
    }
}
