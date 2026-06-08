// ios/SoccerOdds2026/Views/MatchDetailView.swift
import SwiftUI

struct MatchDetailView: View {
    let match: Match
    @Environment(ProStore.self) private var store
    @Environment(OddsHistoryService.self) private var historyService   // Plan-4-Typ

    private var snapshots: [OddsSnapshot] {
        historyService.snapshots(for: match.id)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.s4) {
                heroCard
                prob1x2Card
                proSectionEdge
                proSectionSparkline
                topScoresCard
                goalMarketsCard
                proSectionXG
                proSectionExtMarkets
                disclaimer
            }
            .padding(Theme.s4)
        }
        .navigationTitle("\(match.teams.home) – \(match.teams.away)")
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.depthBase.ignoresSafeArea())
    }

    // MARK: - Hero Card (Floating Score)
    private var heroCard: some View {
        ZStack {
            // Hintergrund-Verlauf mit Team-Phase-Farbe
            LinearGradient(
                colors: [Theme.phaseColor(match.phase).opacity(0.35), Theme.depthSurface],
                startPoint: .top, endPoint: .bottom
            )

            VStack(spacing: Theme.s3) {
                PhaseTag(phase: match.phase)

                HStack(alignment: .center) {
                    VStack {
                        FlagView(team: match.teams.home)
                            .font(.system(size: 40))
                        Text(match.teams.home)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)

                    // Floating Score Hero
                    VStack(spacing: 2) {
                        Text((match.topScores.first?.score ?? "--").replacingOccurrences(of: ":", with: " : "))
                            .font(.heroScore)
                            .monospacedDigit()
                        Text("most likely")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if let pct = match.topScores.first?.pct {
                            Text(String(format: "%.1f%%", pct))
                                .font(.caption)
                                .foregroundStyle(Theme.accent)
                                .monospacedDigit()
                        }
                    }
                    .padding(.horizontal, Theme.s4)

                    VStack {
                        FlagView(team: match.teams.away)
                            .font(.system(size: 40))
                        Text(match.teams.away)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                }

                // Kickoff + Venue
                if let d = match.kickoffDate {
                    Text(d.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(Theme.s5)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.phaseColor(match.phase).opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - 1X2 Wahrscheinlichkeiten
    private var prob1x2Card: some View {
        VStack(alignment: .leading, spacing: Theme.s3) {
            Text("Match Result").font(.subheadline.bold())

            HStack(alignment: .top) {
                DonutChart(probs: match.probs1x2, size: 80)
                Spacer()
                VStack(alignment: .trailing, spacing: Theme.s2) {
                    probRow("Home", match.probs1x2.home, Theme.home)
                    probRow("Draw", match.probs1x2.draw, Theme.draw)
                    probRow("Away", match.probs1x2.away, Theme.away)
                }
            }
            AnimatedProbBar(probs: match.probs1x2)
        }
        .padding(Theme.s4)
        .liquidCard()
    }

    private func probRow(_ label: String, _ value: Double, _ color: Color) -> some View {
        HStack(spacing: Theme.s2) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption)
            Text("\(Int(value.rounded()))%")
                .font(.caption.bold())
                .monospacedDigit()
                .foregroundStyle(color)
        }
    }

    // MARK: - Pro: Edge-Badge
    @ViewBuilder
    private var proSectionEdge: some View {
        if let edge = match.edge {
            VStack(alignment: .leading, spacing: Theme.s2) {
                Text("Value Edge").font(.subheadline.bold())
                EdgeBadge(edge: edge)
                Text("Fair model vs. best available odds.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(Theme.s4)
            .liquidCard()
            .lockedIfNotPro()
        }
    }

    // MARK: - Pro: Line-Movement-Sparkline
    @ViewBuilder
    private var proSectionSparkline: some View {
        VStack(alignment: .leading, spacing: Theme.s3) {
            Text("Odds Movement").font(.subheadline.bold())
            OddsSparkline(snapshots: snapshots)
        }
        .padding(Theme.s4)
        .liquidCard()
        .lockedIfNotPro()
    }

    // MARK: - Top Scores
    private var topScoresCard: some View {
        VStack(alignment: .leading, spacing: Theme.s2) {
            Text("Most Likely Scores").font(.subheadline.bold())
            ForEach(match.topScores.prefix(5)) { s in
                HStack {
                    Text(s.score).monospacedDigit().font(.body.weight(.medium))
                    Spacer()
                    Text(String(format: "%.1f%%", s.pct))
                        .font(.caption.bold()).monospacedDigit()
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .padding(Theme.s4)
        .liquidCard()
    }

    // MARK: - Goal Markets (Free)
    private var goalMarketsCard: some View {
        VStack(alignment: .leading, spacing: Theme.s2) {
            Text("Goals").font(.subheadline.bold())
            marketRow("Over 2.5", match.goalMarkets.overUnder2_5)
            marketRow("Both Teams to Score", match.goalMarkets.btts)
        }
        .padding(Theme.s4)
        .liquidCard()
    }

    // MARK: - Pro: xG
    @ViewBuilder
    private var proSectionXG: some View {
        if let xg = match.xg {
            VStack(alignment: .leading, spacing: Theme.s3) {
                Text("Expected Goals (xG)").font(.subheadline.bold())
                HStack {
                    xgPill(match.teams.home, xg.home)
                    Spacer()
                    xgPill(match.teams.away, xg.away)
                }
            }
            .padding(Theme.s4)
            .liquidCard()
            .lockedIfNotPro()
        }
    }

    private func xgPill(_ team: String, _ value: Double) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.2f", value))
                .font(.title2.bold())
                .monospacedDigit()
                .foregroundStyle(Theme.accent)
            Text(team).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
    }

    // MARK: - Pro: Erweiterte Maerkte
    @ViewBuilder
    private var proSectionExtMarkets: some View {
        if let ext = match.marketsExt {
            VStack(alignment: .leading, spacing: Theme.s2) {
                Text("Extended Markets").font(.subheadline.bold())
                marketRow("Over 1.5", ext.over15)
                marketRow("Over 3.5", ext.over35)
                Divider()
                Text("Correct Score (top 5)").font(.caption.bold()).foregroundStyle(.secondary)
                ForEach(ext.correctScore.prefix(5)) { s in
                    HStack {
                        Text(s.score).monospacedDigit()
                        Spacer()
                        Text(String(format: "%.1f%%", s.pct))
                            .font(.caption.bold()).monospacedDigit()
                    }
                    .font(.caption)
                }
            }
            .padding(Theme.s4)
            .liquidCard()
            .lockedIfNotPro()
        }
    }

    private func marketRow(_ label: String, _ value: Double) -> some View {
        HStack {
            Text(label).font(.subheadline)
            Spacer()
            Text("\(Int(value.rounded()))%")
                .font(.subheadline.bold())
                .monospacedDigit()
        }
    }

    private var disclaimer: some View {
        Text("Based on bookmaker consensus · for entertainment only.")
            .font(.caption2).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, Theme.s4)
    }
}
