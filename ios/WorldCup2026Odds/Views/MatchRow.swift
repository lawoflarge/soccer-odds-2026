import SwiftUI

struct MatchRow: View {
    let match: Match

    private var kickoffLabel: String {
        guard let d = match.kickoffDate else { return "" }
        return d.formatted(date: .omitted, time: .shortened)
    }
    private var predictedScore: String { match.topScores.first?.score ?? "—" }
    private var predictedPct: Int { Int((match.topScores.first?.pct ?? 0).rounded()) }

    var body: some View {
        VStack(spacing: Theme.s3) {
            HStack(spacing: Theme.s2) {
                HStack(spacing: 6) {
                    FlagView(team: match.teams.home)
                    Text(match.teams.home).fontWeight(.semibold).lineLimit(1).minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(predictedScore.replacingOccurrences(of: ":", with: " : "))
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .monospacedDigit()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 9))

                HStack(spacing: 6) {
                    Text(match.teams.away).fontWeight(.semibold).lineLimit(1).minimumScaleFactor(0.7)
                    FlagView(team: match.teams.away)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            ProbabilityBar(probs: match.probs1x2)

            Text("\(kickoffLabel)  ·  most likely \(predictedScore) (\(predictedPct)%)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(Theme.s4)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}
