import XCTest
@testable import DialedInCoffee

final class AdjustmentPlannerTests: XCTestCase {
    func testOverExtractionCoarsens() {
        let adj = AdjustmentPlanner.adjustment(
            for: .overExtraction,
            current: MachineSettings(grinder: 5),
            drink: .flatWhite,
            milk: .devondaleFullCreamUHT
        )
        XCTAssertNotNil(adj)
        XCTAssertEqual(adj?.parameter, .grinder)
        XCTAssertEqual(adj?.fromInt, 5)
        XCTAssertEqual(adj?.toInt, 4)
    }

    func testUnderExtractionFineGrind() {
        let adj = AdjustmentPlanner.adjustment(
            for: .underExtraction,
            current: MachineSettings(grinder: 2),
            drink: .flatWhite,
            milk: .devondaleFullCreamUHT
        )
        XCTAssertEqual(adj?.parameter, .grinder)
        XCTAssertEqual(adj?.toInt, 3)
    }

    func testGrinderClampedAtLowerBound() {
        let adj = AdjustmentPlanner.adjustment(
            for: .overExtraction,
            current: MachineSettings(grinder: 1),
            drink: .flatWhite,
            milk: .devondaleFullCreamUHT
        )
        // Already at floor; coarsening returns nil (no actionable change).
        XCTAssertNil(adj)
    }

    func testExcessiveHeatCools() {
        let adj = AdjustmentPlanner.adjustment(
            for: .excessiveHeat,
            current: MachineSettings(temperature: .high),
            drink: .flatWhite,
            milk: .devondaleFullCreamUHT
        )
        XCTAssertEqual(adj?.parameter, .temperature)
        XCTAssertEqual(adj?.toTemp, .normal)
    }

    func testAustralianOverrideOnHighTempMilkDrink() {
        let adj = AdjustmentPlanner.australianBiasOverride(
            current: MachineSettings(temperature: .high),
            drink: .flatWhite,
            symptoms: [.tooHot]
        )
        XCTAssertNotNil(adj)
        XCTAssertEqual(adj?.parameter, .temperature)
        XCTAssertEqual(adj?.toTemp, .normal)
    }

    func testAustralianOverrideSkippedForLongBlack() {
        let adj = AdjustmentPlanner.australianBiasOverride(
            current: MachineSettings(temperature: .high),
            drink: .longBlack,
            symptoms: [.tooHot]
        )
        XCTAssertNil(adj)
    }

    func testDifferentParameterCheck() {
        let a = Adjustment(parameter: .grinder, fromInt: 5, toInt: 4, reason: "", expectedOutcome: "")
        let b = Adjustment(parameter: .strength, fromInt: 7, toInt: 8, reason: "", expectedOutcome: "")
        let c = Adjustment(parameter: .grinder, fromInt: 4, toInt: 3, reason: "", expectedOutcome: "")
        XCTAssertTrue(AdjustmentPlanner.differentParameter(a, from: b))
        XCTAssertFalse(AdjustmentPlanner.differentParameter(a, from: c))
    }
}
