package com.positive.converter.domain.model

data class ConversionHistory(
    val id: Long = 0,
    val originalText: String,
    val convertedText: String,
    val timestamp: Long = System.currentTimeMillis()
)