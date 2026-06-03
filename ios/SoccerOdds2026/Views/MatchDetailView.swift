import SwiftUI

struct MatchDetailView: View {
    let match: Match

    private var hint: String {
        let p = match.probs1x2
        let leader = max(p.home, p.draw, p.away)
        let side = leader == p.home ? match.teams.home
                 : leader == p.away ? match.teams.away : "a draw"
        let score = match.topScores.first?.score ?? "—"
        return "Market leans to \(side). Most likely score \(score)."
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.s5) {
                HStack {
                    Text(match.teams.home)
                    Spacer(); Text("vs").foregroundStyle(.secondary); Spacer()
                    Text(match.teams.away)
                }
                .font(.headline)

                VStack(alignment: .leading, spacing: Theme.s2) {
                    Text("Match result").font(.subheadline.bold())
                    ProbabilityBar(probs: match.probs1x2)
                    HStack {
                        Text("Home \(Int(match.probs1x2.home))%")
                        Spacer(); Text("Draw \(Int(match.probs1x2.draw))%")
                        Spacer(); Text("Away \(Int(match.probs1x2.away))%")
                    }.font(.caption).foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: Theme.s2) {
                    Text("Most likely scores").font(.subheadline.bold())
                    ForEach(match.topScores) { s in
                        HStack { Text(s.score).monospacedDigit(); Spacer(); Text(String(format: "%.1f%%", s.pct)) }
                    }
                }

                VStack(alignment: .leading, spacing: Theme.s2) {
                    Text("Goals").font(.subheadline.bold())
                    HStack { Text("Over 2.5"); Spacer(); Text("\(Int(match.goalMarkets.overUnder2_5))%") }
                    HStack { Text("Both teams to score"); Spacer(); Text("\(Int(match.goalMarkets.btts))%") }
                }

                Text(hint).font(.callout).padding(Theme.s3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.cardRadius))

                Text("Based on bookmaker consensus · for entertainment only.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(Theme.s4)
        }
        .navigationTitle("\(match.teams.home) – \(match.teams.away)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
