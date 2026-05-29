import Foundation
@testable import DialedInCoffee

enum SampleData {
    static let baselineFlatWhite = MachineSettings(
        grinder: 4, strength: 7, volumeML: 35, milkSeconds: 18, temperature: .normal
    )

    static let bean = BeanSnapshot(
        id: "ona-maple",
        name: "Maple 🥛",
        roaster: "ONA Coffee",
        roastLevel: .medium,
        milkFriendly: true,
        flavourNotes: ["caramel", "biscuit", "nut", "spice"],
        recommendedSettings: baselineFlatWhite
    )
}
