// ios/SoccerOdds2026/Views/MyTeamView.swift
import SwiftUI

struct MyTeamView: View {
    @EnvironmentObject var service: PredictionsService
    @EnvironmentObject var favorites: FavoriteStore
    @Environment(SimulationService.self) private var simService
    @Environment(ProStore.self) private var store

    private var allTeams: [String] {
        Set(service.matches.flatMap { [$0.teams.home, $0.teams.away] }).sorted()
    }

    private var teamMatches: [Match] {
        guard let t = favorites.favoriteTeam else { return [] }
        return service.matches
            .filter { $0.teams.home == t || $0.teams.away == t }
            .sorted { $0.kickoff < $1.kickoff }
    }

    private var teamSim: TeamSim? {
        guard let t = favorites.favoriteTeam else { return nil }
        return simService.simulation?.teams.first(where: { $0.team == t })
    }

    var body: some View {
        NavigationStack {
            Group {
                if favorites.favoriteTeam == nil {
                    teamPicker
                } else {
                    ScrollView {
                        VStack(spacing: Theme.s4) {
                            // Pro: Titel-Chance + Funnel
                            if let ts = teamSim {
                                titleChanceCard(ts)
                                reachFunnelCard(ts)
                            }
                            // Free: Matches
                            matchList
                        }
                        .padding(Theme.s4)
                    }
                    .background(Theme.depthBase.ignoresSafeArea())
                }
            }
            .navigationTitle("My Team")
            .navigationDestination(for: Match.self) { MatchDetailView(match: $0) }
        }
    }

    // MARK: - Pro: Titel-Chance
    private func titleChanceCard(_ ts: TeamSim) -> some View {
        VStack(spacing: Theme.s2) {
            HStack {
                FlagView(team: ts.team).font(.title)
                Text(ts.team).font(.title2.bold())
            }
            Text("Title Chance")
                .font(.caption)
                .foregroundStyle(.secondary)
            NumberTicker(value: ts.win)
                .foregroundStyle(Theme.gold)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.s5)
        .liquidCard()
        .lockedIfNotPro()
    }

    // MARK: - Pro: Reach-Funnel
    private func reachFunnelCard(_ ts: TeamSim) -> some View {
        VStack(alignment: .leading, spacing: Theme.s3) {
            Text("Tournament Path").font(.subheadline.bold())
            ReachFunnel(rounds: [
                ("R32", ts.reach["r32"] ?? 0),
                ("R16", ts.reach["r16"] ?? 0),
                ("QF",  ts.reach["qf"] ?? 0),
                ("SF",  ts.reach["sf"] ?? 0),
                ("Final", ts.reach["final"] ?? 0),
                ("Title", ts.reach["title"] ?? 0),
            ])
        }
        .padding(Theme.s4)
        .liquidCard()
        .lockedIfNotPro()
    }

    // MARK: - Free: Match-Liste
    private var matchList: some View {
        VStack(spacing: Theme.s2) {
            HStack {
                FlagView(team: favorites.favoriteTeam!)
                Text(favorites.favoriteTeam!).font(.headline)
                Spacer()
                Button("Change") { favorites.favoriteTeam = nil }
                    .font(.subheadline)
                    .foregroundStyle(Theme.accent)
            }
            ForEach(teamMatches) { m in
                NavigationLink(value: m) { MatchRow(match: m) }
                    .buttonStyle(.plain)
            }
            if teamMatches.isEmpty {
                ContentUnavailableView("No upcoming matches", systemImage: "calendar.badge.clock")
            }
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
