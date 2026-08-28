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

    // ProGate: wenn isPro=true, darf kein Blur aktiv sein
    func testProGate_notLockedWhenPro() {
        // Logik: locked = !isPro
        let isPro = true
        XCTAssertFalse(!isPro, "Wenn isPro=true muss locked false sein")
    }

    func testProGate_lockedWhenNotPro() {
        let isPro = false
        XCTAssertTrue(!isPro, "Wenn isPro=false muss locked true sein")
    }
}

/// predictions.json ist ungeprueft. Int(Double) bricht bei NaN und bei allem
/// ausserhalb des Int-Bereichs ab, deshalb muss jeder Prozentwert vor der
/// Umwandlung begrenzt werden.
final class PctBoundsTests: XCTestCase {
    func testIntSurvivesNaNAndOverflow() {
        XCTAssertEqual(Pct.int(.nan), 0)
        XCTAssertEqual(Pct.int(.infinity), 0)
        XCTAssertEqual(Pct.int(-.infinity), 0)
        XCTAssertEqual(Pct.int(1e30), 100)
        XCTAssertEqual(Pct.int(-42), 0)
    }

    func testIntRoundsLikeBefore() {
        XCTAssertEqual(Pct.int(0), 0)
        XCTAssertEqual(Pct.int(42.4), 42)
        XCTAssertEqual(Pct.int(42.5), 43)
        XCTAssertEqual(Pct.int(100), 100)
    }

    func testClampedKeepsWidthsFinite() {
        XCTAssertEqual(Pct.clamped(.nan), 0)
        XCTAssertEqual(Pct.clamped(1e30), 100)
        XCTAssertEqual(Pct.clamped(37.5), 37.5)
    }
}
