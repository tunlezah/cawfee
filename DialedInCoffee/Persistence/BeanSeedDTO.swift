import Foundation

public struct BeanSeedSettingsDTO: Codable, Hashable, Sendable {
    public var grinder: Int
    public var strength: Int
    public var volume: Int
    public var milkTime: Int
    public var temp: String
}

public struct BeanSeedDTO: Codable, Hashable, Sendable, Identifiable {
    public var id: String { slug }
    public var slug: String
    public var name: String
    public var roaster: String
    public var roastLevel: String
    public var milkFriendly: Bool
    public var flavourNotes: [String]
    public var recommendedSettings: BeanSeedSettingsDTO
    public var notes: String?
    public var origin: String?
    public var process: String?
    public var availability: String?

    public func toMachineSettings() -> MachineSettings {
        MachineSettings(
            grinder: recommendedSettings.grinder,
            strength: recommendedSettings.strength,
            volumeML: recommendedSettings.volume,
            milkSeconds: recommendedSettings.milkTime,
            temperature: TemperatureLevel(rawValue: recommendedSettings.temp) ?? .normal
        )
    }

    public func toRoastLevel() -> RoastLevel {
        RoastLevel(rawValue: roastLevel) ?? .medium
    }
}

public struct BeanSeedFile: Codable, Sendable {
    public var beans: [BeanSeedDTO]
}
