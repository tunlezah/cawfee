import Foundation

public enum AustralianStyleBias {
    public static let preferredTemperature: TemperatureLevel = .normal
    public static let preferredVolumeRange: ClosedRange<Int> = 30...40
    public static let preferredMilkSecondsFlatWhite: ClosedRange<Int> = 14...20
    public static let preferredMilkSecondsCappuccino: ClosedRange<Int> = 18...26
    public static let preferredStrengthRange: ClosedRange<Int> = 6...8

    public static func appliesTo(drink: DrinkType) -> Bool {
        drink == .flatWhite || drink == .cappuccino
    }

    public static func preferredMilkSeconds(for drink: DrinkType) -> ClosedRange<Int>? {
        switch drink {
        case .flatWhite: return preferredMilkSecondsFlatWhite
        case .cappuccino: return preferredMilkSecondsCappuccino
        default: return nil
        }
    }
}
