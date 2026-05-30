package com.cawfee.domain

import com.cawfee.domain.model.DrinkType
import com.cawfee.domain.model.FreshnessCalculator
import com.cawfee.domain.model.FreshnessStage
import com.cawfee.domain.model.MachineSettings
import kotlin.test.Test
import kotlin.test.assertEquals

/** Verifies the bean-freshness windows (ported from BeanProfile+Freshness.swift) and the
 * Cappuccino default invariant (Phase 9). */
class FreshnessTest {

    private val now = 1_700_000_000_000L
    private fun daysAgo(d: Int) = now - d * 86_400_000L

    @Test
    fun `roast windows map to the right stage`() {
        assertEquals(FreshnessStage.UNKNOWN, FreshnessCalculator.assess(null, now).stage)
        assertEquals(FreshnessStage.RESTING, FreshnessCalculator.assess(daysAgo(3), now).stage)
        assertEquals(FreshnessStage.PEAK, FreshnessCalculator.assess(daysAgo(14), now).stage)
        assertEquals(FreshnessStage.GOOD, FreshnessCalculator.assess(daysAgo(30), now).stage)
        assertEquals(FreshnessStage.FADING, FreshnessCalculator.assess(daysAgo(50), now).stage)
        assertEquals(FreshnessStage.STALE, FreshnessCalculator.assess(daysAgo(90), now).stage)
    }

    @Test
    fun `days since roast clamps at zero for future dates`() {
        assertEquals(0, FreshnessCalculator.daysSinceRoast(daysAgo(-5), now))
        assertEquals(12, FreshnessCalculator.daysSinceRoast(daysAgo(12), now))
    }

    @Test
    fun `cappuccino is the default drink and uses the cappuccino settings`() {
        // Phase 9 invariant: the cappuccino preset adds extra milk time vs the flat white.
        assertEquals(22, MachineSettings.defaultCappuccino.milkSeconds)
        assertEquals(MachineSettings.defaultCappuccino, MachineSettings.defaults(DrinkType.CAPPUCCINO))
    }
}
