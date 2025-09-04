# ポジティブ変換アプリ アーキテクチャ設計書

## 1. アーキテクチャ概要
**採用アーキテクチャ**: MVVM (Model-View-ViewModel) + Repository Pattern
**理由**: 
- UIとビジネスロジックの分離
- テスタビリティの向上
- データソースの抽象化

## 2. レイヤー構成

```
┌─────────────────────────────────────────┐
│           View Layer (UI)               │
│  - Activities                           │
│  - Fragments                            │
│  - Composables (Jetpack Compose)        │
└─────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────┐
│         ViewModel Layer                 │
│  - MainViewModel                        │
│  - HistoryViewModel                     │
│  - SettingsViewModel                    │
└─────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────┐
│         Repository Layer                │
│  - ConversionRepository                 │
│  - HistoryRepository                    │
│  - SettingsRepository                   │
└─────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────┐
│         Data Layer                      │
│  - Room Database                        │
│  - SharedPreferences                    │
│  - ConversionEngine                     │
└─────────────────────────────────────────┘
```

## 3. パッケージ構造

```
com.positive.converter/
├── ui/
│   ├── main/
│   │   ├── MainActivity.kt
│   │   ├── MainScreen.kt
│   │   └── MainViewModel.kt
│   ├── history/
│   │   ├── HistoryScreen.kt
│   │   └── HistoryViewModel.kt
│   ├── settings/
│   │   ├── SettingsScreen.kt
│   │   └── SettingsViewModel.kt
│   ├── theme/
│   │   ├── Color.kt
│   │   ├── Theme.kt
│   │   └── Type.kt
│   └── components/
│       ├── ConversionCard.kt
│       └── HistoryItem.kt
├── domain/
│   ├── model/
│   │   ├── ConversionHistory.kt
│   │   ├── ConversionRule.kt
│   │   └── AppSettings.kt
│   ├── repository/
│   │   ├── ConversionRepository.kt
│   │   ├── HistoryRepository.kt
│   │   └── SettingsRepository.kt
│   └── usecase/
│       ├── ConvertTextUseCase.kt
│       ├── SaveHistoryUseCase.kt
│       └── GetHistoryUseCase.kt
├── data/
│   ├── local/
│   │   ├── database/
│   │   │   ├── AppDatabase.kt
│   │   │   ├── HistoryDao.kt
│   │   │   └── HistoryEntity.kt
│   │   └── preferences/
│   │       └── PreferencesManager.kt
│   ├── repository/
│   │   ├── ConversionRepositoryImpl.kt
│   │   ├── HistoryRepositoryImpl.kt
│   │   └── SettingsRepositoryImpl.kt
│   └── converter/
│       ├── ConversionEngine.kt
│       ├── ConversionRules.kt
│       └── WordDictionary.kt
└── di/
    └── AppModule.kt
```

## 4. 主要コンポーネント

### 4.1 ConversionEngine
```kotlin
class ConversionEngine {
    fun convert(text: String): String
    private fun detectNegativeWords(text: String): List<String>
    private fun applyConversionRules(text: String): String
}
```

### 4.2 Database Schema
```sql
CREATE TABLE conversion_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    original_text TEXT NOT NULL,
    converted_text TEXT NOT NULL,
    timestamp INTEGER NOT NULL
);
```

### 4.3 依存性注入 (Hilt)
- ViewModelの注入
- Repositoryの注入
- DatabaseとDAOの提供

## 5. 技術スタック

### 5.1 Core
- **言語**: Kotlin 1.9.x
- **最小SDK**: API 24 (Android 7.0)
- **ターゲットSDK**: API 34 (Android 14)

### 5.2 UI
- **Jetpack Compose**: 最新安定版
- **Material3**: デザインシステム
- **Navigation Compose**: 画面遷移

### 5.3 Architecture Components
- **ViewModel**: UI状態管理
- **LiveData/StateFlow**: データ監視
- **Room**: ローカルDB
- **Hilt**: 依存性注入

### 5.4 その他
- **Coroutines**: 非同期処理
- **JUnit**: ユニットテスト
- **Espresso**: UIテスト

## 6. データフロー

```
User Input → View → ViewModel → UseCase → Repository → Data Source
                ↑                                           ↓
                ←────────────── State/LiveData ←───────────
```

## 7. 状態管理

### 7.1 UI State
```kotlin
data class MainUiState(
    val inputText: String = "",
    val convertedText: String = "",
    val isLoading: Boolean = false,
    val error: String? = null,
    val charCount: Int = 0
)
```

### 7.2 State更新フロー
1. ユーザー入力
2. ViewModelで状態更新
3. Compose Recomposition
4. UI更新