import Foundation

public enum Cause: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case overExtraction
    case underExtraction
    case excessiveDilution
    case insufficientDilution
    case excessiveHeat
    case insufficientHeat
    case excessiveStrength
    case insufficientStrength
    case excessiveFoam
    case staleOrTooFine
    case milkOverwhelmingCoffee

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .overExtraction: return "Over-extraction"
        case .underExtraction: return "Under-extraction"
        case .excessiveDilution: return "Too much water"
        case .insufficientDilution: return "Too little water"
        case .excessiveHeat: return "Too hot"
        case .insufficientHeat: return "Too cool"
        case .excessiveStrength: return "Strength too high"
        case .insufficientStrength: return "Strength too low"
        case .excessiveFoam: return "Too much foam"
        case .staleOrTooFine: return "Grind too fine or stale beans"
        case .milkOverwhelmingCoffee: return "Milk overwhelming coffee"
        }
    }

    public var plainExplanation: String {
        switch self {
        case .overExtraction:
            return "The grind is finer than the beans want, so water pulls bitter compounds."
        case .underExtraction:
            return "Water is rushing through too quickly, so the coffee tastes sour and thin."
        case .excessiveDilution:
            return "There's more water in the cup than the dose can flavour."
        case .insufficientDilution:
            return "Volume is too small for the dose — the cup tastes intense or syrupy."
        case .excessiveHeat:
            return "Temperature is masking subtle flavours and burning the tongue."
        case .insufficientHeat:
            return "Coffee is dropping below the right serving temperature."
        case .excessiveStrength:
            return "The strength dial is pulling too much coffee for this volume."
        case .insufficientStrength:
            return "Not enough coffee is being ground for the cup size."
        case .excessiveFoam:
            return "Milk frothing is producing too much air rather than silky texture."
        case .staleOrTooFine:
            return "Beans are losing oils or the grind is choking flow."
        case .milkOverwhelmingCoffee:
            return "Milk volume or sweetness is drowning the espresso."
        }
    }
}
