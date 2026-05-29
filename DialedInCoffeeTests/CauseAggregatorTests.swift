import XCTest
@testable import DialedInCoffee

final class CauseAggregatorTests: XCTestCase {
    func testLogOddsMonotonic() {
        let single = CauseAggregator.aggregate(
            symptoms: [.tooBitter],
            current: SampleData.baselineFlatWhite,
            drink: .flatWhite,
            milk: .devondaleFullCreamUHT,
            bean: SampleData.bean
        )
        let multi = CauseAggregator.aggregate(
            symptoms: [.tooBitter, .tooBurnt],
            current: SampleData.baselineFlatWhite.with(temperature: .high),
            drink: .flatWhite,
            milk: .devondaleFullCreamUHT,
            bean: SampleData.bean
        )
        guard
            let single1 = single.first(where: { $0.cause == .overExtraction || $0.cause == .excessiveHeat }),
            let multi1 = multi.first
        else {
            return XCTFail("Expected at least one aggregate cause")
        }
        XCTAssertGreaterThanOrEqual(multi1.confidence, single1.confidence - 0.0001)
        XCTAssertLessThanOrEqual(multi1.confidence, 1.0)
    }

    func testAggregateEmptyForNoSymptoms() {
        let result = CauseAggregator.aggregate(
            symptoms: [],
            current: SampleData.baselineFlatWhite,
            drink: .flatWhite,
            milk: .devondaleFullCreamUHT,
            bean: nil
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testConfidenceBounded() {
        let result = CauseAggregator.aggregate(
            symptoms: Symptom.allCases,
            current: SampleData.baselineFlatWhite,
            drink: .flatWhite,
            milk: .devondaleFullCreamUHT,
            bean: SampleData.bean
        )
        XCTAssertFalse(result.isEmpty)
        for c in result {
            XCTAssertGreaterThanOrEqual(c.confidence, 0)
            XCTAssertLessThanOrEqual(c.confidence, 1)
        }
    }
}
