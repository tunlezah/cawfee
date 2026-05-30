package com.cawfee.domain.model

/**
 * Lifecycle stage of a bag of beans, derived from its roast date. Espresso-oriented
 * windows: beans need a few days to de-gas, hit a peak window, then gradually fade.
 * All computed locally. Ported from BeanProfile+Freshness.swift (FreshnessStage).
 */
enum class FreshnessStage(val label: String) {
    UNKNOWN("No roast date"),
    RESTING("Resting"),
    PEAK("Peak"),
    GOOD("Good"),
    FADING("Fading"),
    STALE("Stale"),
}

/** A computed freshness assessment for a bean at a given moment. Ported from Freshness. */
data class Freshness(
    val stage: FreshnessStage,
    val daysSinceRoast: Int?,
) {
    /** Short status line, e.g. "Peak · 12 days" or "Add a roast date". */
    val summary: String
        get() {
            val days = daysSinceRoast ?: return "Add a roast date to track freshness"
            val dayWord = if (days == 1) "day" else "days"
            return when (stage) {
                FreshnessStage.RESTING -> "Resting · $days $dayWord — let it de-gas"
                FreshnessStage.PEAK, FreshnessStage.GOOD, FreshnessStage.FADING ->
                    "${stage.label} · $days $dayWord since roast"
                FreshnessStage.STALE -> "Stale · $days $dayWord since roast"
                FreshnessStage.UNKNOWN -> "Add a roast date to track freshness"
            }
        }
}

/**
 * Pure freshness calculator. Mirrors the Swift `BeanProfile.freshness(asOf:)` extension;
 * dates are epoch milliseconds so the logic is platform-independent and unit-testable.
 */
object FreshnessCalculator {
    private const val MS_PER_DAY = 86_400_000L

    // Espresso de-gas / peak window boundaries, in days since roast (matches Swift Window).
    private const val REST_UNTIL = 6
    private const val PEAK_UNTIL = 21
    private const val GOOD_UNTIL = 35
    private const val FADING_UNTIL = 60

    /** Whole days between [roastDateMillis] and [nowMillis] (clamped at 0); null if no roast date. */
    fun daysSinceRoast(roastDateMillis: Long?, nowMillis: Long = System.currentTimeMillis()): Int? {
        if (roastDateMillis == null) return null
        val days = ((nowMillis - roastDateMillis) / MS_PER_DAY).toInt()
        return if (days < 0) 0 else days
    }

    fun assess(roastDateMillis: Long?, nowMillis: Long = System.currentTimeMillis()): Freshness {
        val days = daysSinceRoast(roastDateMillis, nowMillis)
            ?: return Freshness(FreshnessStage.UNKNOWN, null)
        val stage = when {
            days <= REST_UNTIL -> FreshnessStage.RESTING
            days <= PEAK_UNTIL -> FreshnessStage.PEAK
            days <= GOOD_UNTIL -> FreshnessStage.GOOD
            days <= FADING_UNTIL -> FreshnessStage.FADING
            else -> FreshnessStage.STALE
        }
        return Freshness(stage, days)
    }
}
