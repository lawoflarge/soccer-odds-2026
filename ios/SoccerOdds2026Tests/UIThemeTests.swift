// ios/SoccerOdds2026/Tests/UIThemeTests.swift
import XCTest
import SwiftUI
@testable import SoccerOdds2026

final class UIThemeTests: XCTestCase {
    func testPhaseColor_finalIsGold() {
        // Gold hat R=1.0, G=0.824, B=0.29
        let gold = Theme.phaseColor("final")
        XCTAssertEqual(gold, Theme.gold)
    }

    func testPhaseColor_unknownIsFallback() {
        let fallback = Theme.phaseColor(nil)
        XCTAssertEqual(fallback, Color.secondary)
    }

    func testPhaseLabel_allKnownPhasesNonEmpty() {
        let phases = ["group","round_of_32","round_of_16","qf","sf","third","final"]
        for p in phases {
            XCTAssertFalse(Theme.phaseLabel(p).isEmpty, "Label fuer \(p) ist leer")
        }
    }

    func testPhaseLabel_unknownIsTBD() {
        XCTAssertEqual(Theme.phaseLabel(nil), "TBD")
    }
}
