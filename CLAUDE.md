# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ポジティブ変換アプリ - ネガティブなテキストをポジティブに変換するAndroidアプリケーション

## Architecture

- **Pattern**: MVVM + Repository Pattern
- **UI Framework**: Jetpack Compose
- **DI**: Hilt
- **Database**: Room
- **Async**: Kotlin Coroutines + Flow

## Project Structure

```
app/src/main/java/com/positive/converter/
├── data/           # Data layer (Repository実装, Database, Converter)
├── domain/         # Domain layer (Model, Repository interface)
├── ui/            # UI layer (Screen, ViewModel, Theme)
├── di/            # Dependency injection
└── MainActivity.kt
```

## Development Commands

### Build
```bash
# Windows
gradlew.bat assembleDebug

# Mac/Linux
./gradlew assembleDebug
```

### Run Tests
```bash
# Unit tests
./gradlew test

# Android tests
./gradlew connectedAndroidTest
```

### Clean Build
```bash
./gradlew clean build
```

## Key Features

1. **テキスト変換エンジン** (`ConversionEngine.kt`)
   - ネガティブワードの辞書ベース変換
   - パターンマッチングによる文脈考慮

2. **履歴管理** (Room Database)
   - 変換履歴の永続化
   - 最大100件まで保存

3. **UI** (Jetpack Compose)
   - Material Design 3
   - ダークモード対応
   - BottomNavigation

## Development Phases

各フェーズの詳細は `docs/` ディレクトリを参照:
- Phase 1: プロジェクト初期設定 → `docs/phase-1-setup.md`
- Phase 2: UI実装 → `docs/phase-2-ui.md`
- Phase 3: ロジック実装 → `docs/phase-3-logic.md`
- Phase 4: テスト最適化 → `docs/phase-4-test.md`

## Google Play Store & Analytics 対応

### Firebase統合済み
- Google Analytics for Firebase
- Crashlytics
- データ収集同意機能

### リリース対応
- App Bundle署名設定
- ProGuard最適化
- Google Play Console設定ガイド

### 必要な追加ファイル
```
app/google-services.json  # Firebaseコンソールからダウンロード
release.keystore         # Android Studioで生成
```

### 環境変数設定
```bash
export KEY_ALIAS=app-release
export KEY_PASSWORD=your_key_password
export KEYSTORE_PATH=path/to/release.keystore
export KEYSTORE_PASSWORD=your_keystore_password
```

### リリースビルド
```bash
./gradlew bundleRelease
```

## Analytics計測項目

- テキスト変換回数
- 文字数統計
- 画面遷移
- 共有・コピー機能利用
- エラー発生状況
- ユーザーリテンション

詳細は `docs/google-play-release-guide.md` を参照

## Important Notes

- APIは使用しない（すべてローカル処理、Analytics除く）
- 最小SDK: API 24 (Android 7.0)
- ターゲットSDK: API 34 (Android 14)
- GDPR準拠のデータ収集同意機能実装済み