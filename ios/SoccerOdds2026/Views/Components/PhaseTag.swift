// ios/SoccerOdds2026/Views/Components/PhaseTag.swift
import SwiftUI

/// Kleines Label-Tag mit Phasen-Farbe (z.B. "Quarter-Final" in Orange).
struct PhaseTag: View {
    let phase: String?

    var body: some View {
        if let phase, phase != "group" {
            Text(Theme.phaseLabel(phase).uppercased())
                .font(.system(.caption2, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.phaseColor(phase))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Theme.phaseColor(phase).opacity(0.15),
                            in: Capsule())
        }
    }
}
