package com.cawfee.data.local

import androidx.room.Database
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.RoomDatabase
import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Update
import androidx.room.Delete
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.TypeConverter
import androidx.room.TypeConverters
import kotlinx.coroutines.flow.Flow

/**
 * Room persistence layer for Cawfee. Each entity is a 1:1 port of one of the macOS
 * SwiftData @Model types (DialedInCoffee/Models/*.swift). Domain enums are stored as
 * their Kotlin `name`; list fields use [Converters].
 */

// ---------------------------------------------------------------------------------------
// Type converters
// ---------------------------------------------------------------------------------------

class Converters {
    /** Lists are stored newline-delimited; descriptors/notes never contain newlines. */
    @TypeConverter
    fun fromStringList(value: List<String>): String = value.joinToString("\n")

    @TypeConverter
    fun toStringList(value: String): List<String> =
        if (value.isEmpty()) emptyList() else value.split("\n")
}

// ---------------------------------------------------------------------------------------
// Shot (espresso shot timer record) — ported from Shot.swift
// ---------------------------------------------------------------------------------------

@Entity(tableName = "shots")
data class ShotEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val dateMillis: Long,
    val beanName: String?,
    val beanSlug: String? = null,
    val drink: String,
    val doseGrams: Double,
    val yieldGrams: Double,
    val preInfusionSeconds: Double,
    val totalSeconds: Double,
    val grindSetting: Int? = null,
    val rating: Int,
    val notes: String,
) {
    val ratio: Double get() = if (doseGrams > 0) yieldGrams / doseGrams else 0.0
}

@Dao
interface ShotDao {
    @Query("SELECT * FROM shots ORDER BY dateMillis DESC")
    fun observeAll(): Flow<List<ShotEntity>>

    @Query("SELECT COUNT(*) FROM shots")
    fun observeCount(): Flow<Int>

    @Insert
    suspend fun insert(shot: ShotEntity): Long

    @Delete
    suspend fun delete(shot: ShotEntity)
}

// ---------------------------------------------------------------------------------------
// BeanProfile — ported from BeanProfile.swift
// ---------------------------------------------------------------------------------------

@Entity(tableName = "beans")
data class BeanEntity(
    @PrimaryKey val slug: String,
    val name: String,
    val roaster: String,
    val roastLevel: String,
    val milkFriendly: Boolean,
    val flavourNotes: List<String>,
    val notes: String,
    val recGrinder: Int,
    val recStrength: Int,
    val recVolumeML: Int,
    val recMilkSeconds: Int,
    val recTemperature: String,
    val createdAtMillis: Long,
    val isSeeded: Boolean,
    val roastDateMillis: Long?,
    val openedDateMillis: Long?,
    val currentGrindSetting: Int?,
)

@Dao
interface BeanDao {
    @Query("SELECT * FROM beans ORDER BY roaster, name")
    fun observeAll(): Flow<List<BeanEntity>>

    @Query("SELECT COUNT(*) FROM beans")
    suspend fun count(): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(bean: BeanEntity)

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAll(beans: List<BeanEntity>)

    @Update
    suspend fun update(bean: BeanEntity)

    @Delete
    suspend fun delete(bean: BeanEntity)
}

// ---------------------------------------------------------------------------------------
// Recipe — ported from Recipe.swift
// ---------------------------------------------------------------------------------------

@Entity(tableName = "recipes")
data class RecipeEntity(
    @PrimaryKey val id: String,
    val name: String,
    val drink: String,
    val milkKind: String,
    val grinder: Int,
    val strength: Int,
    val volumeML: Int,
    val milkSeconds: Int,
    val temperature: String,
    val isFavourite: Boolean,
    val isLastGood: Boolean,
    val createdAtMillis: Long,
    val notes: String,
    val beanSlug: String?,
)

@Dao
interface RecipeDao {
    @Query("SELECT * FROM recipes ORDER BY createdAtMillis DESC")
    fun observeAll(): Flow<List<RecipeEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(recipe: RecipeEntity)

    @Delete
    suspend fun delete(recipe: RecipeEntity)

    /** Clear every last-good flag (single-baseline invariant). */
    @Query("UPDATE recipes SET isLastGood = 0")
    suspend fun clearLastGood()
}

// ---------------------------------------------------------------------------------------
// TastingNote — ported from TastingNote.swift
// ---------------------------------------------------------------------------------------

