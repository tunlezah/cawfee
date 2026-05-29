import Foundation

public struct CauseContribution: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var cause: Cause
    public var confidence: Double          // 0...1
    public var ruleIDs: [String]           // contributing rule ids

    public init(
        id: UUID = UUID(),
        cause: Cause,
        confidence: Double,
        ruleIDs: [String]
    ) {
        self.id = id
        self.cause = cause
        self.confidence = confidence
        self.ruleIDs = ruleIDs
    }
}

public struct Recommendation: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var primary: Adjustment?
    public var secondary: Adjustment?
    public var topCause: Cause?
    public var confidence: Double          // 0...1
    public var rationale: String
    public var contributions: [CauseContribution]
    public var alternativeCauses: [CauseContribution]
    public var suggestRevertToLastGood: Bool

    public init(
        id: UUID = UUID(),
        primary: Adjustment? = nil,
        secondary: Adjustment? = nil,
        topCause: Cause? = nil,
        confidence: Double = 0,
        rationale: String = "",
        contributions: [CauseContribution] = [],
        alternativeCauses: [CauseContribution] = [],
        suggestRevertToLastGood: Bool = false
    ) {
        self.id = id
        self.primary = primary
        self.secondary = secondary
        self.topCause = topCause
        self.confidence = confidence
        self.rationale = rationale
        self.contributions = contributions
        self.alternativeCauses = alternativeCauses
        self.suggestRevertToLastGood = suggestRevertToLastGood
    }

    public var adjustments: [Adjustment] {
        [primary, secondary].compactMap { $0 }
    }

    public var hasAnyAdjustment: Bool { primary != nil }
}
