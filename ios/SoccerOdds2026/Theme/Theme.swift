// ios/SoccerOdds2026/Theme/Theme.swift
import SwiftUI

enum Theme {
    // MARK: - 1x2 Segment Colors (bestehend, unveraendert)
    static let home = Color("HomeAccent")
    static let draw = Color("DrawAccent")
    static let away = Color("AwayAccent")

    // MARK: - Spacing (bestehend, unveraendert)
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 24

    static let cardRadius: CGFloat = 16

    // MARK: - Stadion Premium Farben (neu)
    /// Tiefster Hintergrund (Nacht-Schwarz mit Gruenstich)
    static let depthBase = Color(red: 0.059, green: 0.078, blue: 0.098)       // #0f1419
    /// Zweiter Hintergrund (dunkelgruenes Rasen-Tief)
    static let depthSurface = Color(red: 0.114, green: 0.169, blue: 0.122)    // #1d2b1f

    /// Gold-Akzent (Finale, Highlights)
    static let gold = Color(red: 1.0, green: 0.824, blue: 0.290)              // #ffd24a
    /// Gruen-Akzent (Trefferquote, Fortschritt)
    static let accent = Color(red: 0.227, green: 0.820, blue: 0.498)          // #3ad17f

    // MARK: - Phasen-Farbcodierung
    /// Gibt die Akzentfarbe fuer eine Match-Phase zurueck.
    static func phaseColor(_ phase: String?) -> Color {
        switch phase {
        case "group":      return Color.secondary
        case "round_of_32": return Color(red: 0.4, green: 0.7, blue: 1.0)     // hellblau
        case "round_of_16": return Color(red: 0.3, green: 0.85, blue: 0.7)    // tuerkis
        case "qf":         return Color(red: 1.0, green: 0.65, blue: 0.2)     // orange
        case "sf":         return Color(red: 0.9, green: 0.3, blue: 0.5)      // rosa
        case "third":      return Color(red: 0.7, green: 0.55, blue: 0.3)     // bronze
        case "final":      return gold
        default:           return Color.secondary
        }
    }

    /// Lesbare Phasen-Bezeichnung
    static func phaseLabel(_ phase: String?) -> String {
        switch phase {
        case "group":       return "Group Stage"
        case "round_of_32": return "Round of 32"
        case "round_of_16": return "Round of 16"
        case "qf":          return "Quarter-Final"
        case "sf":          return "Semi-Final"
        case "third":       return "3rd Place"
        case "final":       return "Final"
        default:            return "TBD"
        }
    }
}

// MARK: - Font Extensions
extension Font {
    /// Bestehend (unveraendert)
    static let pctLabel = Font.system(.caption, design: .rounded).weight(.semibold)
    /// Grosse Score-Zahl (Hero, tabular-nums via monospacedDigit())
    static let heroScore = Font.system(.largeTitle, design: .rounded).weight(.heavy)
    /// Sieg-Prozent in Turnier-Liste
    static let winPct = Font.system(.title2, design: .rounded).weight(.bold)
}

// MARK: - Liquid-Glass-Karten-Modifier
struct LiquidCard: ViewModifier {
    var radius: CGFloat = Theme.cardRadius
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}

extension View {
    /// Liquid-Glass-Karte: ultraThinMaterial + Border.
    func liquidCard(radius: CGFloat = Theme.cardRadius) -> some View {
        modifier(LiquidCard(radius: radius))
    }
}
