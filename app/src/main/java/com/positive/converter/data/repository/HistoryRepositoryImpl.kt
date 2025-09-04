package com.positive.converter.data.repository

import com.positive.converter.data.local.database.HistoryDao
import com.positive.converter.data.local.database.HistoryEntity
import com.positive.converter.domain.model.ConversionHistory
import com.positive.converter.domain.repository.HistoryRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class HistoryRepositoryImpl @Inject constructor(
    private val historyDao: HistoryDao
) : HistoryRepository {
    
    override fun getAllHistory(): Flow<List<ConversionHistory>> {
        return historyDao.getAllHistory().map { entities ->
            entities.map { entity ->
                ConversionHistory(
                    id = entity.id,
                    originalText = entity.originalText,
                    convertedText = entity.convertedText,
                    timestamp = entity.timestamp
                )
            }
        }
    }
    
    override suspend fun saveHistory(originalText: String, convertedText: String) {
        val entity = HistoryEntity(
            originalText = originalText,
            convertedText = convertedText,
            timestamp = System.currentTimeMillis()
        )
        historyDao.insertHistory(entity)
    }
    
    override suspend fun deleteHistory(history: ConversionHistory) {
        val entity = HistoryEntity(
            id = history.id,
            originalText = history.originalText,
            convertedText = history.convertedText,
            timestamp = history.timestamp
        )
        historyDao.deleteHistory(entity)
    }
    
    override suspend fun deleteAllHistory() {
        historyDao.deleteAllHistory()
    }
}