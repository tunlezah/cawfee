package com.cawfee.di

import android.content.Context
import androidx.room.Room
import com.cawfee.data.local.BeanDao
import com.cawfee.data.local.CawfeeDatabase
import com.cawfee.data.local.HistoryDao
import com.cawfee.data.local.MaintenanceDao
import com.cawfee.data.local.RecipeDao
import com.cawfee.data.local.ShotDao
import com.cawfee.data.local.TastingNoteDao
import com.cawfee.data.local.WaterDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): CawfeeDatabase =
        Room.databaseBuilder(context, CawfeeDatabase::class.java, "cawfee.db")
            .fallbackToDestructiveMigration()
            .build()

    @Provides fun provideShotDao(db: CawfeeDatabase): ShotDao = db.shotDao()
    @Provides fun provideBeanDao(db: CawfeeDatabase): BeanDao = db.beanDao()
    @Provides fun provideRecipeDao(db: CawfeeDatabase): RecipeDao = db.recipeDao()
    @Provides fun provideTastingNoteDao(db: CawfeeDatabase): TastingNoteDao = db.tastingNoteDao()
    @Provides fun provideHistoryDao(db: CawfeeDatabase): HistoryDao = db.historyDao()
    @Provides fun provideMaintenanceDao(db: CawfeeDatabase): MaintenanceDao = db.maintenanceDao()
    @Provides fun provideWaterDao(db: CawfeeDatabase): WaterDao = db.waterDao()
}
