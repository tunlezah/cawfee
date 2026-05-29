import Foundation

public enum AdjustmentOutcome: String, Codable, CaseIterable, Hashable, Sendable {
    case unknown
    case better
    case worse
    case good

    public var displayName: String {
        switch self {
        case .unknown: return "Not rated"
        case .better: return "Better"
        case .worse: return "Worse"
        case .good: return "Good (last good)"
        }
    }
}

public struct HistorySnapshot: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var date: Date
    public var beforeSettings: MachineSettings
    public var afterSettings: MachineSettings
    public var symptoms: [Symptom]
    public var primaryAdjustmentParameter: AdjustmentParameter
    public var outcome: AdjustmentOutcome
    public var beanName: String?
    public var drink: DrinkType

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        beforeSettings: MachineSettings,
        afterSettings: MachineSettings,
        symptoms: [Symptom],
        primaryAdjustmentParameter: AdjustmentParameter,
        outcome: AdjustmentOutcome = .unknown,
        beanName: String? = nil,
        drink: DrinkType
    ) {
        self.id = id
        self.date = date
        self.beforeSettings = beforeSettings
        self.afterSettings = afterSettings
        self.symptoms = symptoms
        self.primaryAdjustmentParameter = primaryAdjustmentParameter
        self.outcome = outcome
        self.beanName = beanName
        self.drink = drink
    }
}
