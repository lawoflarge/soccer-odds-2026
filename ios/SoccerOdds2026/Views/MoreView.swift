// ios/SoccerOdds2026/Views/MoreView.swift
import SwiftUI
import CrossPromotionUI

struct MoreView: View {
    var isActive = true
    @State private var promotions = AppPromotions.makeStore()
    @Environment(ProStore.self) private var store
    @Environment(ConsentManager.self) private var consent
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            PromotionViewport { viewport in
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

                if let promotions {
                    AppPromotionSection(store: promotions, viewport: isActive && !showPaywall ? viewport : .zero)
                }

                Section("Support") {
                    Link(destination: URL(string: "https://soccer-odds-2026.vercel.app/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    if consent.privacyOptionsRequired {
                        Button { consent.presentPrivacyOptions() } label: {
                            Label("Ad Privacy Options", systemImage: "hand.raised.circle.fill")
                        }
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
                    Text("Powered by a Poisson goal model and consensus bookmaker odds. Independent app, not affiliated with FIFA or any governing body.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("More")
            .scrollContentBackground(.hidden)
            .background(Theme.depthBase.ignoresSafeArea())
            .sheet(isPresented: $showPaywall) { PaywallView() }
            }
            .promotionLifecycle(promotions, isActive: isActive && !showPaywall)
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
                        Text("One-time purchase · no subscription").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary).font(.caption)
            }
        }
        .padding(.vertical, Theme.s1)
    }
}
