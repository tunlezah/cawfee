import Foundation
import SwiftData

@MainActor
@Observable
public final class FixMyCoffeeViewModel {
    public var drink: DrinkType = .cappuccino
    public var milkKind: MilkKind = .devondaleFullCreamUHT
    public var settings: MachineSettings = .defaultCappuccino
    public var selectedSymptoms: Set<Symptom> = []
    public var selectedBeanSlug: String? = nil
    public var recommendation: Recommendation? = nil
    public var lastEvaluated: Date? = nil

    public init() {}

    public func toggle(_ symptom: Symptom) {
        if selectedSymptoms.contains(symptom) {
            selectedSymptoms.remove(symptom)
        } else {
            selectedSymptoms.insert(symptom)
        }
    }

    public func clearSymptoms() {
        selectedSymptoms.removeAll()
    }

    public func loadDefaults(from prefs: UserPreferences?) {
        guard let prefs else { return }
        drink = prefs.defaultDrink
        milkKind = prefs.defaultMilkKind
        settings = MachineSettings.defaults(for: drink)
    }

    public func resetSettingsForDrink() {
        settings = MachineSettings.defaults(for: drink)
    }

    public func evaluate(
        beans: [BeanProfile],
        history: [AdjustmentHistoryEntry],
        novice: Bool
    ) {
        let bean = beans.first(where: { $0.slug == selectedBeanSlug })?.snapshot()
        let snapshots = history.map { $0.snapshot() }
        let milk = Milk.canonical(for: milkKind)
        let symptoms = Array(selectedSymptoms)
        recommendation = RulesEngine.evaluate(
            symptoms: symptoms,
            current: settings,
            milk: milk,
            drink: drink,
            bean: bean,
            recentHistory: snapshots,
            novice: novice
        )
        lastEvaluated = Date()
    }

    public func applyAndLog(
        primary: Adjustment,
        secondary: Adjustment?,
        context: ModelContext,
        beans: [BeanProfile]
    ) {
        let before = settings
        var after = primary.apply(to: before)
        if let secondary {
            after = secondary.apply(to: after)
        }
        let beanName = beans.first(where: { $0.slug == selectedBeanSlug })?.name
        let entry = AdjustmentHistoryEntry(
            drink: drink,
            beanName: beanName,
            symptoms: Array(selectedSymptoms),
            before: before,
            after: after,
            primaryParameter: primary.parameter,
            rationale: recommendation?.rationale ?? "",
            confidence: recommendation?.confidence ?? 0
        )
        context.insert(entry)
        try? context.save()
        settings = after
    }
}
