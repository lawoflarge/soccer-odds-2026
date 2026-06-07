// ios/SoccerOdds2026/Views/TrackRecordView.swift
import SwiftUI

struct TrackRecordView: View {
    @Environment(TrackRecordService.self) private var trackService   // Plan-4-Typ
    @Environment(ProStore.self) private var store

    private var record: TrackRecord? { trackService.trackRecord }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.s4) {
                if let r = record {
                    headerCard(r)
                    marketsCard(r)
                } else {
                    loadingPlaceholder
                }
                disclaimer
            }
            .padding(Theme.s4)
        }
        .navigationTitle("Track Record")
        .background(Theme.depthBase.ignoresSafeArea())
        .task { await trackService.refresh() }
    }

    // MARK: - Header
    private func headerCard(_ r: TrackRecord) -> some View {
        VStack(spacing: Theme.s2) {
            Text("Settled Matches")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(r.settledMatches)")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.accent)
            Text("Updated \(String(r.updatedAt.prefix(10)))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.s5)
        .liquidCard()
    }

    // MARK: - Je-Markt-Tabelle
    private func marketsCard(_ r: TrackRecord) -> some View {
        VStack(alignment: .leading, spacing: Theme.s3) {
            Text("By Market").font(.subheadline.bold())
            Divider().opacity(0.3)

            // Header
            HStack {
                Text("Market").frame(maxWidth: .infinity, alignment: .leading)
                Text("N").frame(width: 30, alignment: .trailing)
                Text("Brier").frame(width: 55, alignment: .trailing)
                Text("Hit%").frame(width: 45, alignment: .trailing)
            }
            .font(.caption.bold())
            .foregroundStyle(.secondary)

            // Zeilen
            ForEach(Array(r.byMarket.keys.sorted().enumerated()), id: \.element) { idx, key in
                marketRow(key: key, rec: r.byMarket[key]!)
                    .lockedIfNotPro(onlyWhenIndex: idx, freeCount: 2)
                Divider().opacity(0.2)
            }
        }
        .padding(Theme.s4)
        .liquidCard()
    }

    private func marketRow(key: String, rec: MarketRecord) -> some View {
        HStack {
            Text(marketLabel(key))
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(rec.n)")
                .font(.caption.bold()).monospacedDigit()
                .frame(width: 30, alignment: .trailing)
                .foregroundStyle(.secondary)
            Text(String(format: "%.2f", rec.brier))
                .font(.caption.bold()).monospacedDigit()
                .frame(width: 55, alignment: .trailing)
                .foregroundStyle(brierColor(rec.brier))
            Text(String(format: "%.0f%%", rec.hitRate * 100))
                .font(.caption.bold()).monospacedDigit()
                .frame(width: 45, alignment: .trailing)
                .foregroundStyle(hitColor(rec.hitRate))
        }
    }

    private func marketLabel(_ key: String) -> String {
        switch key {
        case "1x2": return "1X2"
        case "over_2_5": return "Over 2.5"
        case "btts": return "BTTS"
        default: return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func brierColor(_ v: Double) -> Color {
        v < 0.2 ? Theme.accent : v < 0.3 ? Theme.gold : Color.orange
    }
    private func hitColor(_ v: Double) -> Color {
        v >= 0.6 ? Theme.accent : v >= 0.5 ? Theme.gold : Color.orange
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: Theme.s3) {
            ForEach(0..<4, id: \.self) { _ in
                SkeletonShimmer(height: 36, radius: 8)
            }
        }
    }

    private var disclaimer: some View {
        Text("Track record builds live as matches are settled during the tournament.")
            .font(.caption2).foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.bottom, Theme.s4)
    }
}
