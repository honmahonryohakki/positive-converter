package com.positive.converter.analytics

import android.content.Context
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.analytics.ktx.analytics
import com.google.firebase.analytics.ktx.logEvent
import com.google.firebase.ktx.Firebase
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AnalyticsManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val firebaseAnalytics: FirebaseAnalytics = Firebase.analytics

    fun logTextConverted(originalText: String, convertedText: String) {
        firebaseAnalytics.logEvent("text_converted") {
            param("original_length", originalText.length.toLong())
            param("converted_length", convertedText.length.toLong())
            param("word_count", originalText.split(" ").size.toLong())
        }
    }

    fun logScreenView(screenName: String) {
        firebaseAnalytics.logEvent(FirebaseAnalytics.Event.SCREEN_VIEW) {
            param(FirebaseAnalytics.Param.SCREEN_NAME, screenName)
            param(FirebaseAnalytics.Param.SCREEN_CLASS, "${screenName}Screen")
        }
    }

    fun logHistoryAction(action: HistoryAction) {
        firebaseAnalytics.logEvent("history_action") {
            param("action_type", action.name.lowercase())
        }
    }

    fun logShareAction(contentType: String) {
        firebaseAnalytics.logEvent(FirebaseAnalytics.Event.SHARE) {
            param(FirebaseAnalytics.Param.CONTENT_TYPE, contentType)
            param(FirebaseAnalytics.Param.METHOD, "app_share")
        }
    }

    fun logCopyAction() {
        firebaseAnalytics.logEvent("copy_to_clipboard") {
            param("content_type", "converted_text")
        }
    }

    fun logSettingsChange(settingName: String, newValue: String) {
        firebaseAnalytics.logEvent("settings_changed") {
            param("setting_name", settingName)
            param("new_value", newValue)
        }
    }

    fun logAppOpen() {
        firebaseAnalytics.logEvent(FirebaseAnalytics.Event.APP_OPEN) {
            param("timestamp", System.currentTimeMillis())
        }
    }

    fun logError(errorType: String, errorMessage: String) {
        firebaseAnalytics.logEvent("app_error") {
            param("error_type", errorType)
            param("error_message", errorMessage.take(100)) // Limit message length
        }
    }

    fun setUserProperty(name: String, value: String) {
        firebaseAnalytics.setUserProperty(name, value)
    }

    fun setAnalyticsCollectionEnabled(enabled: Boolean) {
        firebaseAnalytics.setAnalyticsCollectionEnabled(enabled)
    }
}

enum class HistoryAction {
    VIEW,
    DELETE_SINGLE,
    DELETE_ALL,
    COPY_FROM_HISTORY,
    SHARE_FROM_HISTORY
}