// ios/SoccerOdds2026/Views/Components/NumberTicker.swift
import SwiftUI

/// Animierter Zahl-Ticker: zeigt Double als ganzzahligen Prozentwert mit "%" Suffix.
/// Bei Wert-Aenderung laeuft eine kurze Zaehl-Animation.
struct NumberTicker: View {
    let value: Double           // Prozentwert 0..100
    var decimals: Int = 0
    var suffix: String = "%"

    @State private var displayed: Double = 0

    var body: some View {
        Text(formatted(displayed))
            .font(.winPct)
            .monospacedDigit()
            .foregroundStyle(.primary)
            .onAppear { animate(to: value) }
            .onChange(of: value) { _, new in animate(to: new) }
    }

    private func formatted(_ v: Double) -> String {
        String(format: "%.\(decimals)f", v) + suffix
    }

    private func animate(to target: Double) {
        withAnimation(.easeOut(duration: 0.6)) { displayed = target }
    }
}
