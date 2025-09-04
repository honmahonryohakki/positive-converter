package com.positive.converter.data.repository

import com.positive.converter.data.converter.ConversionEngine
import com.positive.converter.domain.repository.ConversionRepository
import javax.inject.Inject

class ConversionRepositoryImpl @Inject constructor(
    private val conversionEngine: ConversionEngine
) : ConversionRepository {
    override suspend fun convertText(text: String): String {
        return conversionEngine.convert(text)
    }
}