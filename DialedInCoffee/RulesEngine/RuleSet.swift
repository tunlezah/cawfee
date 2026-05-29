import Foundation

public enum RuleSet {
    public static let allRules: [Rule] = [
        // --- Too Bitter ---
        Rule(
            id: "bitter.overExtraction.base",
            trigger: .tooBitter,
            cause: .overExtraction,
            baseWeight: 0.7,
            rationale: "Bitterness usually means water is pulling too much from the grounds."
        ),
        Rule(
            id: "bitter.overExtraction.fineGrind",
            trigger: .tooBitter,
            cause: .overExtraction,
            baseWeight: 0.55,
            conditions: [.grinderAtLeast(5)],
            conditionMultiplier: 1.2,
            rationale: "Grinder is on the fine side — that exacerbates over-extraction."
        ),
        Rule(
            id: "bitter.excessiveHeat",
            trigger: .tooBitter,
            cause: .excessiveHeat,
            baseWeight: 0.35,
            conditions: [.tempEquals(.high)],
            conditionMultiplier: 1.4,
            rationale: "Temperature set to high tends to accentuate bitter notes."
        ),
        Rule(
            id: "bitter.darkRoast",
            trigger: .tooBitter,
            cause: .excessiveStrength,
            baseWeight: 0.3,
            conditions: [.beanRoastAtLeast(.mediumDark), .strengthAtLeast(8)],
            conditionMultiplier: 1.3,
            rationale: "Dark roast with high strength pulls extra bitterness."
        ),

        // --- Too Sour ---
        Rule(
            id: "sour.underExtraction.base",
            trigger: .tooSour,
            cause: .underExtraction,
            baseWeight: 0.75,
            rationale: "Sourness usually means water isn't pulling enough — grind finer."
        ),
        Rule(
            id: "sour.underExtraction.coarse",
            trigger: .tooSour,
            cause: .underExtraction,
            baseWeight: 0.55,
            conditions: [.grinderAtMost(3)],
            conditionMultiplier: 1.25,
            rationale: "Grinder is coarse — likely the dominant cause."
        ),
        Rule(
            id: "sour.insufficientHeat",
            trigger: .tooSour,
            cause: .insufficientHeat,
            baseWeight: 0.3,
            conditions: [.tempEquals(.low)],
            conditionMultiplier: 1.3,
            rationale: "Low temperature can leave acidity in the cup."
        ),

        // --- Too Watery ---
        Rule(
            id: "watery.excessiveDilution.base",
            trigger: .tooWatery,
            cause: .excessiveDilution,
            baseWeight: 0.75,
            rationale: "Volume is overpowering the dose — cut volume."
        ),
        Rule(
            id: "watery.excessiveDilution.largeVolume",
            trigger: .tooWatery,
            cause: .excessiveDilution,
            baseWeight: 0.55,
            conditions: [.volumeAtLeast(80)],
            conditionMultiplier: 1.3,
            rationale: "Volume is well above an Aus-style flat white."
        ),
        Rule(
            id: "watery.insufficientStrength",
            trigger: .tooWatery,
            cause: .insufficientStrength,
            baseWeight: 0.4,
            conditions: [.strengthAtMost(5)],
            conditionMultiplier: 1.3,
            rationale: "Strength is low — more coffee would help body."
        ),

        // --- Too Burnt ---
        Rule(
            id: "burnt.excessiveHeat.base",
            trigger: .tooBurnt,
            cause: .excessiveHeat,
            baseWeight: 0.7,
            rationale: "Burnt taste correlates strongly with temperature being too high."
        ),
        Rule(
            id: "burnt.excessiveHeat.highTemp",
            trigger: .tooBurnt,
            cause: .excessiveHeat,
            baseWeight: 0.55,
            conditions: [.tempEquals(.high)],
            conditionMultiplier: 1.4,
            rationale: "Temperature is already high — drop it."
        ),
        Rule(
            id: "burnt.overExtraction",
            trigger: .tooBurnt,
            cause: .overExtraction,
            baseWeight: 0.35,
            conditions: [.grinderAtLeast(6)],
            conditionMultiplier: 1.2,
            rationale: "Grinder is very fine, adding ashy notes."
        ),

        // --- Too Dry / Harsh ---
        Rule(
            id: "dry.overExtraction",
            trigger: .tooDry,
            cause: .overExtraction,
            baseWeight: 0.6,
            rationale: "Astringency points to over-extraction — coarsen the grind."
        ),
        Rule(
            id: "dry.staleOrTooFine",
            trigger: .tooDry,
            cause: .staleOrTooFine,
            baseWeight: 0.35,
            conditions: [.grinderAtLeast(6)],
            conditionMultiplier: 1.2,
            rationale: "Very fine grind can dry the palate."
        ),

        // --- Too Weak ---
        Rule(
            id: "weak.insufficientStrength.base",
            trigger: .tooWeak,
            cause: .insufficientStrength,
            baseWeight: 0.7,
            rationale: "Increase strength to get more coffee into the cup."
        ),
        Rule(
            id: "weak.excessiveDilution",
            trigger: .tooWeak,
            cause: .excessiveDilution,
            baseWeight: 0.4,
            conditions: [.volumeAtLeast(50)],
            conditionMultiplier: 1.3,
            rationale: "Volume is high relative to dose — shorten the pour."
        ),
        Rule(
            id: "weak.milkOverwhelming",
            trigger: .tooWeak,
            cause: .milkOverwhelmingCoffee,
            baseWeight: 0.45,
            conditions: [.drinkIsMilkBased, .milkSecondsAtLeast(25)],
            conditionMultiplier: 1.3,
            rationale: "Milk run is long — it's drowning the espresso."
        ),

        // --- Too Strong ---
        Rule(
            id: "strong.excessiveStrength.base",
            trigger: .tooStrong,
            cause: .excessiveStrength,
            baseWeight: 0.7,
            rationale: "Strength is too high for this cup."
        ),
        Rule(
            id: "strong.insufficientDilution",
            trigger: .tooStrong,
            cause: .insufficientDilution,
            baseWeight: 0.35,
            conditions: [.volumeAtMost(30)],
            conditionMultiplier: 1.3,
            rationale: "Volume is at the low end — a touch more water helps."
        ),

        // --- Too Foamy ---
        Rule(
            id: "foamy.excessiveFoam.base",
            trigger: .tooFoamy,
            cause: .excessiveFoam,
            baseWeight: 0.75,
            rationale: "Reduce milk duration for less aerated foam."
        ),
        Rule(
            id: "foamy.excessiveFoam.long",
            trigger: .tooFoamy,
            cause: .excessiveFoam,
            baseWeight: 0.55,
            conditions: [.milkSecondsAtLeast(28)],
            conditionMultiplier: 1.3,
            rationale: "Milk frothing time is long."
        ),

        // --- Too Hot ---
        Rule(
            id: "hot.excessiveHeat.base",
            trigger: .tooHot,
            cause: .excessiveHeat,
            baseWeight: 0.8,
            rationale: "Drop the brew temperature."
        ),
        Rule(
            id: "hot.excessiveHeat.high",
            trigger: .tooHot,
            cause: .excessiveHeat,
            baseWeight: 0.6,
            conditions: [.tempEquals(.high)],
            conditionMultiplier: 1.4,
            rationale: "Temperature is set to high."
        ),

        // --- Tastes Empty ---
        Rule(
            id: "empty.insufficientStrength",
            trigger: .tastesEmpty,
            cause: .insufficientStrength,
            baseWeight: 0.55,
            rationale: "Lift strength to give the cup body and flavour."
        ),
        Rule(
            id: "empty.underExtraction",
            trigger: .tastesEmpty,
            cause: .underExtraction,
            baseWeight: 0.4,
            conditions: [.grinderAtMost(3)],
            conditionMultiplier: 1.2,
            rationale: "Coarse grind is producing a hollow cup."
        ),
        Rule(
            id: "empty.milkOverwhelming",
            trigger: .tastesEmpty,
            cause: .milkOverwhelmingCoffee,
            baseWeight: 0.35,
            conditions: [.drinkIsMilkBased, .milkSecondsAtLeast(24)],
            conditionMultiplier: 1.3,
            rationale: "Milk is masking the coffee."
        ),

        // --- Not Cafe-Like ---
        Rule(
            id: "notCafeLike.excessiveDilution",
            trigger: .notCafeLike,
            cause: .excessiveDilution,
            baseWeight: 0.45,
            conditions: [.volumeAtLeast(60)],
            conditionMultiplier: 1.3,
            rationale: "Cafe-style flat whites sit around 30–40ml espresso."
        ),
        Rule(
            id: "notCafeLike.excessiveHeat",
            trigger: .notCafeLike,
            cause: .excessiveHeat,
            baseWeight: 0.4,
            conditions: [.tempEquals(.high)],
            conditionMultiplier: 1.3,
            rationale: "Cafe-style milk drinks aren't scalding."
        ),
        Rule(
            id: "notCafeLike.excessiveFoam",
            trigger: .notCafeLike,
            cause: .excessiveFoam,
            baseWeight: 0.4,
            conditions: [.drinkIs(.flatWhite), .milkSecondsAtLeast(22)],
            conditionMultiplier: 1.3,
            rationale: "A flat white should be silky, not airy."
        ),

        // --- Sharp Aftertaste ---
        Rule(
            id: "sharp.overExtraction",
            trigger: .sharpAftertaste,
            cause: .overExtraction,
            baseWeight: 0.5,
            rationale: "A harsh finish usually means over-extraction."
        ),
        Rule(
            id: "sharp.underExtraction",
            trigger: .sharpAftertaste,
            cause: .underExtraction,
            baseWeight: 0.45,
            conditions: [.grinderAtMost(3)],
            conditionMultiplier: 1.2,
            rationale: "Coarse grind can give a thin, acidic finish."
        ),

        // --- Muddy / Dull ---
        Rule(
            id: "muddy.staleOrTooFine.base",
            trigger: .muddyDull,
            cause: .staleOrTooFine,
            baseWeight: 0.6,
            rationale: "A muddy cup often means stale beans or a choked grind."
        ),
        Rule(
            id: "muddy.staleOrTooFine.fineGrind",
            trigger: .muddyDull,
            cause: .staleOrTooFine,
            baseWeight: 0.5,
            conditions: [.grinderAtLeast(6)],
            conditionMultiplier: 1.3,
            rationale: "Grinder is very fine — flow is being choked."
        ),
        Rule(
            id: "muddy.overExtraction",
            trigger: .muddyDull,
            cause: .overExtraction,
            baseWeight: 0.35,
            rationale: "Over-extraction can flatten clarity."
        ),
    ]

    public static func rules(triggeredBy symptoms: [Symptom]) -> [Rule] {
        let set = Set(symptoms)
        return allRules.filter { set.contains($0.trigger) }
    }
}
