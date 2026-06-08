// ios/SoccerOdds2026/Views/PaywallView.swift
import SwiftUI
import StoreKit

/// Paywall (Stil B — Stadion Premium): dunkel, Gold-Akzent #ffd24a, Liquid-Glass-Karte.
/// Shown modally when the user taps a locked Pro feature.
struct PaywallView: View {

    @Environment(ProStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var isRestoring  = false
    @State private var errorMessage: String?

    // MARK: - Pro feature list

    private let features: [(icon: String, title: String, subtitle: String)] = [
        ("chart.line.uptrend.xyaxis",     "Edge Detection",         "See which side the market undervalues"),
        ("arrow.up.arrow.down",           "Line Movement",          "Track how odds shift before kick-off"),
        ("trophy.fill",                   "Tournament Simulation",  "10,000 Monte-Carlo runs per update"),
        ("bolt.fill",                     "xG + Extra Markets",     "Expected goals, Over 1.5/3.5, BTTS detail"),
        ("checkmark.seal.fill",           "Track Record",           "Live Brier score — see the model earn trust"),
        ("nosign",                        "Ad-free",                "No banners, ever"),
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: 0) {
                    closeButton
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    heroSection
                        .padding(.top, 8)

                    featureList
                        .padding(.top, 28)

                    trustAnchor
                        .padding(.top, 24)

                    purchaseButton
                        .padding(.top, 32)
                        .padding(.horizontal, 24)

                    restoreButton
                        .padding(.top, 12)

                    legalNote
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await store.loadProducts() }
    }

    // MARK: - Sub-views

    private var background: some View {
        LinearGradient(
            colors: [Color(hex: "0f1419"), Color(hex: "1d2b1f")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .accessibilityLabel("Close")
    }

    private var heroSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Color(hex: "ffd24a"))
                .symbolEffect(.pulse, options: .repeating)

            Text("Soccer Odds Pro")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text("Quant-edge analysis for the World Cup 2026")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var featureList: some View {
        VStack(spacing: 0) {
            ForEach(features, id: \.title) { f in
                featureRow(icon: f.icon, title: f.title, subtitle: f.subtitle)
                if f.title != features.last?.title {
                    Divider()
                        .background(.white.opacity(0.1))
                        .padding(.leading, 60)
                }
            }
        }
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        }
        .padding(.horizontal, 16)
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "ffd24a"))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.caption.bold())
                .foregroundStyle(Color(hex: "3ad17f"))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }

    private var trustAnchor: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .foregroundStyle(Color(hex: "ffd24a"))
            Text("Track Record grows live — every settled match sharpens the model score.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 28)
    }

    private var purchaseButton: some View {
        Button {
            Task { await doPurchase() }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text(priceLabel)
                        .font(.system(.body, weight: .bold))
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color(hex: "ffd24a"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(isPurchasing || isRestoring)
        .accessibilityLabel("Purchase Pro for \(priceLabel)")
    }

    private var restoreButton: some View {
        Button {
            Task { await doRestore() }
        } label: {
            if isRestoring {
                ProgressView().tint(.white)
            } else {
                Text("Restore Purchase")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .disabled(isPurchasing || isRestoring)
    }

    private var legalNote: some View {
        Group {
            if let msg = errorMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else {
                Text("One-time purchase. No subscription. Automatically restored on your other devices.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - Helpers

    private var priceLabel: String {
        store.products.first(where: { $0.id == ProStore.productID })?.displayPrice ?? "Get Pro"
    }

    // MARK: - Actions

    private func doPurchase() async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            try await store.purchase()
            if store.isPro { dismiss() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func doRestore() async {
        isRestoring = true
        errorMessage = nil
        defer { isRestoring = false }
        do {
            try await store.restore()
            if store.isPro { dismiss() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Hex color helper (local, avoids Theme dependency)

private extension Color {
    init(hex: String) {
        let v = UInt64((Scanner(string: hex).scanUInt64(representation: .hexadecimal) ?? 0) &
                       (hex.count == 6 ? 0xFFFFFF : 0xFFFFFFFF))
        let r, g, b: Double
        if hex.count == 6 {
            (r, g, b) = (Double((v >> 16) & 0xFF)/255, Double((v >> 8) & 0xFF)/255, Double(v & 0xFF)/255)
        } else {
            (r, g, b) = (Double((v >> 24) & 0xFF)/255, Double((v >> 16) & 0xFF)/255, Double((v >> 8) & 0xFF)/255)
        }
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environment(ProStore())
}
