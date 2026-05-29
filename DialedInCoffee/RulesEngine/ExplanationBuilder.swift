import Foundation

public enum ExplanationBuilder {
    public static func rationale(
        topCause: Cause?,
        symptoms: [Symptom],
        novice: Bool
    ) -> String {
        guard let cause = topCause, !symptoms.isEmpty else {
            return "Couldn't isolate a clear cause from these symptoms. Try a small tweak and re-taste."
        }
        let symptomList = symptoms.map { $0.displayName.lowercased() }
        let symptomPhrase: String
        switch symptomList.count {
        case 1: symptomPhrase = symptomList[0]
        case 2: symptomPhrase = symptomList.joined(separator: " and ")
        default:
            let head = symptomList.dropLast().joined(separator: ", ")
            let tail = symptomList.last ?? ""
            symptomPhrase = "\(head), and \(tail)"
        }

        if novice {
            return "You said the cup was \(symptomPhrase). That usually means \(cause.displayName.lowercased())."
        } else {
            return "Symptoms (\(symptomPhrase)) point to \(cause.displayName.lowercased()). \(cause.plainExplanation)"
        }
    }

    public static func ruleSummary(_ rule: Rule) -> String {
        "\(rule.id) • \(rule.trigger.displayName) → \(rule.cause.displayName) (w=\(String(format: "%.2f", rule.baseWeight)))"
    }
}
