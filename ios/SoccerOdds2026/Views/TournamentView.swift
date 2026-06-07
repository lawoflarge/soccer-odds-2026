// ios/SoccerOdds2026/Views/TournamentView.swift
import SwiftUI

struct TournamentView: View {
    @Environment(SimulationService.self) private var simService   // Plan-4-Typ
    @Environment(ProStore.self) private var store
    @State private var selectedTeam: String? = nil

    private var simulation: TournamentSimulation? { simService.simulation }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let sim = simulation {
                    VStack(spacing: Theme.s4) {
                        generatedAtBanner(sim.generatedAt, iterations: sim.iterations)
                        winChanceList(sim.teams)
                        if let team = selectedTeam,
                           let ts = sim.teams.first(where: { $0.team == team }) {
                            reachFunnelCard(ts)
                        }
                        groupsCard(sim.groups)
                    }
                    .padding(Theme.s4)
                } else {
                    loadingPlaceholder
                }
            }
            .navigationTitle("Tournament")
            .background(Theme.depthBase.ignoresSafeArea())
        }
        .task { await simService.refresh() }
    }

    // MARK: - Generiert-At-Banner
    private func generatedAtBanner(_ isoDate: String, iterations: Int) -> some View {
        HStack {
            Image(systemName: "cpu")
                .foregroundStyle(Theme.gold)
            Text("Monte Carlo · \(iterations / 1000)k simulations")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(shortDate(isoDate))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(Theme.s3)
        .liquidCard()
    }

    // MARK: - Sieg-%-Liste
    private func winChanceList(_ teams: [TeamSim]) -> some View {
        let sorted = teams.sorted { $0.win > $1.win }
        return VStack(alignment: .leading, spacing: Theme.s2) {
            Text("Win Probability")
                .font(.subheadline.bold())
                .padding(.bottom, Theme.s1)

            ForEach(Array(sorted.enumerated()), id: \.element.team) { idx, ts in
                winRow(rank: idx + 1, ts: ts, maxWin: sorted.first?.win ?? 1)
                    .lockedIfNotPro(onlyWhenIndex: idx, freeCount: 3)
            }
        }
        .padding(Theme.s4)
        .liquidCard()
    }

    private func winRow(rank: Int, ts: TeamSim, maxWin: Double) -> some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                selectedTeam = selectedTeam == ts.team ? nil : ts.team
            }
        } label: {
            HStack(spacing: Theme.s3) {
                Text("\(rank)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(width: 20, alignment: .trailing)
                FlagView(team: ts.team)
                Text(ts.team)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                GeometryReader { geo in
                    let w = geo.size.width * CGFloat(ts.win / max(maxWin, 0.01))
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.06))
                        Capsule()
                            .fill(rank <= 3 ? Theme.gold : Theme.accent)
                            .frame(width: w)
                    }
                }
                .frame(width: 80, height: 14)
                Text(String(format: "%.1f%%", ts.win))
                    .font(.caption.bold())
                    .monospacedDigit()
                    .foregroundStyle(rank <= 3 ? Theme.gold : .primary)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
    }

    // MARK: - Reichweiten-Funnel fuer ausgewaehltes Team
    private func reachFunnelCard(_ ts: TeamSim) -> some View {
        VStack(alignment: .leading, spacing: Theme.s3) {
            HStack {
                FlagView(team: ts.team)
                Text(ts.team).font(.headline)
                Spacer()
                Text("Reach Probabilities").font(.caption).foregroundStyle(.secondary)
            }
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

    // MARK: - Gruppen
    private func groupsCard(_ groups: [String: [GroupSim]]) -> some View {
        VStack(alignment: .leading, spacing: Theme.s3) {
            Text("Group Advancement").font(.subheadline.bold())
            ForEach(groups.keys.sorted(), id: \.self) { g in
                groupSection(letter: g, sims: groups[g] ?? [])
            }
        }
        .padding(Theme.s4)
        .liquidCard()
        .lockedIfNotPro()
    }

    private func groupSection(letter: String, sims: [GroupSim]) -> some View {
        VStack(alignment: .leading, spacing: Theme.s1) {
            Text("Group \(letter)")
                .font(.caption.bold())
                .foregroundStyle(Theme.gold)
            ForEach(sims, id: \.team) { gs in
                HStack {
                    FlagView(team: gs.team)
                    Text(gs.team).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                    Text("Adv \(Int(gs.advance.rounded()))%")
                        .font(.caption2).monospacedDigit().foregroundStyle(Theme.accent)
                    Text("Win \(Int(gs.winGroup.rounded()))%")
                        .font(.caption2).monospacedDigit().foregroundStyle(.secondary)
                }
            }
            Divider().opacity(0.3)
        }
    }

    // MARK: - Lade-Platzhalter
    private var loadingPlaceholder: some View {
        VStack(spacing: Theme.s3) {
            ForEach(0..<6, id: \.self) { _ in
                SkeletonShimmer(height: 44, radius: Theme.cardRadius)
            }
        }
        .padding(Theme.s4)
    }

    private func shortDate(_ iso: String) -> String { String(iso.prefix(10)) }
}
