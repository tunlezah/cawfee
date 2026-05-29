import XCTest
@testable import DialedInCoffee

final class RulesEngineTests: XCTestCase {
    func testEmptySymptomsProducesNoAdjustment() {
        let rec = RulesEngine.evaluate(
            symptoms: [],
            current: SampleData.baselineFlatWhite,
            milk: .devondaleFullCreamUHT,
            drink: .flatWhite
        )
        XCTAssertNil(rec.primary)
        XCTAssertNil(rec.secondary)
    }

    func testTooBitterAtFineGrindRecommendsCoarser() {
        let rec = RulesEngine.evaluate(
            symptoms: [.tooBitter],
            current: MachineSettings(grinder: 6),
            milk: .devondaleFullCreamUHT,
            drink: .flatWhite
        )
        XCTAssertEqual(rec.topCause, .overExtraction)
        XCTAssertEqual(rec.primary?.parameter, .grinder)
        XCTAssertEqual(rec.primary?.fromInt, 6)
        XCTAssertEqual(rec.primary?.toInt, 5)
        XCTAssertGreaterThanOrEqual(rec.confidence, 0.7)
    }

    func testTooSourAtCoarseGrindRecommendsFiner() {
        let rec = RulesEngine.evaluate(
            symptoms: [.tooSour],
            current: MachineSettings(grinder: 2),
            milk: .devondaleFullCreamUHT,
            drink: .flatWhite
        )
        XCTAssertEqual(rec.topCause, .underExtraction)
        XCTAssertEqual(rec.primary?.parameter, .grinder)
        XCTAssertEqual(rec.primary?.toInt, 3)
    }

    func testTooWateryRecommendsVolumeReduction() {
        let rec = RulesEngine.evaluate(
            symptoms: [.tooWatery],
            current: MachineSettings(volumeML: 120),
            milk: .devondaleFullCreamUHT,
            drink: .flatWhite
        )
        XCTAssertEqual(rec.topCause, .excessiveDilution)
        XCTAssertEqual(rec.primary?.parameter, .volume)
        XCTAssertTrue((rec.primary?.toInt ?? 999) < 120)
    }

    func testTooHotFlatWhiteAustralianBiasDropsTemp() {
        let rec = RulesEngine.evaluate(
            symptoms: [.tooHot],
            current: MachineSettings(temperature: .high),
            milk: .devondaleFullCreamUHT,
            drink: .flatWhite
        )
        XCTAssertEqual(rec.primary?.parameter, .temperature)
        XCTAssertEqual(rec.primary?.toTemp, .normal)
    }

    func testMaxTwoAdjustments() {
        let rec = RulesEngine.evaluate(
            symptoms: [.tooBitter, .tooBurnt, .tooStrong],
            current: MachineSettings(grinder: 6, strength: 9, temperature: .high),
            milk: .devondaleFullCreamUHT,
            drink: .flatWhite
        )
        XCTAssertNotNil(rec.primary)
        // At most two adjustments emitted.
        XCTAssertLessThanOrEqual(rec.adjustments.count, 2)
        // If two, they must touch different parameters.
        if let s = rec.secondary, let p = rec.primary {
            XCTAssertNotEqual(s.parameter, p.parameter)
        }
    }

    func testRepeatedFailureSuggestsRevert() {
        let history: [HistorySnapshot] = (0..<3).map { i in
            HistorySnapshot(
                beforeSettings: MachineSettings(grinder: 6 - i),
                afterSettings: MachineSettings(grinder: 5 - i),
                symptoms: [.tooBitter],
                primaryAdjustmentParameter: .grinder,
                outcome: .worse,
                drink: .flatWhite
            )
        }
        let rec = RulesEngine.evaluate(
            symptoms: [.tooBitter],
            current: MachineSettings(grinder: 3),
            milk: .devondaleFullCreamUHT,
            drink: .flatWhite,
            recentHistory: history
        )
        XCTAssertTrue(rec.suggestRevertToLastGood)
    }

    func testNoviceVsExpertRationaleDiffers() {
        let novice = RulesEngine.evaluate(
            symptoms: [.tooBitter],
            current: MachineSettings(grinder: 6),
            milk: .devondaleFullCreamUHT,
            drink: .flatWhite,
            novice: true
        )
        let expert = RulesEngine.evaluate(
            symptoms: [.tooBitter],
            current: MachineSettings(grinder: 6),
            milk: .devondaleFullCreamUHT,
            drink: .flatWhite,
            novice: false
        )
        XCTAssertNotEqual(novice.rationale, expert.rationale)
    }
}
