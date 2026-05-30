import XCTest
@testable import DialedInCoffee

/// Validates the Swift port of the Jura protocol against the spec's executed vectors
/// (JURA_E8_BLUETOOTH_SPECIFICATION.md §6.5) — the same vectors the Kotlin `:protocol`
/// module is tested against, keeping the two platforms in lock-step.
final class JuraProtocolTests: XCTestCase {

    private func hex(_ s: String) -> [UInt8] {
        let clean = s.filter { !$0.isWhitespace }
        var out = [UInt8]()
        var i = clean.startIndex
        while i < clean.endIndex {
            let j = clean.index(i, offsetBy: 2)
            out.append(UInt8(clean[i..<j], radix: 16)!)
            i = j
        }
        return out
    }

    private func hexString(_ b: [UInt8]) -> String { b.map { String(format: "%02x", $0) }.joined() }

    func testHeartbeatVector() {
        XCTAssertEqual(hexString(JuraCommands.heartbeat(key: 0x2A)), "77656d")
    }

    func testBrewVectorIsInvolutive() {
        let cipher = hex("77c23dd05e81d3dba32bf898a4a3faab45fd")
        let plain = "2a280006120000010001090000000000062a"
        XCTAssertEqual(hexString(JuraCipher.encDec(cipher, key: 0x2A)), plain)
        XCTAssertEqual(hexString(JuraCipher.encDec(hex(plain), key: 0x2A)), hexString(cipher))
    }

    func testCappuccinoVector() {
        let cipher = hex("77ea3dd38981dadba32bfa98a4a3faab45fd")
        XCTAssertEqual(hexString(JuraCipher.encDec(cipher, key: 0x2A)), "2a0400080c000e010001000000000000062a")
    }

    func testDecodedByteZeroEqualsKey() {
        for key in [0x00, 0x2A, 0x7F, 0xAB, 0xFF] {
            let frame = (0..<18).map { UInt8($0) }
            let enc = JuraCipher.encrypt(frame, key: key)
            XCTAssertEqual(Int(JuraCipher.decrypt(enc, key: key)[0]), key)
        }
    }

    func testStartFrameOffsets() {
        guard let coffee = JuraMachineCatalog.e8.product(code: 0x03) else { return XCTFail() }
        let frame = JuraCommands.buildStartFrame(
            product: coffee,
            params: JuraBrewParameters(strength: 6, waterMl: 100, temperature: .normal),
            key: 0x2A)
        XCTAssertEqual(frame[1], 0x03)
        XCTAssertEqual(frame[3], 6)
        XCTAssertEqual(frame[4], 20) // 100ml / 5
        XCTAssertEqual(frame[7], 1)
        XCTAssertEqual(frame[17], 0x2A)
    }

    func testStatusParserWalksBits() {
        let status = JuraParsers.parseStatus(decoded: hex("00 40 04"), model: JuraMachineCatalog.e8)
        XCTAssertTrue(status.needsWater)
        XCTAssertTrue(status.coffeeReady)
    }

    func testStatisticsParser() {
        let stats = JuraParsers.parseStatistics(decoded: hex("00014E 000000 000027 00FFFF"))
        XCTAssertEqual(stats.total, 334)
        XCTAssertEqual(stats.count(forProductCode: 2), 39)
        XCTAssertEqual(stats.count(forProductCode: 3), 0)
    }
}
