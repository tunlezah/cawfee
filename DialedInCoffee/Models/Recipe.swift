import Foundation
import SwiftData

@Model
public final class Recipe {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var drinkRaw: String
    public var milkKindRaw: String
    public var grinder: Int
    public var strength: Int
    public var volumeML: Int
    public var milkSeconds: Int
    public var temperatureRaw: String
    public var isFavourite: Bool
    public var isLastGood: Bool
    public var createdAt: Date
    public var notes: String

    public var bean: BeanProfile?

    public init(
        id: UUID = UUID(),
        name: String,
        drink: DrinkType,
        milkKind: MilkKind = .devondaleFullCreamUHT,
        settings: MachineSettings,
        bean: BeanProfile? = nil,
        isFavourite: Bool = false,
        isLastGood: Bool = false,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.drinkRaw = drink.rawValue
        self.milkKindRaw = milkKind.rawValue
        self.grinder = settings.grinder
        self.strength = settings.strength
        self.volumeML = settings.volumeML
        self.milkSeconds = settings.milkSeconds
        self.temperatureRaw = settings.temperature.rawValue
        self.isFavourite = isFavourite
        self.isLastGood = isLastGood
        self.notes = notes
        self.createdAt = createdAt
        self.bean = bean
    }

    public var drink: DrinkType {
        get { DrinkType(rawValue: drinkRaw) ?? .cappuccino }
        set { drinkRaw = newValue.rawValue }
    }

    public var milkKind: MilkKind {
        get { MilkKind(rawValue: milkKindRaw) ?? .devondaleFullCreamUHT }
        set { milkKindRaw = newValue.rawValue }
    }

    public var temperature: TemperatureLevel {
        get { TemperatureLevel(rawValue: temperatureRaw) ?? .normal }
        set { temperatureRaw = newValue.rawValue }
    }

    public var settings: MachineSettings {
        get {
            MachineSettings(
                grinder: grinder,
                strength: strength,
                volumeML: volumeML,
                milkSeconds: milkSeconds,
                temperature: temperature
            )
        }
        set {
            grinder = newValue.grinder
            strength = newValue.strength
            volumeML = newValue.volumeML
            milkSeconds = newValue.milkSeconds
            temperatureRaw = newValue.temperature.rawValue
        }
    }
}
