package com.positive.converter.domain.repository

import com.positive.converter.domain.model.ConversionHistory
import kotlinx.coroutines.flow.Flow

interface HistoryRepository {
    fun getAllHistory(): Flow<List<ConversionHistory>>
    suspend fun saveHistory(originalText: String, convertedText: String)
    suspend fun deleteHistory(history: ConversionHistory)
    suspend fun deleteAllHistory()
}