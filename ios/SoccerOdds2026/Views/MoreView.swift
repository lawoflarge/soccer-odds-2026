// ios/SoccerOdds2026/Views/MoreView.swift
import SwiftUI

struct MoreView: View {
    @Environment(ProStore.self) private var store
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            List {
                // Pro-Status-Banner
                Section {
                    if store.isPro {
                        proActiveRow
                    } else {
                        proUpgradeRow
                    }
                }

                // Navigation
                Section("Analytics") {
                    NavigationLink { TrackRecordView() } label: {
                        Label("Track Record", systemImage: "chart.bar.fill")
                    }
                }

                Section("Support") {
                    Link(destination: URL(string: "https://soccer-odds-2026.vercel.app/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    Link(destination: URL(string: "https://www.begambleaware.org")!) {
                        Label("BeGambleAware.org", systemImage: "exclamationmark.shield.fill")
                    }
                    Link(destination: URL(string: "https://www.ncpgambling.org")!) {
                        Label("ncpgambling.org (US)", systemImage: "exclamationmark.shield")
                    }
                }

                Section("About") {
                    Label("Soccer Odds 2026 v2.0", systemImage: "soccerball")
                    Text("Powered by a Poisson goal model and consensus bookmaker odds. Independent app — not affiliated with FIFA or any governing body.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("More")
            .scrollContentBackground(.hidden)
            .background(Theme.depthBase.ignoresSafeArea())
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var proActiveRow: some View {
        HStack {
            Image(systemName: "star.fill").foregroundStyle(Theme.gold)
            VStack(alignment: .leading) {
                Text("Pro Unlocked").font(.headline)
                Text("All features active · No ads").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Theme.s1)
    }

    private var proUpgradeRow: some View {
        Button { showPaywall = true } label: {
            HStack {
                Image(systemName: "lock.open.fill").foregroundStyle(Theme.gold)
                VStack(alignment: .leading) {
                    Text("Unlock Soccer Odds Pro").font(.headline)
                    if let price = store.products.first?.displayPrice {
                        Text("\(price) · one-time purchase").font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("4.99 EUR · one-time purchase").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary).font(.caption)
            }
        }
        .padding(.vertical, Theme.s1)
    }
}
