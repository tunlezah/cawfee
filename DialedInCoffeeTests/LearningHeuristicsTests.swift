import XCTest
@testable import DialedInCoffee

final class LearningHeuristicsTests: XCTestCase {
    func testDetectRepeatedFailureRequiresThree() {
        let history: [HistorySnapshot] = (1...2).map { i in
            HistorySnapshot(
                beforeSettings: MachineSettings(grinder: 5 - i + 1),
                afterSettings: MachineSettings(grinder: 5 - i),
                symptoms: [.tooBitter],
                primaryAdjustmentParameter: .grinder,
                outcome: .unknown,
                drink: .flatWhite
            )
        }
        XCTAssertFalse(LearningHeuristics.detectRepeatedFailure(history: history))
    }

    func testDetectRepeatedFailureWhenChasingSameDirection() {
        let history: [HistorySnapshot] = [
            HistorySnapshot(
                beforeSettings: MachineSettings(grinder: 6),
                afterSettings: MachineSettings(grinder: 5),
                symptoms: [.tooBitter],
                primaryAdjustmentParameter: .grinder,
                outcome: .worse,
                drink: .flatWhite
            ),
            HistorySnapshot(
                beforeSettings: MachineSettings(grinder: 5),
                afterSettings: MachineSettings(grinder: 4),
                symptoms: [.tooBitter],
                primaryAdjustmentParameter: .grinder,
                outcome: .worse,
                drink: .flatWhite
            ),
            HistorySnapshot(
                beforeSettings: MachineSettings(grinder: 4),
                afterSettings: MachineSettings(grinder: 3),
                symptoms: [.tooBitter],
                primaryAdjustmentParameter: .grinder,
                outcome: .unknown,
                drink: .flatWhite
            ),
        ]
        XCTAssertTrue(LearningHeuristics.detectRepeatedFailure(history: history))
    }

    func testRecentGoodResetsDetection() {
        let history: [HistorySnapshot] = [
            HistorySnapshot(
                beforeSettings: MachineSettings(grinder: 6),
                afterSettings: MachineSettings(grinder: 5),
                symptoms: [.tooBitter],
                primaryAdjustmentParameter: .grinder,
                outcome: .good,
                drink: .flatWhite
            ),
            HistorySnapshot(
                beforeSettings: MachineSettings(grinder: 5),
                afterSettings: MachineSettings(grinder: 4),
                symptoms: [.tooBitter],
                primaryAdjustmentParameter: .grinder,
                outcome: .worse,
                drink: .flatWhite
            ),
            HistorySnapshot(
                beforeSettings: MachineSettings(grinder: 4),
                afterSettings: MachineSettings(grinder: 3),
                symptoms: [.tooBitter],
                primaryAdjustmentParameter: .grinder,
                outcome: .worse,
                drink: .flatWhite
            ),
        ]
        XCTAssertFalse(LearningHeuristics.detectRepeatedFailure(history: history))
    }

    func testLastGoodFindsMostRecent() {
        let history: [HistorySnapshot] = [
            HistorySnapshot(
                date: Date(timeIntervalSince1970: 1000),
                beforeSettings: MachineSettings(),
                afterSettings: MachineSettings(),
                symptoms: [],
                primaryAdjustmentParameter: .grinder,
                outcome: .good,
                drink: .flatWhite
            ),
            HistorySnapshot(
                date: Date(timeIntervalSince1970: 2000),
                beforeSettings: MachineSettings(),
                afterSettings: MachineSettings(),
                symptoms: [],
                primaryAdjustmentParameter: .grinder,
                outcome: .worse,
                drink: .flatWhite
            ),
        ]
        let lg = LearningHeuristics.lastGood(history: history)
        XCTAssertEqual(lg?.date.timeIntervalSince1970, 1000)
    }
}
