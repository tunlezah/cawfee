import Foundation
import SwiftData

/// A single pulled espresso shot, captured by the in-app shot timer.
/// Fully local — persisted via SwiftData, no network involved.
@Model
public final class Shot {
    @Attribute(.unique) public var id: UUID
    public var date: Date

    /// Denormalised bean references so a shot survives bean deletion.
    public var beanName: String?
    public var beanSlug: String?

    public var drinkRaw: String

    /// Dose in grams (coffee in).
    public var doseGrams: Double
    /// Yield in grams (liquid espresso out).
    public var yieldGrams: Double

    /// Timer captures.
    public var preInfusionSeconds: Double
    public var totalSeconds: Double

    /// Optional grind setting at the time of the shot (machine-specific scale).
    public var grindSetting: Int?

    /// 0 = unrated, 1...5 stars.
    public var rating: Int
    public var notes: String

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        beanName: String? = nil,
        beanSlug: String? = nil,
        drink: DrinkType = .cappuccino,
        doseGrams: Double = 18,
        yieldGrams: Double = 36,
        preInfusionSeconds: Double = 0,
        totalSeconds: Double = 0,
        grindSetting: Int? = nil,
        rating: Int = 0,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.beanName = beanName
        self.beanSlug = beanSlug
        self.drinkRaw = drink.rawValue
        self.doseGrams = doseGrams
        self.yieldGrams = yieldGrams
        self.preInfusionSeconds = preInfusionSeconds
        self.totalSeconds = totalSeconds
        self.grindSetting = grindSetting
        self.rating = rating
        self.notes = notes
    }

    public var drink: DrinkType {
        get { DrinkType(rawValue: drinkRaw) ?? .cappuccino }
        set { drinkRaw = newValue.rawValue }
    }

    /// Brew ratio as a multiplier (yield / dose). Returns nil if dose is zero.
    public var ratio: Double? {
        guard doseGrams > 0 else { return nil }
        return yieldGrams / doseGrams
    }

    /// Human-readable ratio, e.g. "1:2.1". Returns "—" if dose is zero.
    public var ratioText: String {
        guard let ratio else { return "—" }
        return String(format: "1:%.1f", ratio)
    }
}
