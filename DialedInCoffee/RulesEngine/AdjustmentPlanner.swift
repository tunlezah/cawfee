import Foundation

public enum AdjustmentPlanner {
    /// Translate the top-confidence cause into a concrete machine adjustment.
    /// Returns nil for `.beans` — handled separately as informational.
    public static func adjustment(
        for cause: Cause,
        current: MachineSettings,
        drink: DrinkType,
        milk: Milk
    ) -> Adjustment? {
        switch cause {
        case .overExtraction:
            let to = MachineRanges.clampGrinder(current.grinder - 1)
            guard to != current.grinder else { return nil }
            return Adjustment(
                parameter: .grinder,
                fromInt: current.grinder,
                toInt: to,
                reason: "Coarser grind reduces over-extraction.",
                expectedOutcome: "Less bitterness, smoother body."
            )

        case .underExtraction:
            let to = MachineRanges.clampGrinder(current.grinder + 1)
            guard to != current.grinder else { return nil }
            return Adjustment(
                parameter: .grinder,
                fromInt: current.grinder,
                toInt: to,
                reason: "Finer grind builds extraction.",
                expectedOutcome: "Less sour, more sweetness and body."
            )

        case .excessiveDilution:
            let target = AustralianStyleBias.appliesTo(drink: drink)
                ? min(current.volumeML - 10, AustralianStyleBias.preferredVolumeRange.upperBound)
                : current.volumeML - 10
            let to = MachineRanges.clampVolume(target)
            guard to != current.volumeML else { return nil }
            return Adjustment(
                parameter: .volume,
                fromInt: current.volumeML,
                toInt: to,
                reason: "Less water concentrates flavour.",
                expectedOutcome: "Fuller body, more cafe-like cup."
            )

        case .insufficientDilution:
            let to = MachineRanges.clampVolume(current.volumeML + 5)
            guard to != current.volumeML else { return nil }
            return Adjustment(
                parameter: .volume,
                fromInt: current.volumeML,
                toInt: to,
                reason: "A little more water rounds out the cup.",
                expectedOutcome: "Less intensity, drinkable balance."
            )

        case .excessiveHeat:
            let to = current.temperature.cooler()
            guard to != current.temperature else { return nil }
            return Adjustment(
                parameter: .temperature,
                fromTemp: current.temperature,
                toTemp: to,
                reason: "Lower temperature reveals sweetness instead of bitterness.",
                expectedOutcome: "Smoother, less burnt."
            )

        case .insufficientHeat:
            let to = current.temperature.hotter()
            guard to != current.temperature else { return nil }
            return Adjustment(
                parameter: .temperature,
                fromTemp: current.temperature,
                toTemp: to,
                reason: "Warmer brew lifts aromatics.",
                expectedOutcome: "More fragrance, less sour edge."
            )

        case .excessiveStrength:
            let to = MachineRanges.clampStrength(current.strength - 1)
            guard to != current.strength else { return nil }
            return Adjustment(
                parameter: .strength,
                fromInt: current.strength,
                toInt: to,
                reason: "Less coffee for this volume.",
                expectedOutcome: "More balanced, easier to drink."
            )

        case .insufficientStrength:
            let to = MachineRanges.clampStrength(current.strength + 1)
            guard to != current.strength else { return nil }
            return Adjustment(
                parameter: .strength,
                fromInt: current.strength,
                toInt: to,
                reason: "More coffee for this volume.",
                expectedOutcome: "Fuller, more coffee-forward."
            )

        case .excessiveFoam:
            let to = MachineRanges.clampMilkDuration(current.milkSeconds - 4)
            guard to != current.milkSeconds else { return nil }
            return Adjustment(
                parameter: .milkDuration,
                fromInt: current.milkSeconds,
                toInt: to,
                reason: "Less milk run gives silkier microfoam.",
                expectedOutcome: "Cafe-style flat-white texture."
            )

        case .staleOrTooFine:
            // Two viable moves: coarsen one notch, or suggest a fresher bean.
            // Coarsening is the deterministic machine action.
            let to = MachineRanges.clampGrinder(current.grinder - 1)
            if to != current.grinder {
                return Adjustment(
                    parameter: .grinder,
                    fromInt: current.grinder,
                    toInt: to,
                    reason: "A coarser grind helps if flow is choked.",
                    expectedOutcome: "Clearer flavour, less muddy mouthfeel."
                )
            }
            return Adjustment(
                parameter: .beans,
                reason: "Try fresher beans or a different SKU.",
                expectedOutcome: "Brighter, more defined flavour."
            )

        case .milkOverwhelmingCoffee:
            let to = MachineRanges.clampMilkDuration(current.milkSeconds - 4)
            guard to != current.milkSeconds else { return nil }
            return Adjustment(
                parameter: .milkDuration,
                fromInt: current.milkSeconds,
                toInt: to,
                reason: "Less milk lets the espresso speak.",
                expectedOutcome: "More coffee character in the cup."
            )
        }
    }

    /// Apply Australian-style biases that can take precedence over the raw top cause.
    /// Returns a pre-emptive adjustment if a high-impact lifestyle fix is obvious.
    public static func australianBiasOverride(
        current: MachineSettings,
        drink: DrinkType,
        symptoms: [Symptom]
    ) -> Adjustment? {
        guard AustralianStyleBias.appliesTo(drink: drink) else { return nil }

        // If the user is on .high temperature for a milk drink, biasing toward .normal
        // is the single highest-leverage smoothness change. Apply only if `tooHot` or
        // `tooBurnt` or `notCafeLike` is among symptoms.
        let highTempSymptoms: Set<Symptom> = [.tooHot, .tooBurnt, .notCafeLike, .tooBitter]
        if current.temperature == .high && !highTempSymptoms.isDisjoint(with: Set(symptoms)) {
            return Adjustment(
                parameter: .temperature,
                fromTemp: .high,
                toTemp: .normal,
                reason: "Australian-style milk coffee is smoother at normal temperature.",
                expectedOutcome: "Less burnt, more chocolate-and-caramel character."
            )
        }
        return nil
    }

    public static func differentParameter(_ a: Adjustment, from b: Adjustment) -> Bool {
        a.parameter != b.parameter
    }
}
