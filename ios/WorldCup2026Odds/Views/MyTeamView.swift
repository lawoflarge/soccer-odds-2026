import SwiftUI

struct MyTeamView: View {
    @EnvironmentObject var service: PredictionsService
    @EnvironmentObject var favorites: FavoriteStore

    private var allTeams: [String] {
        Set(service.matches.flatMap { [$0.teams.home, $0.teams.away] }).sorted()
    }

    private var teamMatches: [Match] {
        guard let t = favorites.favoriteTeam else { return [] }
        return service.matches
            .filter { $0.teams.home == t || $0.teams.away == t }
            .sorted { $0.kickoff < $1.kickoff }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favorites.favoriteTeam == nil {
                    teamPicker
                } else {
                    List {
                        Section {
                            ForEach(teamMatches) { m in
                                NavigationLink(value: m) { MatchRow(match: m) }
                            }
                        } header: {
                            HStack {
                                FlagView(team: favorites.favoriteTeam!)
                                Text(favorites.favoriteTeam!).font(.headline)
                                Spacer()
                                Button("Change") { favorites.favoriteTeam = nil }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Team")
            .navigationDestination(for: Match.self) { MatchDetailView(match: $0) }
        }
    }

    private var teamPicker: some View {
        List(allTeams, id: \.self) { team in
            Button { favorites.favoriteTeam = team } label: {
                HStack { FlagView(team: team); Text(team); Spacer() }
            }
        }
        .overlay {
            if allTeams.isEmpty {
                ContentUnavailableView("Pick your team", systemImage: "star",
                    description: Text("Teams appear here once predictions load."))
            }
        }
    }
}
