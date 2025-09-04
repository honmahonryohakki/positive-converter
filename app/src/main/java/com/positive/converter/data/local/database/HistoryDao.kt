package com.positive.converter.data.local.database

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface HistoryDao {
    @Query("SELECT * FROM conversion_history ORDER BY timestamp DESC LIMIT 100")
    fun getAllHistory(): Flow<List<HistoryEntity>>
    
    @Insert
    suspend fun insertHistory(history: HistoryEntity)
    
    @Delete
    suspend fun deleteHistory(history: HistoryEntity)
    
    @Query("DELETE FROM conversion_history")
    suspend fun deleteAllHistory()
    
    @Query("SELECT * FROM conversion_history WHERE id = :id")
    suspend fun getHistoryById(id: Long): HistoryEntity?
}