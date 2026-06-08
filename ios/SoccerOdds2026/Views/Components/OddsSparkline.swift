// ios/SoccerOdds2026/Views/Components/OddsSparkline.swift
import SwiftUI

/// Einfache Liniengrafik fuer Quoten-Bewegung (home/draw/away-Linien).
/// Erwartet OddsSnapshot-Array aus OddsHistoryService (Plan 4).
struct OddsSparkline: View {
    /// [OddsSnapshot] aus OddsHistoryService, chronologisch
    let snapshots: [OddsSnapshot]   // OddsSnapshot = Plan-4-Typ {t,home,draw,away}
    var height: CGFloat = 60

    var body: some View {
        if snapshots.count < 2 {
            // Zu wenig Datenpunkte: Platzhalter
            Text("Movement data builds over tournament")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: height)
        } else {
            Canvas { ctx, size in
                drawLine(ctx: ctx, size: size, values: snapshots.map(\.home), color: UIColor(Theme.home))
                drawLine(ctx: ctx, size: size, values: snapshots.map(\.draw), color: UIColor(Theme.draw))
                drawLine(ctx: ctx, size: size, values: snapshots.map(\.away), color: UIColor(Theme.away))
            }
            .frame(height: height)
            // Legende
            HStack(spacing: Theme.s3) {
                legendItem("H", Theme.home)
                legendItem("D", Theme.draw)
                legendItem("A", Theme.away)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private func drawLine(ctx: GraphicsContext, size: CGSize, values: [Double], color: UIColor) {
        guard values.count >= 2 else { return }
        let minV = values.min()!
        let maxV = max(values.max()!, minV + 1)
        let stepX = size.width / CGFloat(values.count - 1)
        var path = Path()
        for (i, v) in values.enumerated() {
            let x = CGFloat(i) * stepX
            let y = size.height * (1 - (v - minV) / (maxV - minV))
            i == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
        }
        ctx.stroke(path, with: .color(Color(color)), lineWidth: 2)
    }

    private func legendItem(_ label: String, _ color: Color) -> some View {
        HStack(spacing: 2) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
        }
    }
}
