import Foundation

/// A compact, SCA-inspired coffee flavour wheel for tasting notes.
/// Two levels: top-level categories → descriptor leaves. Bundled in-code so it
/// works entirely offline.
public struct SensoryCategory: Identifiable, Hashable, Sendable {
    public let name: String
    public let symbolName: String
    public let descriptors: [String]
    public var id: String { name }
}

public enum SensoryWheel {
    public static let categories: [SensoryCategory] = [
        SensoryCategory(
            name: "Fruity",
            symbolName: "cherries",
            descriptors: ["Berry", "Blueberry", "Raspberry", "Strawberry",
                          "Stone Fruit", "Cherry", "Citrus", "Lemon",
                          "Orange", "Tropical", "Apple", "Grape"]
        ),
        SensoryCategory(
            name: "Sweet",
            symbolName: "cube",
            descriptors: ["Caramel", "Brown Sugar", "Honey", "Maple",
                          "Toffee", "Molasses", "Vanilla", "Butterscotch"]
        ),
        SensoryCategory(
            name: "Nutty / Cocoa",
            symbolName: "circle.hexagongrid",
            descriptors: ["Almond", "Hazelnut", "Peanut", "Cocoa",
                          "Dark Chocolate", "Milk Chocolate", "Malt"]
        ),
        SensoryCategory(
            name: "Floral",
            symbolName: "leaf",
            descriptors: ["Jasmine", "Rose", "Bergamot", "Black Tea",
                          "Chamomile", "Honeysuckle"]
        ),
        SensoryCategory(
            name: "Spice",
            symbolName: "flame",
            descriptors: ["Cinnamon", "Clove", "Nutmeg", "Pepper", "Anise"]
        ),
        SensoryCategory(
            name: "Roasted",
            symbolName: "smoke",
            descriptors: ["Toast", "Smoky", "Tobacco", "Burnt", "Cereal"]
        ),
        SensoryCategory(
            name: "Other",
            symbolName: "drop",
            descriptors: ["Winey", "Boozy", "Earthy", "Herbal",
                          "Savoury", "Creamy", "Juicy", "Clean"]
        )
    ]

    /// All descriptors flattened (e.g. for search or validation).
    public static let allDescriptors: [String] = categories.flatMap(\.descriptors)
}
