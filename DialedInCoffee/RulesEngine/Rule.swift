import Foundation

public struct Rule: Identifiable, Hashable, Sendable {
    public let id: String
    public let trigger: Symptom
    public let cause: Cause
    public let baseWeight: Double           // 0...1 base contribution when trigger fires
    public let conditions: [Condition]      // ALL must be satisfied to multiply contribution
    public let conditionMultiplier: Double  // applied when conditions match (default 1.0)
    public let rationale: String

    public init(
        id: String,
        trigger: Symptom,
        cause: Cause,
        baseWeight: Double,
        conditions: [Condition] = [],
        conditionMultiplier: Double = 1.0,
        rationale: String
    ) {
        self.id = id
        self.trigger = trigger
        self.cause = cause
        self.baseWeight = baseWeight
        self.conditions = conditions
        self.conditionMultiplier = conditionMultiplier
        self.rationale = rationale
    }

    public func effectiveWeight(
        current: MachineSettings,
        drink: DrinkType,
        milk: Milk,
        bean: BeanSnapshot?
    ) -> Double {
        if conditions.isEmpty { return baseWeight }
        let allMatch = conditions.allSatisfy {
            $0.isSatisfied(current: current, drink: drink, milk: milk, bean: bean)
        }
        return allMatch ? min(1.0, baseWeight * conditionMultiplier) : baseWeight
    }
}
