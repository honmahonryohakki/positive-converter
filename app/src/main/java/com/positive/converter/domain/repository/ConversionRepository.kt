package com.positive.converter.domain.repository

interface ConversionRepository {
    suspend fun convertText(text: String): String
}