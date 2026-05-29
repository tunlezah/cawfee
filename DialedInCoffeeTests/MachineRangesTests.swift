import XCTest
@testable import DialedInCoffee

final class MachineRangesTests: XCTestCase {
    func testClampGrinder() {
        XCTAssertEqual(MachineRanges.clampGrinder(0), 1)
        XCTAssertEqual(MachineRanges.clampGrinder(4), 4)
        XCTAssertEqual(MachineRanges.clampGrinder(99), 7)
    }
    func testClampStrength() {
        XCTAssertEqual(MachineRanges.clampStrength(-1), 1)
        XCTAssertEqual(MachineRanges.clampStrength(10), 10)
        XCTAssertEqual(MachineRanges.clampStrength(100), 10)
    }
    func testClampVolume() {
        XCTAssertEqual(MachineRanges.clampVolume(10), 25)
        XCTAssertEqual(MachineRanges.clampVolume(300), 240)
    }
    func testClampMilkDuration() {
        XCTAssertEqual(MachineRanges.clampMilkDuration(0), 3)
        XCTAssertEqual(MachineRanges.clampMilkDuration(500), 120)
    }
    func testMachineSettingsInitClamps() {
        let s = MachineSettings(grinder: 12, strength: -3, volumeML: 5, milkSeconds: 200, temperature: .high)
        XCTAssertEqual(s.grinder, 7)
        XCTAssertEqual(s.strength, 1)
        XCTAssertEqual(s.volumeML, 25)
        XCTAssertEqual(s.milkSeconds, 120)
        XCTAssertEqual(s.temperature, .high)
    }
}
