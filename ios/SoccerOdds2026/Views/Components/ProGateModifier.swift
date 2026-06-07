// ios/SoccerOdds2026/Views/Components/ProGateModifier.swift
import SwiftUI

/// Blendet Pro-Inhalte aus und fordert zum Kauf auf, solange isPro=false.
/// Nutzung: anyView.lockedIfNotPro()
struct ProGateModifier: ViewModifier {
    @Environment(ProStore.self) private var store
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        let locked = !store.isPro
        content
            .blur(radius: locked ? 8 : 0)
            .overlay {
                if locked {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.cardRadius)
                            .fill(.ultraThinMaterial)
                        VStack(spacing: Theme.s2) {
                            Image(systemName: "lock.fill")
                                .font(.title)
                                .foregroundStyle(Theme.gold)
                            Text("Pro Feature")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Unlock with Soccer Odds Pro")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(Theme.s4)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { showPaywall = true }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: locked)
            .sheet(isPresented: $showPaywall) { PaywallView() }
    }
}

extension View {
    /// Zeigt Blur + Lock-Overlay, falls ProStore.isPro == false. Tap oeffnet PaywallView.
    func lockedIfNotPro() -> some View {
        modifier(ProGateModifier())
    }
}

/// Lock content only when its index is at/after freeCount (free teaser: first `freeCount` items visible).
struct ConditionalProGate: ViewModifier {
    let index: Int
    let freeCount: Int
    @Environment(ProStore.self) private var store
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        let locked = index >= freeCount && !store.isPro
        content
            .blur(radius: locked ? 6 : 0)
            .overlay {
                if locked {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(Theme.gold)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { showPaywall = true }
                }
            }
            .animation(.easeInOut(duration: 0.15), value: locked)
            .sheet(isPresented: $showPaywall) { PaywallView() }
    }
}

extension View {
    func lockedIfNotPro(onlyWhenIndex idx: Int, freeCount: Int) -> some View {
        modifier(ConditionalProGate(index: idx, freeCount: freeCount))
    }
}
