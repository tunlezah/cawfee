import Foundation
import SwiftData

/// A named brewing-water mineral profile (mg/L). Lets the user record their tap
/// or recipe water and compare against SCA-ish target ranges. Fully local.
@Model
public final class WaterProfile {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var detail: String

    /// Minerals in mg/L (ppm).
    public var calcium: Double
    public var magnesium: Double
    public var bicarbonate: Double
    /// Total hardness as CaCO3 (mg/L). Stored explicitly because tap reports vary.
    public var totalHardness: Double

    public var isDefault: Bool
    public var isSeeded: Bool
    public var sortOrder: Int

    public init(
        id: UUID = UUID(),
        name: String,
        detail: String = "",
        calcium: Double = 0,
        magnesium: Double = 0,
        bicarbonate: Double = 0,
        totalHardness: Double = 0,
        isDefault: Bool = false,
        isSeeded: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.calcium = calcium
        self.magnesium = magnesium
        self.bicarbonate = bicarbonate
        self.totalHardness = totalHardness
        self.isDefault = isDefault
        self.isSeeded = isSeeded
        self.sortOrder = sortOrder
    }

    /// SCA general guidance: total hardness target ~ 50–175 mg/L (CaCO3),
    /// alkalinity (bicarbonate) ~ 40–75 mg/L. We classify roughly for the UI.
    public enum Assessment: String, Sendable {
        case soft, ideal, hard

        public var label: String {
            switch self {
            case .soft: return "Soft"
            case .ideal: return "In range"
            case .hard: return "Hard"
            }
        }
    }

    public var hardnessAssessment: Assessment {
        switch totalHardness {
        case ..<50: return .soft
        case ...175: return .ideal
        default: return .hard
        }
    }

    /// Practical brewing hint based on the profile.
    public var brewingHint: String {
        switch hardnessAssessment {
        case .soft:
            return "Soft water (low scale risk) but can taste flat / under-extracted. Grind finer or push the ratio, and consider a remineraliser for clarity."
        case .ideal:
            return "Hardness is in the sweet spot for extraction. Keep an eye on alkalinity if shots taste dull."
        case .hard:
            return "Hard water extracts strongly but scales the machine. Descale more often and watch for chalky/bitter cups."
        }
    }
}
