import Foundation
import SwiftData

@Model
public final class AdjustmentHistoryEntry {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var drinkRaw: String
    public var beanName: String?
    public var symptomsRaw: [String]

    // Before snapshot
    public var beforeGrinder: Int
    public var beforeStrength: Int
    public var beforeVolumeML: Int
    public var beforeMilkSeconds: Int
    public var beforeTemperatureRaw: String

    // After snapshot
    public var afterGrinder: Int
    public var afterStrength: Int
    public var afterVolumeML: Int
    public var afterMilkSeconds: Int
    public var afterTemperatureRaw: String

    public var primaryParameterRaw: String
    public var outcomeRaw: String
    public var rationale: String
    public var confidence: Double

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        drink: DrinkType,
        beanName: String? = nil,
        symptoms: [Symptom],
        before: MachineSettings,
        after: MachineSettings,
        primaryParameter: AdjustmentParameter,
        outcome: AdjustmentOutcome = .unknown,
        rationale: String = "",
        confidence: Double = 0
    ) {
        self.id = id
        self.date = date
        self.drinkRaw = drink.rawValue
        self.beanName = beanName
        self.symptomsRaw = symptoms.map(\.rawValue)
        self.beforeGrinder = before.grinder
        self.beforeStrength = before.strength
        self.beforeVolumeML = before.volumeML
        self.beforeMilkSeconds = before.milkSeconds
        self.beforeTemperatureRaw = before.temperature.rawValue
        self.afterGrinder = after.grinder
        self.afterStrength = after.strength
        self.afterVolumeML = after.volumeML
        self.afterMilkSeconds = after.milkSeconds
        self.afterTemperatureRaw = after.temperature.rawValue
        self.primaryParameterRaw = primaryParameter.rawValue
        self.outcomeRaw = outcome.rawValue
        self.rationale = rationale
        self.confidence = confidence
    }

    public var drink: DrinkType { DrinkType(rawValue: drinkRaw) ?? .cappuccino }
    public var symptoms: [Symptom] { symptomsRaw.compactMap(Symptom.init(rawValue:)) }
    public var primaryParameter: AdjustmentParameter {
        AdjustmentParameter(rawValue: primaryParameterRaw) ?? .grinder
    }
    public var outcome: AdjustmentOutcome {
        get { AdjustmentOutcome(rawValue: outcomeRaw) ?? .unknown }
        set { outcomeRaw = newValue.rawValue }
    }
    public var beforeSettings: MachineSettings {
        MachineSettings(
            grinder: beforeGrinder,
            strength: beforeStrength,
            volumeML: beforeVolumeML,
            milkSeconds: beforeMilkSeconds,
            temperature: TemperatureLevel(rawValue: beforeTemperatureRaw) ?? .normal
        )
    }
    public var afterSettings: MachineSettings {
        MachineSettings(
            grinder: afterGrinder,
            strength: afterStrength,
            volumeML: afterVolumeML,
            milkSeconds: afterMilkSeconds,
            temperature: TemperatureLevel(rawValue: afterTemperatureRaw) ?? .normal
        )
    }

    public func snapshot() -> HistorySnapshot {
        HistorySnapshot(
            id: id,
            date: date,
            beforeSettings: beforeSettings,
            afterSettings: afterSettings,
            symptoms: symptoms,
            primaryAdjustmentParameter: primaryParameter,
            outcome: outcome,
            beanName: beanName,
            drink: drink
        )
    }
}
