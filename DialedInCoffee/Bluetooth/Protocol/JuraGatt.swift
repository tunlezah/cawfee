import CoreBluetooth
import Foundation

/// GATT service/characteristic UUIDs and timing constants (spec §5, §7, §20). Mirrors
/// the Kotlin `JuraGatt`.
enum JuraGatt {
    static let companyId: UInt16 = 0x00AB
    static let advertisedName = "TT214H BlueFrog"
    static let modelIdE8 = 15057

    private static let suffix = "-AB2E-2548-C435-08C300000710"

    static let serviceControl = CBUUID(string: "5A401523\(suffix)")
    static let serviceUart = CBUUID(string: "5A401623\(suffix)")

    static let charAboutMachine = CBUUID(string: "5A401531\(suffix)")
    static let charMachineStatus = CBUUID(string: "5A401524\(suffix)")
    static let charStartProduct = CBUUID(string: "5A401525\(suffix)")
    static let charProductProgress = CBUUID(string: "5A401527\(suffix)")
    static let charPMode = CBUUID(string: "5A401529\(suffix)")
    static let charBarista = CBUUID(string: "5A401530\(suffix)")
    static let charStatisticsCmd = CBUUID(string: "5A401533\(suffix)")
    static let charStatisticsData = CBUUID(string: "5A401534\(suffix)")

    enum Timing {
        static let idleDisconnect: TimeInterval = 20
        static let heartbeatInterval: TimeInterval = 9
        static let activeWindow: TimeInterval = 120
        static let statsInitialWait: TimeInterval = 1.2
        static let statsPollInterval: TimeInterval = 0.8
        static let statsMaxPolls = 30
        static let connectRetryDelay: TimeInterval = 1
        static let connectMaxRetries = 3
    }
}
