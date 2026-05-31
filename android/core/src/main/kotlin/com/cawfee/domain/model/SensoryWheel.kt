package com.cawfee.domain.model

/**
 * A compact, SCA-inspired coffee flavour wheel for tasting notes. Two levels: top-level
 * categories -> descriptor leaves. Bundled in-code so it works entirely offline.
 * Ported 1:1 from SensoryWheel.swift.
 */
data class SensoryCategory(
    val name: String,
    val descriptors: List<String>,
)

object SensoryWheel {
    val categories: List<SensoryCategory> = listOf(
        SensoryCategory(
            "Fruity",
            listOf(
                "Berry", "Blueberry", "Raspberry", "Strawberry",
                "Stone Fruit", "Cherry", "Citrus", "Lemon",
                "Orange", "Tropical", "Apple", "Grape",
            ),
        ),
        SensoryCategory(
            "Sweet",
            listOf(
                "Caramel", "Brown Sugar", "Honey", "Maple",
                "Toffee", "Molasses", "Vanilla", "Butterscotch",
            ),
        ),
        SensoryCategory(
            "Nutty / Cocoa",
            listOf(
                "Almond", "Hazelnut", "Peanut", "Cocoa",
                "Dark Chocolate", "Milk Chocolate", "Malt",
            ),
        ),
        SensoryCategory(
            "Floral",
            listOf("Jasmine", "Rose", "Bergamot", "Black Tea", "Chamomile", "Honeysuckle"),
        ),
        SensoryCategory(
            "Spice",
            listOf("Cinnamon", "Clove", "Nutmeg", "Pepper", "Anise"),
        ),
        SensoryCategory(
            "Roasted",
            listOf("Toast", "Smoky", "Tobacco", "Burnt", "Cereal"),
        ),
        SensoryCategory(
            "Other",
            listOf("Winey", "Boozy", "Earthy", "Herbal", "Savoury", "Creamy", "Juicy", "Clean"),
        ),
    )

    /** All descriptors flattened (e.g. for search or validation). */
    val allDescriptors: List<String> = categories.flatMap { it.descriptors }
}
