package com.positive.converter.data.local.database

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "conversion_history")
data class HistoryEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    @ColumnInfo(name = "original_text")
    val originalText: String,
    @ColumnInfo(name = "converted_text")
    val convertedText: String,
    @ColumnInfo(name = "timestamp")
    val timestamp: Long
)