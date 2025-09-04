package com.positive.converter.di

import android.content.Context
import androidx.room.Room
import com.positive.converter.analytics.AnalyticsManager
import com.positive.converter.data.converter.ConversionEngine
import com.positive.converter.data.local.database.AppDatabase
import com.positive.converter.data.local.database.HistoryDao
import com.positive.converter.data.preferences.ConsentPreferences
import com.positive.converter.data.repository.ConversionRepositoryImpl
import com.positive.converter.data.repository.HistoryRepositoryImpl
import com.positive.converter.domain.repository.ConversionRepository
import com.positive.converter.domain.repository.HistoryRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {
    
    @Provides
    @Singleton
    fun provideAppDatabase(
        @ApplicationContext context: Context
    ): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "positive_converter_database"
        ).build()
    }
    
    @Provides
    @Singleton
    fun provideHistoryDao(database: AppDatabase): HistoryDao {
        return database.historyDao()
    }
    
    @Provides
    @Singleton
    fun provideConversionEngine(): ConversionEngine {
        return ConversionEngine()
    }
    
    @Provides
    @Singleton
    fun provideConversionRepository(
        conversionEngine: ConversionEngine
    ): ConversionRepository {
        return ConversionRepositoryImpl(conversionEngine)
    }
    
    @Provides
    @Singleton
    fun provideHistoryRepository(
        historyDao: HistoryDao
    ): HistoryRepository {
        return HistoryRepositoryImpl(historyDao)
    }
    
    @Provides
    @Singleton
    fun provideAnalyticsManager(
        @ApplicationContext context: Context
    ): AnalyticsManager {
        return AnalyticsManager(context)
    }
    
    @Provides
    @Singleton
    fun provideConsentPreferences(
        @ApplicationContext context: Context
    ): ConsentPreferences {
        return ConsentPreferences(context)
    }
}