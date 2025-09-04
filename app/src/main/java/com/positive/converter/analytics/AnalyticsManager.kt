package com.positive.converter.analytics

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AnalyticsManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    // Firebase無効化: ローカル分析のみ

    fun logTextConverted(originalText: String, convertedText: String) {
        // ローカル分析: ログのみ
        println("Analytics: Text converted - original: ${originalText.length}, converted: ${convertedText.length}")
    }

    fun logScreenView(screenName: String) {
        println("Analytics: Screen view - $screenName")
    }

    fun logHistoryAction(action: HistoryAction) {
        println("Analytics: History action - ${action.name}")
    }

    fun logShareAction(contentType: String) {
        println("Analytics: Share action - $contentType")
    }

    fun logCopyAction() {
        println("Analytics: Copy to clipboard")
    }

    fun logSettingsChange(settingName: String, newValue: String) {
        println("Analytics: Settings changed - $settingName: $newValue")
    }

    fun logAppOpen() {
        println("Analytics: App opened")
    }

    fun logError(errorType: String, errorMessage: String) {
        println("Analytics: Error - $errorType: $errorMessage")
    }

    fun setUserProperty(name: String, value: String) {
        println("Analytics: User property - $name: $value")
    }

    fun setAnalyticsCollectionEnabled(enabled: Boolean) {
        println("Analytics: Collection enabled - $enabled")
    }
}

enum class HistoryAction {
    VIEW,
    DELETE_SINGLE,
    DELETE_ALL,
    COPY_FROM_HISTORY,
    SHARE_FROM_HISTORY
}