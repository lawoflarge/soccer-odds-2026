import SwiftUI

/// A horizontal stacked bar showing home/draw/away shares.
struct ProbabilityBar: View {
    let probs: Probs1x2
    var compact: Bool = false

    private var total: Double {
        max(Pct.clamped(probs.home) + Pct.clamped(probs.draw) + Pct.clamped(probs.away), 0.0001)
    }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                segment(probs.home, Theme.home, width: geo.size.width)
                segment(probs.draw, Theme.draw, width: geo.size.width)
                segment(probs.away, Theme.away, width: geo.size.width)
            }
        }
        .frame(height: compact ? 8 : 22)
        .clipShape(Capsule())
        .accessibilityElement()
        .accessibilityLabel("Home \(Pct.int(probs.home)) percent, draw \(Pct.int(probs.draw)) percent, away \(Pct.int(probs.away)) percent")
    }

    private func segment(_ rawValue: Double, _ color: Color, width: CGFloat) -> some View {
        let value = Pct.clamped(rawValue)
        return ZStack {
            color
            if !compact, value / total > 0.12 {
                Text("\(Pct.int(value))%")
                    .font(.pctLabel)
                    .foregroundStyle(.white)
            }
        }
        .frame(width: width * value / total)
    }
}
