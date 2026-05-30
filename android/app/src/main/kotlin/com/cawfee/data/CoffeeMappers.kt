package com.cawfee.data

import com.cawfee.data.local.BeanEntity
import com.cawfee.data.local.HistoryEntity
import com.cawfee.data.local.RecipeEntity
import com.cawfee.domain.model.AdjustmentOutcome
import com.cawfee.domain.model.AdjustmentParameter
import com.cawfee.domain.model.BeanSnapshot
import com.cawfee.domain.model.DrinkType
import com.cawfee.domain.model.Freshness
import com.cawfee.domain.model.FreshnessCalculator
import com.cawfee.domain.model.HistorySnapshot
import com.cawfee.domain.model.MachineSettings
import com.cawfee.domain.model.MilkKind
import com.cawfee.domain.model.RoastLevel
import com.cawfee.domain.model.Symptom
import com.cawfee.domain.model.TemperatureLevel

/**
 * Conversions between Room entities and the platform-independent `:core` domain types.
 * Enums are stored as their Kotlin `name`; parsing tolerates unknown values by falling
 * back to the same defaults the Swift getters use.
 */

fun drinkOf(name: String?): DrinkType =
    name?.let { runCatching { DrinkType.valueOf(it) }.getOrNull() } ?: DrinkType.CAPPUCCINO

fun milkOf(name: String?): MilkKind =
    name?.let { runCatching { MilkKind.valueOf(it) }.getOrNull() } ?: MilkKind.DEVONDALE_FULL_CREAM_UHT

fun tempOf(name: String?): TemperatureLevel =
    name?.let { runCatching { TemperatureLevel.valueOf(it) }.getOrNull() } ?: TemperatureLevel.NORMAL

fun roastOf(name: String?): RoastLevel =
    name?.let { runCatching { RoastLevel.valueOf(it) }.getOrNull() } ?: RoastLevel.MEDIUM

fun outcomeOf(name: String?): AdjustmentOutcome =
    name?.let { runCatching { AdjustmentOutcome.valueOf(it) }.getOrNull() } ?: AdjustmentOutcome.UNKNOWN

fun parameterOf(name: String?): AdjustmentParameter =
    name?.let { runCatching { AdjustmentParameter.valueOf(it) }.getOrNull() } ?: AdjustmentParameter.GRINDER

/** Map a seed JSON roast-level token (camelCase, matching the Swift raw value) to the enum. */
fun roastFromSeed(token: String): RoastLevel = when (token) {
    "light" -> RoastLevel.LIGHT
    "mediumLight" -> RoastLevel.MEDIUM_LIGHT
    "medium" -> RoastLevel.MEDIUM
    "mediumDark" -> RoastLevel.MEDIUM_DARK
    "dark" -> RoastLevel.DARK
    else -> RoastLevel.MEDIUM
}

fun tempFromSeed(token: String): TemperatureLevel = when (token) {
    "low" -> TemperatureLevel.LOW
    "high" -> TemperatureLevel.HIGH
    else -> TemperatureLevel.NORMAL
}

// ---- BeanEntity ----------------------------------------------------------------------

val BeanEntity.recommendedSettings: MachineSettings
    get() = MachineSettings(recGrinder, recStrength, recVolumeML, recMilkSeconds, tempOf(recTemperature))

val BeanEntity.roastLevelEnum: RoastLevel get() = roastOf(roastLevel)

fun BeanEntity.freshness(nowMillis: Long = System.currentTimeMillis()): Freshness =
    FreshnessCalculator.assess(roastDateMillis, nowMillis)

fun BeanEntity.snapshot(): BeanSnapshot = BeanSnapshot(
    id = slug,
    name = name,
    roaster = roaster,
    roastLevel = roastOf(roastLevel),
    milkFriendly = milkFriendly,
    flavourNotes = flavourNotes,
    recommendedSettings = recommendedSettings,
)

// ---- RecipeEntity --------------------------------------------------------------------

val RecipeEntity.settings: MachineSettings
    get() = MachineSettings(grinder, strength, volumeML, milkSeconds, tempOf(temperature))

// ---- HistoryEntity -------------------------------------------------------------------

val HistoryEntity.beforeSettings: MachineSettings
    get() = MachineSettings(beforeGrinder, beforeStrength, beforeVolumeML, beforeMilkSeconds, tempOf(beforeTemperature))

val HistoryEntity.afterSettings: MachineSettings
    get() = MachineSettings(afterGrinder, afterStrength, afterVolumeML, afterMilkSeconds, tempOf(afterTemperature))

val HistoryEntity.symptomList: List<Symptom>
    get() = symptoms.mapNotNull { runCatching { Symptom.valueOf(it) }.getOrNull() }

fun HistoryEntity.snapshot(): HistorySnapshot = HistorySnapshot(
    dateMillis = dateMillis,
    beforeSettings = beforeSettings,
    afterSettings = afterSettings,
    symptoms = symptomList,
    primaryAdjustmentParameter = parameterOf(primaryParameter),
    outcome = outcomeOf(outcome),
    beanName = beanName,
    drink = drinkOf(drink),
)
