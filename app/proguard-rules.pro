# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Room
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-dontwarn androidx.room.paging.**

# Hilt
-keep class dagger.hilt.** { *; }
-keep class javax.inject.** { *; }
-keep class * extends dagger.hilt.android.HiltAndroidApp

# Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory { }
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler { }

# Compose
-keep class androidx.compose.** { *; }
-dontwarn androidx.compose.**

# Keep data classes used in Room
-keep class com.positive.converter.domain.model.** { *; }
-keep class com.positive.converter.data.local.database.** { *; }

# Keep line numbers for crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile