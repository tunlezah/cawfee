package com.cawfee.data

import com.cawfee.data.local.MaintenanceTaskEntity
import com.cawfee.data.local.WaterProfileEntity
import java.util.UUID

/**
 * Default seed content, ported 1:1 from SeedLoader.swift (`defaultWaterProfiles` and
 * `defaultMaintenanceTasks`). Inserted on first launch when the corresponding table is
 * empty. `iconKey` mirrors the Swift SF Symbol name for documentation parity; the Android
 * UI maps it to a Material icon.
 */
object SeedData {

    fun waterProfiles(): List<WaterProfileEntity> = listOf(
        WaterProfileEntity(
            id = UUID.randomUUID().toString(),
            name = "Canberra Tap (ACT)",
            detail = "Approx. Icon Water average — soft, low-bicarbonate.",
            calcium = 20.0, magnesium = 10.0, bicarbonate = 30.0, totalHardness = 55.0,
            isDefault = true, isSeeded = true, sortOrder = 0,
        ),
        WaterProfileEntity(
            id = UUID.randomUUID().toString(),
            name = "Third Wave Water (Espresso)",
            detail = "Distilled + TWW espresso mineral packet.",
            calcium = 50.0, magnesium = 18.0, bicarbonate = 50.0, totalHardness = 150.0,
            isDefault = false, isSeeded = true, sortOrder = 1,
        ),
        WaterProfileEntity(
            id = UUID.randomUUID().toString(),
            name = "SCA Target",
            detail = "Mid-point of SCA recommended brewing-water range.",
            calcium = 40.0, magnesium = 12.0, bicarbonate = 50.0, totalHardness = 100.0,
            isDefault = false, isSeeded = true, sortOrder = 2,
        ),
    )

    fun maintenanceTasks(): List<MaintenanceTaskEntity> = listOf(
        MaintenanceTaskEntity(
            id = UUID.randomUUID().toString(),
            name = "Backflush (water)",
            detail = "Blind-basket backflush with water to clear the group.",
            iconKey = "arrow.triangle.2.circlepath",
            intervalDays = 3, intervalShots = 20,
            lastCompletedMillis = null, lastCompletedShotCount = 0,
            isSeeded = true, sortOrder = 0,
        ),
        MaintenanceTaskEntity(
            id = UUID.randomUUID().toString(),
            name = "Backflush (detergent)",
            detail = "Backflush with espresso machine cleaner (e.g. Cafiza).",
            iconKey = "bubbles.and.sparkles",
            intervalDays = 14, intervalShots = 200,
            lastCompletedMillis = null, lastCompletedShotCount = 0,
            isSeeded = true, sortOrder = 1,
        ),
        MaintenanceTaskEntity(
            id = UUID.randomUUID().toString(),
            name = "Descale",
            detail = "ACT water is soft, so descaling can be infrequent — but don't skip it.",
            iconKey = "drop.triangle",
            intervalDays = 120, intervalShots = null,
            lastCompletedMillis = null, lastCompletedShotCount = 0,
            isSeeded = true, sortOrder = 2,
        ),
        MaintenanceTaskEntity(
            id = UUID.randomUUID().toString(),
            name = "Clean shower screen",
            detail = "Remove and scrub the group head shower screen.",
            iconKey = "shower",
            intervalDays = 14, intervalShots = null,
            lastCompletedMillis = null, lastCompletedShotCount = 0,
            isSeeded = true, sortOrder = 3,
        ),
        MaintenanceTaskEntity(
            id = UUID.randomUUID().toString(),
            name = "Replace group gasket",
            detail = "Swap the portafilter gasket when it hardens or leaks.",
            iconKey = "circle.dashed",
            intervalDays = 365, intervalShots = null,
            lastCompletedMillis = null, lastCompletedShotCount = 0,
            isSeeded = true, sortOrder = 4,
        ),
        MaintenanceTaskEntity(
            id = UUID.randomUUID().toString(),
            name = "Clean grinder burrs",
            detail = "Brush out fines and old grounds from the burrs and chute.",
            iconKey = "fan",
            intervalDays = 30, intervalShots = null,
            lastCompletedMillis = null, lastCompletedShotCount = 0,
            isSeeded = true, sortOrder = 5,
        ),
    )
}
