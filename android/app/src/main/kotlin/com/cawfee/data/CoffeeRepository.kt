package com.cawfee.data

import android.content.Context
import com.cawfee.data.local.BeanDao
import com.cawfee.data.local.BeanEntity
import com.cawfee.data.local.HistoryDao
import com.cawfee.data.local.HistoryEntity
import com.cawfee.data.local.MaintenanceDao
import com.cawfee.data.local.MaintenanceTaskEntity
import com.cawfee.data.local.RecipeDao
import com.cawfee.data.local.RecipeEntity
import com.cawfee.data.local.ShotDao
import com.cawfee.data.local.ShotEntity
import com.cawfee.data.local.TastingNoteDao
import com.cawfee.data.local.TastingNoteEntity
import com.cawfee.data.local.WaterDao
import com.cawfee.data.local.WaterProfileEntity
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Single facade over every Room DAO plus first-launch seeding. Mirrors the role of
 * SeedLoader.swift + the SwiftData @Query usage in the macOS views. ViewModels depend on
 * this rather than on DAOs directly.
 */
@Singleton
class CoffeeRepository @Inject constructor(
    @ApplicationContext private val context: Context,
    private val beanDao: BeanDao,
    private val recipeDao: RecipeDao,
    private val tastingNoteDao: TastingNoteDao,
    private val historyDao: HistoryDao,
    private val maintenanceDao: MaintenanceDao,
    private val waterDao: WaterDao,
    private val shotDao: ShotDao,
) {
    // ---- Observable streams ----------------------------------------------------------
    val beans: Flow<List<BeanEntity>> = beanDao.observeAll()
    val recipes: Flow<List<RecipeEntity>> = recipeDao.observeAll()
    val tastingNotes: Flow<List<TastingNoteEntity>> = tastingNoteDao.observeAll()
    val history: Flow<List<HistoryEntity>> = historyDao.observeAll()
    val maintenanceTasks: Flow<List<MaintenanceTaskEntity>> = maintenanceDao.observeAll()
    val waterProfiles: Flow<List<WaterProfileEntity>> = waterDao.observeAll()
    val shots: Flow<List<ShotEntity>> = shotDao.observeAll()
    val shotCount: Flow<Int> = shotDao.observeCount()

    // ---- Beans -----------------------------------------------------------------------
    suspend fun upsertBean(bean: BeanEntity) = beanDao.upsert(bean)
    suspend fun updateBean(bean: BeanEntity) = beanDao.update(bean)
    suspend fun deleteBean(bean: BeanEntity) = beanDao.delete(bean)

    // ---- Recipes ---------------------------------------------------------------------
    suspend fun upsertRecipe(recipe: RecipeEntity) = recipeDao.upsert(recipe)
    suspend fun deleteRecipe(recipe: RecipeEntity) = recipeDao.delete(recipe)

    /** Saving a "last good" recipe clears the flag on every other recipe first. */
    suspend fun saveRecipeAsLastGood(recipe: RecipeEntity) {
        recipeDao.clearLastGood()
        recipeDao.upsert(recipe.copy(isLastGood = true))
    }

    suspend fun setRecipeLastGood(recipe: RecipeEntity, lastGood: Boolean) {
        if (lastGood) recipeDao.clearLastGood()
        recipeDao.upsert(recipe.copy(isLastGood = lastGood))
    }

    // ---- Tasting notes ---------------------------------------------------------------
    suspend fun upsertTastingNote(note: TastingNoteEntity) = tastingNoteDao.upsert(note)
    suspend fun deleteTastingNote(note: TastingNoteEntity) = tastingNoteDao.delete(note)

    // ---- History ---------------------------------------------------------------------
    suspend fun upsertHistory(entry: HistoryEntity) = historyDao.upsert(entry)
    suspend fun deleteHistory(entry: HistoryEntity) = historyDao.delete(entry)

    // ---- Maintenance -----------------------------------------------------------------
    suspend fun upsertTask(task: MaintenanceTaskEntity) = maintenanceDao.upsert(task)
    suspend fun deleteTask(task: MaintenanceTaskEntity) = maintenanceDao.delete(task)

    // ---- Water -----------------------------------------------------------------------
    suspend fun upsertWater(profile: WaterProfileEntity) = waterDao.upsert(profile)
    suspend fun deleteWater(profile: WaterProfileEntity) = waterDao.delete(profile)
    suspend fun makeWaterDefault(profile: WaterProfileEntity) {
        waterDao.clearDefault()
        waterDao.upsert(profile.copy(isDefault = true))
    }

    // ---- Shots -----------------------------------------------------------------------
    suspend fun insertShot(shot: ShotEntity) = shotDao.insert(shot)
    suspend fun deleteShot(shot: ShotEntity) = shotDao.delete(shot)

    // ---- Seeding (first launch) ------------------------------------------------------

    /** Idempotent: seeds beans (from assets/beans.json), water profiles and maintenance
     * tasks only when their tables are empty. Mirrors SeedLoader.bootstrapIfNeeded. */
    suspend fun seedIfNeeded() {
        if (waterDao.count() == 0) waterDao.insertAll(SeedData.waterProfiles())
        if (maintenanceDao.count() == 0) maintenanceDao.insertAll(SeedData.maintenanceTasks())
        if (beanDao.count() == 0) {
            runCatching { loadSeedBeans() }.getOrNull()?.let { beanDao.insertAll(it) }
        }
    }

    private fun loadSeedBeans(): List<BeanEntity> {
        val text = context.assets.open("beans.json").bufferedReader().use { it.readText() }
        val file = json.decodeFromString<BeanSeedFile>(text)
        val now = System.currentTimeMillis()
        return file.beans.map { dto ->
            BeanEntity(
                slug = dto.slug,
                name = dto.name,
                roaster = dto.roaster,
                roastLevel = roastFromSeed(dto.roastLevel).name,
                milkFriendly = dto.milkFriendly,
                flavourNotes = dto.flavourNotes,
                notes = dto.notes ?: "",
                recGrinder = dto.recommendedSettings.grinder,
                recStrength = dto.recommendedSettings.strength,
                recVolumeML = dto.recommendedSettings.volume,
                recMilkSeconds = dto.recommendedSettings.milkTime,
                recTemperature = tempFromSeed(dto.recommendedSettings.temp).name,
                createdAtMillis = now,
                isSeeded = true,
                roastDateMillis = null,
                openedDateMillis = null,
                currentGrindSetting = null,
            )
        }
    }

    private companion object {
        val json = Json { ignoreUnknownKeys = true }
    }
}

// ---- Seed JSON DTOs (match DialedInCoffee/Resources/Seed/beans.json) ------------------

@Serializable
private data class BeanSeedFile(val beans: List<BeanSeedDto>)

@Serializable
private data class BeanSeedDto(
    val slug: String,
    val name: String,
    val roaster: String,
    val roastLevel: String,
    val milkFriendly: Boolean,
    val flavourNotes: List<String>,
    val recommendedSettings: BeanSeedSettingsDto,
    val notes: String? = null,
    val origin: String? = null,
    val process: String? = null,
    val availability: String? = null,
)

@Serializable
private data class BeanSeedSettingsDto(
    val grinder: Int,
    val strength: Int,
    val volume: Int,
    @SerialName("milkTime") val milkTime: Int,
    val temp: String,
)
