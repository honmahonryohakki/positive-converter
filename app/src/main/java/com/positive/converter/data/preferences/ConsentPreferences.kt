package com.positive.converter.data.preferences

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "consent_preferences")

@Singleton
class ConsentPreferences @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val ANALYTICS_CONSENT_KEY = booleanPreferencesKey("analytics_consent")
    private val CONSENT_TIMESTAMP_KEY = longPreferencesKey("consent_timestamp")
    private val CONSENT_SHOWN_KEY = booleanPreferencesKey("consent_shown")

    val analyticsConsentFlow: Flow<Boolean> = context.dataStore.data
        .map { preferences ->
            preferences[ANALYTICS_CONSENT_KEY] ?: false
        }

    val consentShownFlow: Flow<Boolean> = context.dataStore.data
        .map { preferences ->
            preferences[CONSENT_SHOWN_KEY] ?: false
        }

    suspend fun setAnalyticsConsent(consent: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[ANALYTICS_CONSENT_KEY] = consent
            preferences[CONSENT_TIMESTAMP_KEY] = System.currentTimeMillis()
            preferences[CONSENT_SHOWN_KEY] = true
        }
    }

    suspend fun resetConsent() {
        context.dataStore.edit { preferences ->
            preferences.clear()
        }
    }
}