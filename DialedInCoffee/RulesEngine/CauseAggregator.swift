import Foundation

public struct AggregatedCause: Hashable, Sendable {
    public let cause: Cause
    public let confidence: Double          // 0...1
    public let contributingRuleIDs: [String]
}

public enum CauseAggregator {
    /// Combine rule weights into per-cause confidence via log-odds:
    ///   combined = 1 - Π(1 - wᵢ)
    /// This is monotonic, caps at 1.0, and handles overlapping evidence sanely.
    public static func aggregate(
        symptoms: [Symptom],
        current: MachineSettings,
        drink: DrinkType,
        milk: Milk,
        bean: BeanSnapshot?
    ) -> [AggregatedCause] {
        let triggered = RuleSet.rules(triggeredBy: symptoms)
        guard !triggered.isEmpty else { return [] }

        var byCause: [Cause: (Double, [String])] = [:]   // (productOfComplements, ruleIDs)

        for rule in triggered {
            let w = rule.effectiveWeight(
                current: current,
                drink: drink,
                milk: milk,
                bean: bean
            )
            let clamped = min(max(w, 0), 1)
            let complement = 1 - clamped
            let (existingComplementProduct, existingIDs) = byCause[rule.cause] ?? (1.0, [])
            byCause[rule.cause] = (existingComplementProduct * complement, existingIDs + [rule.id])
        }

        let aggregated = byCause.map { (cause, value) in
            AggregatedCause(
                cause: cause,
                confidence: min(1.0, max(0.0, 1.0 - value.0)),
                contributingRuleIDs: value.1
            )
        }

        return aggregated.sorted { $0.confidence > $1.confidence }
    }
}
