import Foundation

public struct MachineSettings: Codable, Hashable, Sendable {
    public var grinder: Int
    public var strength: Int
    public var volumeML: Int
    public var milkSeconds: Int
    public var temperature: TemperatureLevel

    public init(
        grinder: Int = 4,
        strength: Int = 7,
        volumeML: Int = 35,
        milkSeconds: Int = 18,
        temperature: TemperatureLevel = .normal
    ) {
        self.grinder = MachineRanges.clampGrinder(grinder)
        self.strength = MachineRanges.clampStrength(strength)
        self.volumeML = MachineRanges.clampVolume(volumeML)
        self.milkSeconds = MachineRanges.clampMilkDuration(milkSeconds)
        self.temperature = temperature
    }

    public static let defaultFlatWhite = MachineSettings(
        grinder: 4,
        strength: 7,
        volumeML: 35,
        milkSeconds: 18,
        temperature: .normal
    )

    public static let defaultCappuccino = MachineSettings(
        grinder: 4,
        strength: 7,
        volumeML: 35,
        milkSeconds: 22,
        temperature: .normal
    )

    public static func defaults(for drink: DrinkType) -> MachineSettings {
        switch drink {
        case .flatWhite: return .defaultFlatWhite
        case .cappuccino: return .defaultCappuccino
        case .latte: return MachineSettings(grinder: 4, strength: 7, volumeML: 40, milkSeconds: 28, temperature: .normal)
        case .longBlack: return MachineSettings(grinder: 4, strength: 8, volumeML: 110, milkSeconds: 3, temperature: .normal)
        case .espresso: return MachineSettings(grinder: 4, strength: 8, volumeML: 35, milkSeconds: 3, temperature: .normal)
        }
    }

    public func with(
        grinder: Int? = nil,
        strength: Int? = nil,
        volumeML: Int? = nil,
        milkSeconds: Int? = nil,
        temperature: TemperatureLevel? = nil
    ) -> MachineSettings {
        MachineSettings(
            grinder: grinder ?? self.grinder,
            strength: strength ?? self.strength,
            volumeML: volumeML ?? self.volumeML,
            milkSeconds: milkSeconds ?? self.milkSeconds,
            temperature: temperature ?? self.temperature
        )
    }
}
