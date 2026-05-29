import Foundation
import OSLog

public struct RulesEngine {
    private static let log = Logger(subsystem: "coffee.dialedin", category: "RulesEngine")

    /// Secondary cause must reach this confidence and target a different parameter to be emitted.
    public static let secondaryConfidenceThreshold: Double = 0.6

    public static func evaluate(
        symptoms: [Symptom],
        current: MachineSettings,
        milk: Milk,
        drink: DrinkType,
        bean: BeanSnapshot? = nil,
        recentHistory: [HistorySnapshot] = [],
        novice: Bool = true
    ) -> Recommendation {
        log.debug("evaluate symptoms=\(symptoms.map(\.rawValue).joined(separator: ","), privacy: .public) drink=\(drink.rawValue, privacy: .public)")

        // 0. Empty input — nothing to do.
        guard !symptoms.isEmpty else {
            return Recommendation(rationale: "Pick at least one symptom to get a recommendation.")
        }

        // 1. Detect repeated failure → propose revert to last good.
        if LearningHeuristics.detectRepeatedFailure(history: recentHistory) {
            let lg = LearningHeuristics.lastGood(history: recentHistory)
            let rationale: String = {
                if lg != nil {
                    return "You've changed the same setting in the same direction several times without success. Consider going back to your last good recipe and changing something else."
                } else {
                    return "You've been pushing the same setting in one direction. Try the opposite direction or change a different setting instead."
                }
            }()
            log.debug("repeated failure detected; suggesting revert")
            return Recommendation(
                primary: nil,
                secondary: nil,
                topCause: nil,
                confidence: 0.8,
                rationale: rationale,
                contributions: [],
                alternativeCauses: [],
                suggestRevertToLastGood: true
            )
        }

        // 2. Aggregate causes from rules.
        let aggregated = CauseAggregator.aggregate(
            symptoms: symptoms,
            current: current,
            drink: drink,
            milk: milk,
            bean: bean
        )
        guard let top = aggregated.first else {
            return Recommendation(rationale: "No matching rules. Try describing the cup differently.")
        }

        // 3. Plan primary adjustment (with Australian-style override for milk drinks).
        var primary: Adjustment? = AdjustmentPlanner.australianBiasOverride(
            current: current,
            drink: drink,
            symptoms: symptoms
        )

        if primary == nil {
            primary = AdjustmentPlanner.adjustment(
                for: top.cause,
                current: current,
                drink: drink,
                milk: milk
            )
        }

        // 4. Plan optional secondary — must be a different parameter and clear above threshold.
        var secondary: Adjustment? = nil
        if let primary,
           let runnerUp = aggregated.dropFirst().first(where: { $0.confidence >= secondaryConfidenceThreshold }),
           let candidate = AdjustmentPlanner.adjustment(
                for: runnerUp.cause,
                current: current,
                drink: drink,
                milk: milk
           ),
           AdjustmentPlanner.differentParameter(candidate, from: primary)
        {
            secondary = candidate
        }

        // 5. Build contributions for Expert mode.
        let contributions = aggregated.map {
            CauseContribution(cause: $0.cause, confidence: $0.confidence, ruleIDs: $0.contributingRuleIDs)
        }
        let alternatives = Array(contributions.dropFirst().prefix(3))

        let rationale = ExplanationBuilder.rationale(
            topCause: top.cause,
            symptoms: symptoms,
            novice: novice
        )

        return Recommendation(
            primary: primary,
            secondary: secondary,
            topCause: top.cause,
            confidence: top.confidence,
            rationale: rationale,
            contributions: contributions,
            alternativeCauses: alternatives,
            suggestRevertToLastGood: false
        )
    }
}
