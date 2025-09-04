# フェーズ1: プロジェクト初期設定

## 目的
Androidプロジェクトの基本構造を作成し、必要な依存関係を設定する

## 作業項目

### 1. プロジェクト作成
- [ ] Android Studioで新規プロジェクト作成
  - Template: Empty Activity
  - Name: PositiveConverter
  - Package: com.positive.converter
  - Language: Kotlin
  - Minimum SDK: API 24

### 2. Gradle設定
- [ ] プロジェクトレベルbuild.gradle.kts更新
- [ ] アプリレベルbuild.gradle.kts設定
  - Jetpack Compose依存関係
  - Room Database
  - Hilt
  - Coroutines

### 3. 基本パッケージ構造作成
```
com.positive.converter/
├── ui/
├── domain/
├── data/
└── di/
```

### 4. 必要なファイル
- [ ] `build.gradle.kts` (app)
- [ ] `build.gradle.kts` (project)
- [ ] `MainActivity.kt`
- [ ] `Application.kt`
- [ ] `AndroidManifest.xml`

## 実装コード

### app/build.gradle.kts
```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("kotlin-kapt")
    id("dagger.hilt.android.plugin")
}

android {
    namespace = "com.positive.converter"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.positive.converter"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.8"
    }
}

dependencies {
    // Compose
    implementation("androidx.compose.ui:ui:1.5.4")
    implementation("androidx.compose.material3:material3:1.1.2")
    implementation("androidx.compose.ui:ui-tooling-preview:1.5.4")
    implementation("androidx.navigation:navigation-compose:2.7.6")
    
    // Room
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    kapt("androidx.room:room-compiler:2.6.1")
    
    // Hilt
    implementation("com.google.dagger:hilt-android:2.48")
    kapt("com.google.dagger:hilt-compiler:2.48")
    implementation("androidx.hilt:hilt-navigation-compose:1.1.0")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    
    // ViewModel
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
}
```

## 完了条件
- [ ] プロジェクトがビルドできる
- [ ] 基本的なComposeアプリが起動する
- [ ] パッケージ構造が作成されている