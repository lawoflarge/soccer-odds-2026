// ios/SoccerOdds2026/Views/Components/SkeletonShimmer.swift
import SwiftUI

/// Platzhalter-Block mit Shimmer-Effekt fuer Lade-Zustaende.
struct SkeletonShimmer: View {
    var width: CGFloat? = nil
    var height: CGFloat = 18
    var radius: CGFloat = 8

    @State private var phase: CGFloat = -1

    var body: some View {
        Rectangle()
            .fill(shimmerGradient)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.white.opacity(0.05), location: 0),
                .init(color: Color.white.opacity(0.15), location: 0.5 + phase * 0.5),
                .init(color: Color.white.opacity(0.05), location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
