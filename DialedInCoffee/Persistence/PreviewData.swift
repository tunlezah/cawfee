import Foundation
import SwiftData

public enum PreviewData {
    @MainActor
    public static func previewContainer() -> ModelContainer {
        let container = ModelContainerFactory.makeInMemory()
        let ctx = container.mainContext
        populate(ctx)
        return container
    }

    @MainActor
    public static func populate(_ ctx: ModelContext) {
        // Preferences
        let prefs = UserPreferences(hasSeededBeans: true)
        ctx.insert(prefs)

        // A handful of seed-style beans for previews.
        let beans: [BeanProfile] = [
            BeanProfile(
                slug: "ona-maple",
                name: "Maple 🥛",
                roaster: "ONA Coffee",
                roastLevel: .medium,
                milkFriendly: true,
                flavourNotes: ["caramel", "biscuit", "nut", "spice"],
                recommendedSettings: MachineSettings(grinder: 4, strength: 7, volumeML: 37, milkSeconds: 18, temperature: .normal),
                isSeeded: true
            ),
            BeanProfile(
                slug: "cosmorex-signature-blue",
                name: "Signature Blue 🥛",
                roaster: "Cosmorex Coffee",
                roastLevel: .mediumDark,
                milkFriendly: true,
                flavourNotes: ["dark chocolate", "red berries", "toffee", "nutty"],
                recommendedSettings: MachineSettings(grinder: 4, strength: 7, volumeML: 36, milkSeconds: 20, temperature: .normal),
                isSeeded: true
            ),
            BeanProfile(
                slug: "redbrick-coffee-coffee",
                name: "Coffee Coffee 🥛",
                roaster: "Redbrick Coffee",
                roastLevel: .medium,
                milkFriendly: true,
                flavourNotes: ["toffee", "chocolate"],
                recommendedSettings: MachineSettings(grinder: 4, strength: 7, volumeML: 38, milkSeconds: 18, temperature: .normal),
                isSeeded: true
            ),
        ]
        beans.forEach { ctx.insert($0) }

        // A favourite recipe.
        let recipe = Recipe(
            name: "Morning Flat White",
            drink: .flatWhite,
            milkKind: .devondaleFullCreamUHT,
            settings: MachineSettings(grinder: 4, strength: 7, volumeML: 35, milkSeconds: 18, temperature: .normal),
            bean: beans.first,
            isFavourite: true,
            isLastGood: true,
            notes: "The good one. Don't change."
        )
        ctx.insert(recipe)

        // A small history.
        let h1 = AdjustmentHistoryEntry(
            date: Date().addingTimeInterval(-86400 * 2),
            drink: .flatWhite,
            beanName: "Maple",
            symptoms: [.tooBitter],
            before: MachineSettings(grinder: 5, strength: 7, volumeML: 35, milkSeconds: 18, temperature: .normal),
            after:  MachineSettings(grinder: 4, strength: 7, volumeML: 35, milkSeconds: 18, temperature: .normal),
            primaryParameter: .grinder,
            outcome: .better,
            rationale: "Coarsened grind to reduce bitterness.",
            confidence: 0.78
        )
        let h2 = AdjustmentHistoryEntry(
            date: Date().addingTimeInterval(-86400),
            drink: .flatWhite,
            beanName: "Maple",
            symptoms: [.tooHot, .tooBurnt],
            before: MachineSettings(grinder: 4, strength: 7, volumeML: 35, milkSeconds: 18, temperature: .high),
            after:  MachineSettings(grinder: 4, strength: 7, volumeML: 35, milkSeconds: 18, temperature: .normal),
            primaryParameter: .temperature,
            outcome: .good,
            rationale: "Dropped temperature for a smoother cup.",
            confidence: 0.86
        )
        ctx.insert(h1)
        ctx.insert(h2)

        try? ctx.save()
    }
}
