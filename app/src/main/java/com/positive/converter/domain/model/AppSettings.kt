package com.positive.converter.domain.model

data class AppSettings(
    val isDarkMode: Boolean = false,
    val fontSize: FontSize = FontSize.MEDIUM
)

enum class FontSize(val scaleFactor: Float) {
    SMALL(0.9f),
    MEDIUM(1.0f),
    LARGE(1.1f),
    EXTRA_LARGE(1.2f)
}