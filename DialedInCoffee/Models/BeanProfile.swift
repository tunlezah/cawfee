import Foundation
import SwiftData

@Model
public final class BeanProfile {
    @Attribute(.unique) public var slug: String
    public var name: String
    public var roaster: String
    public var roastLevelRaw: String
    public var milkFriendly: Bool
    public var flavourNotes: [String]
    public var notes: String

    // Stored recommended settings (denormalized for simplicity).
    public var recGrinder: Int
    public var recStrength: Int
    public var recVolumeML: Int
    public var recMilkSeconds: Int
    public var recTemperatureRaw: String

    public var createdAt: Date
    public var isSeeded: Bool

    /// Date the bag was roasted. Optional — user-entered, drives the freshness countdown.
    public var roastDate: Date?

    /// Date the bag was opened. Optional — user-entered.
    public var openedDate: Date?

    /// The grinder setting currently dialled in for this bag (machine-specific
    /// scale). Optional — lets the user remember where they landed per bag.
    public var currentGrindSetting: Int?

    @Relationship(deleteRule: .cascade, inverse: \Recipe.bean)
    public var recipes: [Recipe] = []

    public init(
        slug: String,
        name: String,
        roaster: String,
        roastLevel: RoastLevel,
        milkFriendly: Bool,
        flavourNotes: [String],
        recommendedSettings: MachineSettings,
        notes: String = "",
        isSeeded: Bool = false,
        createdAt: Date = Date(),
        roastDate: Date? = nil,
        openedDate: Date? = nil,
        currentGrindSetting: Int? = nil
    ) {
        self.slug = slug
        self.name = name
        self.roaster = roaster
        self.roastLevelRaw = roastLevel.rawValue
        self.milkFriendly = milkFriendly
        self.flavourNotes = flavourNotes
        self.notes = notes
        self.recGrinder = recommendedSettings.grinder
        self.recStrength = recommendedSettings.strength
        self.recVolumeML = recommendedSettings.volumeML
        self.recMilkSeconds = recommendedSettings.milkSeconds
        self.recTemperatureRaw = recommendedSettings.temperature.rawValue
        self.createdAt = createdAt
        self.isSeeded = isSeeded
        self.roastDate = roastDate
        self.openedDate = openedDate
        self.currentGrindSetting = currentGrindSetting
    }

    public var roastLevel: RoastLevel {
        get { RoastLevel(rawValue: roastLevelRaw) ?? .medium }
        set { roastLevelRaw = newValue.rawValue }
    }

    public var recommendedSettings: MachineSettings {
        get {
            MachineSettings(
                grinder: recGrinder,
                strength: recStrength,
                volumeML: recVolumeML,
                milkSeconds: recMilkSeconds,
                temperature: TemperatureLevel(rawValue: recTemperatureRaw) ?? .normal
            )
        }
        set {
            recGrinder = newValue.grinder
            recStrength = newValue.strength
            recVolumeML = newValue.volumeML
            recMilkSeconds = newValue.milkSeconds
            recTemperatureRaw = newValue.temperature.rawValue
        }
    }

    public func snapshot() -> BeanSnapshot {
        BeanSnapshot(
            id: slug,
            name: name,
            roaster: roaster,
            roastLevel: roastLevel,
            milkFriendly: milkFriendly,
            flavourNotes: flavourNotes,
            recommendedSettings: recommendedSettings
        )
    }
}
