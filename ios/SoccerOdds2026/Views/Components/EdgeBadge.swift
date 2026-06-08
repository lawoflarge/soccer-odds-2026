// ios/SoccerOdds2026/Views/Components/EdgeBadge.swift
import SwiftUI

/// Zeigt "+3.2% AWAY VALUE" wenn ein Edge vorhanden ist. Nil-safe.
struct EdgeBadge: View {
    let edge: MatchEdge?        // MatchEdge = Plan-4-Typ {side: String, valuePct: Double}

    var body: some View {
        if let e = edge {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.caption2)
                Text("+\(String(format: "%.1f", e.valuePct))% \(e.side.uppercased()) VALUE")
                    .font(.system(.caption, design: .rounded).weight(.bold))
            }
            .foregroundStyle(Theme.gold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.gold.opacity(0.15), in: Capsule())
        }
    }
}
