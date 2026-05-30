import Foundation
import SwiftData

/// A sensory tasting note for a cup. Can stand alone or reference a bean.
/// Descriptors are stored as flat strings drawn from the SCA-style sensory wheel.
/// Fully local.
@Model
public final class TastingNote {
    @Attribute(.unique) public var id: UUID
    public var date: Date

    public var beanName: String?
    public var beanSlug: String?
    public var drinkRaw: String

    /// Selected sensory-wheel descriptors, e.g. ["Berry", "Cocoa", "Brown Sugar"].
    public var descriptors: [String]

    /// 1...5 intensity sliders (0 = not rated).
    public var body: Int
    public var acidity: Int
    public var sweetness: Int
    public var bitterness: Int

    /// Overall 1...5 (0 = unrated).
    public var rating: Int
    public var freeText: String

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        beanName: String? = nil,
        beanSlug: String? = nil,
        drink: DrinkType = .cappuccino,
        descriptors: [String] = [],
        body: Int = 0,
        acidity: Int = 0,
        sweetness: Int = 0,
        bitterness: Int = 0,
        rating: Int = 0,
        freeText: String = ""
    ) {
        self.id = id
        self.date = date
        self.beanName = beanName
        self.beanSlug = beanSlug
        self.drinkRaw = drink.rawValue
        self.descriptors = descriptors
        self.body = body
        self.acidity = acidity
        self.sweetness = sweetness
        self.bitterness = bitterness
        self.rating = rating
        self.freeText = freeText
    }

    public var drink: DrinkType {
        get { DrinkType(rawValue: drinkRaw) ?? .cappuccino }
        set { drinkRaw = newValue.rawValue }
    }
}