@Entity(tableName = "tasting_notes")
data class TastingNoteEntity(
    @PrimaryKey val id: String,
    val dateMillis: Long,
    val beanName: String?,
    val beanSlug: String?,
    val drink: String,
    val descriptors: List<String>,
    val body: Int,
    val acidity: Int,
    val sweetness: Int,
    val bitterness: Int,
    val rating: Int,
    val freeText: String,
)

@Dao
interface TastingNoteDao {
    @Query("SELECT * FROM tasting_notes ORDER BY dateMillis DESC")
    fun observeAll(): Flow<List<TastingNoteEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(note: TastingNoteEntity)

    @Delete
    suspend fun delete(note: TastingNoteEntity)
}

// ---------------------------------------------------------------------------------------
// AdjustmentHistoryEntry — ported from AdjustmentHistoryEntry.swift
// ---------------------------------------------------------------------------------------

@Entity(tableName = "history")
data class HistoryEntity(
    @PrimaryKey val id: String,
    val dateMillis: Long,
    val drink: String,
    val beanName: String?,
    val symptoms: List<String>,
    val beforeGrinder: Int,
    val beforeStrength: Int,
    val beforeVolumeML: Int,
    val beforeMilkSeconds: Int,
    val beforeTemperature: String,
    val afterGrinder: Int,
    val afterStrength: Int,
    val afterVolumeML: Int,
    val afterMilkSeconds: Int,
    val afterTemperature: String,
    val primaryParameter: String,
    val outcome: String,
    val rationale: String,
    val confidence: Double,
)

@Dao
interface HistoryDao {
    @Query("SELECT * FROM history ORDER BY dateMillis DESC")
    fun observeAll(): Flow<List<HistoryEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entry: HistoryEntity)

    @Delete
    suspend fun delete(entry: HistoryEntity)
}

// ---------------------------------------------------------------------------------------
// MaintenanceTask — ported from MaintenanceTask.swift
// ---------------------------------------------------------------------------------------

@Entity(tableName = "maintenance_tasks")
data class MaintenanceTaskEntity(
    @PrimaryKey val id: String,
    val name: String,
    val detail: String,
    val iconKey: String,
    val intervalDays: Int?,
    val intervalShots: Int?,
    val lastCompletedMillis: Long?,
    val lastCompletedShotCount: Int,
    val isSeeded: Boolean,
    val sortOrder: Int,
)

@Dao
interface MaintenanceDao {
    @Query("SELECT * FROM maintenance_tasks ORDER BY sortOrder, name")
    fun observeAll(): Flow<List<MaintenanceTaskEntity>>

    @Query("SELECT COUNT(*) FROM maintenance_tasks")
    suspend fun count(): Int

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAll(tasks: List<MaintenanceTaskEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(task: MaintenanceTaskEntity)

    @Delete
    suspend fun delete(task: MaintenanceTaskEntity)
}

// ---------------------------------------------------------------------------------------
// WaterProfile — ported from WaterProfile.swift
// ---------------------------------------------------------------------------------------

@Entity(tableName = "water_profiles")
data class WaterProfileEntity(
    @PrimaryKey val id: String,
    val name: String,
    val detail: String,
    val calcium: Double,
    val magnesium: Double,
    val bicarbonate: Double,
    val totalHardness: Double,
    val isDefault: Boolean,
    val isSeeded: Boolean,
    val sortOrder: Int,
)

@Dao
interface WaterDao {
    @Query("SELECT * FROM water_profiles ORDER BY sortOrder, name")
    fun observeAll(): Flow<List<WaterProfileEntity>>

    @Query("SELECT COUNT(*) FROM water_profiles")
    suspend fun count(): Int

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAll(profiles: List<WaterProfileEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(profile: WaterProfileEntity)

    @Delete
    suspend fun delete(profile: WaterProfileEntity)

    @Query("UPDATE water_profiles SET isDefault = 0")
    suspend fun clearDefault()
}

// ---------------------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------------------

@Database(
    entities = [
        ShotEntity::class,
        BeanEntity::class,
        RecipeEntity::class,
        TastingNoteEntity::class,
        HistoryEntity::class,
        MaintenanceTaskEntity::class,
        WaterProfileEntity::class,
    ],
    version = 2,
    exportSchema = true,
)
@TypeConverters(Converters::class)
abstract class CawfeeDatabase : RoomDatabase() {
    abstract fun shotDao(): ShotDao
    abstract fun beanDao(): BeanDao
    abstract fun recipeDao(): RecipeDao
    abstract fun tastingNoteDao(): TastingNoteDao
    abstract fun historyDao(): HistoryDao
    abstract fun maintenanceDao(): MaintenanceDao
    abstract fun waterDao(): WaterDao
}
