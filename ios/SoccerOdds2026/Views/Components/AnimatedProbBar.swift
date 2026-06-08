// ios/SoccerOdds2026/Views/Components/AnimatedProbBar.swift
import SwiftUI

/// Erweiterung von ProbabilityBar mit Einblend-Animation beim ersten Erscheinen.
struct AnimatedProbBar: View {
    let probs: Probs1x2
    var compact: Bool = false

    @State private var appeared = false

    private var animatedProbs: Probs1x2 {
        appeared ? probs : Probs1x2(home: 0, draw: 0, away: 0)
    }

    var body: some View {
        ProbabilityBar(probs: animatedProbs, compact: compact)
            .onAppear {
                withAnimation(.spring(duration: 0.7, bounce: 0.2)) { appeared = true }
            }
    }
}
