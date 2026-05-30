import Foundation

/// Parsed advertisement (spec §4.2). Mirrors the Kotlin `JuraAdvertisement`.
struct JuraAdvertisement {
    let key: Int
    let blueFrogMajor: Int
    let blueFrogMinor: Int
    let modelId: Int
    let machineNumber: Int
    let serialNumber: Int
    let statusBits: Int

    var isValid: Bool { modelId != 0 }
    var hasMasterPin: Bool { (statusBits & 0x40) != 0 }
    var isE8: Bool { modelId == 15057 }
}

/// A single active alert bit.
struct JuraAlert: Identifiable {
    let bit: Int
    let name: String
    var id: Int { bit }
    var isBlocking: Bool { [0, 1, 2, 3, 4, 5, 6, 7, 10].contains(bit) }
}

/// Decoded machine status (spec §9).
struct JuraMachineStatus {
    let alerts: [JuraAlert]
    private func has(_ bit: Int) -> Bool { alerts.contains { $0.bit == bit } }

    var needsWater: Bool { has(1) }
    var noBeans: Bool { has(10) }
    var coffeeReady: Bool { has(13) }
    var needsDescale: Bool { has(33) }
    var needsCleaning: Bool { has(34) }
    var needsFilter: Bool { has(32) }
    var isReadyToBrew: Bool { !alerts.contains { $0.isBlocking } }
}

/// Decoded statistics (spec §10).
struct JuraStatistics {
    let counts: [Int]
    var total: Int { counts.first ?? 0 }
    func count(forProductCode code: Int) -> Int { code < counts.count ? counts[code] : 0 }
}

/// Pure parsing of decoded payloads. Mirrors the Kotlin parsers.
enum JuraParsers {

    static func parseAdvertisement(_ data: [UInt8]) -> JuraAdvertisement? {
        guard data.count >= 16 else { return nil }
        func le16(_ o: Int) -> Int { Int(data[o]) | (Int(data[o + 1]) << 8) }
        return JuraAdvertisement(
            key: Int(data[0]),
            blueFrogMajor: Int(data[1]),
            blueFrogMinor: Int(data[2]),
            modelId: le16(4),
            machineNumber: le16(6),
            serialNumber: le16(8),
            statusBits: Int(data[15])
        )
    }

    /// Walk the decoded status bitfield MSB-first from byte 1 (spec §9).
    static func parseStatus(decoded: [UInt8], model: JuraMachineModel) -> JuraMachineStatus {
        var alerts: [JuraAlert] = []
        let totalBits = (decoded.count - 1) * 8
        guard totalBits > 0 else { return JuraMachineStatus(alerts: []) }
        for i in 0..<totalBits {
            let byteIndex = (i >> 3) + 1
            let bitInByte = 7 - (i & 0b111)
            if (Int(decoded[byteIndex]) >> bitInByte) & 1 == 1 {
                alerts.append(JuraAlert(bit: i, name: model.alertNames[i] ?? "Unknown alert \(i)"))
            }
        }
        return JuraMachineStatus(alerts: alerts)
    }

    static func parseStatistics(decoded: [UInt8]) -> JuraStatistics {
        var counts: [Int] = []
        var i = 0
        while i + 3 <= decoded.count {
            let raw = (Int(decoded[i]) << 16) | (Int(decoded[i + 1]) << 8) | Int(decoded[i + 2])
            counts.append((raw == 0xFFFF || raw > 1_000_000) ? 0 : raw)
            i += 3
        }
        return JuraStatistics(counts: counts)
    }

    /// Statistics readiness check (spec §8.4).
    static func statisticsReady(decoded: [UInt8]) -> Bool {
        guard !decoded.isEmpty else { return false }
        if Int(decoded[0]) == 0x0E { return false }
        if decoded.count > 1 && Int(decoded[1]) == 0xE1 { return false }
        return true
    }
}
