// ios/SoccerOdds2026/Views/Components/DonutChart.swift
import SwiftUI

/// Animierter Donut-Chart fuer 1X2-Wahrscheinlichkeiten.
struct DonutChart: View {
    let probs: Probs1x2
    var size: CGFloat = 100

    @State private var appeared = false

    private var segments: [(value: Double, color: Color)] {
        [(probs.home, Theme.home), (probs.draw, Theme.draw), (probs.away, Theme.away)]
    }
    private var total: Double { max(probs.home + probs.draw + probs.away, 0.001) }

    var body: some View {
        ZStack {
            ForEach(Array(segments.enumerated()), id: \.offset) { idx, seg in
                Circle()
                    .trim(from: appeared ? startAngle(idx) : 0,
                          to: appeared ? endAngle(idx) : 0)
                    .stroke(seg.color, style: StrokeStyle(lineWidth: size * 0.18, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.8, bounce: 0.1).delay(Double(idx) * 0.1), value: appeared)
            }
            VStack(spacing: 0) {
                Text("\(Int(max(probs.home, probs.draw, probs.away).rounded()))%")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .monospacedDigit()
                Text("top")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear { appeared = true }
    }

    private func startAngle(_ idx: Int) -> CGFloat {
        let sum = segments.prefix(idx).reduce(0) { $0 + $1.value }
        return CGFloat(sum / total)
    }
    private func endAngle(_ idx: Int) -> CGFloat {
        let sum = segments.prefix(idx + 1).reduce(0) { $0 + $1.value }
        return CGFloat(sum / total)
    }
}
