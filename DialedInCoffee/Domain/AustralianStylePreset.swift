import Foundation

/// Canberra/Australian café-style drink presets — typical dose ratios and
/// milk volumes. Used by the ratio converter and as a quick reference.
/// Ratios reflect the local flat-white-forward style (tighter than the
/// international 1:2–1:2.5 norm). Fully local reference data.
public struct AustralianStylePreset: Identifiable, Hashable, Sendable {
    public let name: String
    public let drink: DrinkType
    public let symbolName: String
    /// Target brew ratio multiplier (yield ÷ dose).
    public let ratio: Double
    /// Typical total beverage volume in ml.
    public let beverageML: Int
    /// Typical steamed-milk volume in ml (0 for black drinks).
    public let milkML: Int
    public let blurb: String

    public var id: String { name }

    public var ratioText: String { String(format: "1:%.1f", ratio) }

    public static let all: [AustralianStylePreset] = [
        AustralianStylePreset(
            name: "Ristretto",
            drink: .espresso,
            symbolName: "cup.and.saucer",
            ratio: 1.5,
            beverageML: 25,
            milkML: 0,
            blurb: "Short, syrupy and sweet. The tightest pull — great for showcasing chocolatey blends."
        ),
        AustralianStylePreset(
            name: "Espresso",
            drink: .espresso,
            symbolName: "cup.and.saucer",
            ratio: 2.0,
            beverageML: 36,
            milkML: 0,
            blurb: "The classic double shot. Balanced reference point for dialling in."
        ),
        AustralianStylePreset(
            name: "Piccolo",
            drink: .flatWhite,
            symbolName: "cup.and.saucer.fill",
            ratio: 2.0,
            beverageML: 90,
            milkML: 55,
            blurb: "A ristretto/espresso in a small glass topped with textured milk. Canberra café staple."
        ),
        AustralianStylePreset(
            name: "Flat White",
            drink: .flatWhite,
            symbolName: "cup.and.saucer.fill",
            ratio: 2.0,
            beverageML: 160,
            milkML: 120,
            blurb: "The Aussie default. Double ristretto/espresso with silky microfoam, minimal foam."
        ),
        AustralianStylePreset(
            name: "Cappuccino",
            drink: .cappuccino,
            symbolName: "cup.and.saucer.fill",
            ratio: 2.0,
            beverageML: 180,
            milkML: 130,
            blurb: "More foam than a flat white, dusted with chocolate. Slightly drier milk texture."
        ),
        AustralianStylePreset(
            name: "Latte",
            drink: .latte,
            symbolName: "mug.fill",
            ratio: 2.2,
            beverageML: 240,
            milkML: 200,
            blurb: "Milk-forward and mild in a glass. Stretch the ratio a touch so it isn't washed out."
        ),
        AustralianStylePreset(
            name: "Long Black",
            drink: .longBlack,
            symbolName: "cup.and.saucer",
            ratio: 2.0,
            beverageML: 110,
            milkML: 0,
            blurb: "Double shot poured over ~80 ml hot water to keep the crema. Aussie answer to an americano."
        )
    ]
}
