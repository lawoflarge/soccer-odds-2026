// ios/SoccerOdds2026/Views/MatchRow.swift
import SwiftUI

struct MatchRow: View {
    let match: Match
    @Environment(ProStore.self) private var store

    private var kickoffLabel: String {
        guard let d = match.kickoffDate else { return "" }
        return d.formatted(date: .omitted, time: .shortened)
    }
    private var predictedScore: String { match.topScores.first?.score ?? "--" }
    private var predictedPct: Int { Int((match.topScores.first?.pct ?? 0).rounded()) }

    @State private var pressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.s2) {
            // Phase-Tag (nur K.o.-Phase)
            PhaseTag(phase: match.phase)

            // Teams + Score
            HStack(spacing: Theme.s2) {
                teamLabel(match.teams.home, align: .leading)

                Text(predictedScore.replacingOccurrences(of: ":", with: " : "))
                    .font(.heroScore)
                    .monospacedDigit()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))

                teamLabel(match.teams.away, align: .trailing)
            }

            // Animierte 1X2-Bar
            AnimatedProbBar(probs: match.probs1x2, compact: true)
                .frame(height: 8)

            // Footer
            HStack {
                Text("\(kickoffLabel)  ·  \(predictedScore) (\(predictedPct)%)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                // Edge-Badge nur fuer Pro
                if store.isPro {
                    EdgeBadge(edge: match.edge)
                }
            }
        }
        .padding(Theme.s4)
        .liquidCard()
        .scaleEffect(pressed ? 0.97 : 1.0)
        .animation(.spring(duration: 0.2, bounce: 0.4), value: pressed)
        ._onButtonGesture(pressing: { pressed = $0 }, perform: {})
    }

    private func teamLabel(_ name: String, align: Alignment) -> some View {
        HStack(spacing: 6) {
            if align == .trailing {
                Text(name).fontWeight(.semibold).lineLimit(1).minimumScaleFactor(0.7)
                FlagView(team: name)
            } else {
                FlagView(team: name)
                Text(name).fontWeight(.semibold).lineLimit(1).minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: align)
    }
}
