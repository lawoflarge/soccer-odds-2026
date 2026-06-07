// ios/SoccerOdds2026/Views/Components/ReachFunnel.swift
import SwiftUI

/// Horizontaler Balken-Funnel fuer Monte-Carlo-Reichweiten.
/// rounds: geordnete Liste von (Label, Prozentwert).
struct ReachFunnel: View {
    let rounds: [(label: String, pct: Double)]   // z.B. [("R32",100),("R16",82),...]

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.s2) {
            ForEach(Array(rounds.enumerated()), id: \.offset) { idx, r in
                HStack(spacing: Theme.s3) {
                    Text(r.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .leading)
                    GeometryReader { geo in
                        let w = geo.size.width * (appeared ? r.pct / 100 : 0)
                        let color = r.label == "Title" ? Theme.gold : Theme.accent
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.85))
                            .frame(width: max(w, 2))
                            .animation(.spring(duration: 0.6, bounce: 0.15).delay(Double(idx) * 0.08),
                                       value: appeared)
                    }
                    .frame(height: 18)
                    Text("\(String(format: "%.0f", r.pct))%")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .onAppear { appeared = true }
    }
}
