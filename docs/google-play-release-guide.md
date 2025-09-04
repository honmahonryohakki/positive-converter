# Google Play Store リリース & Analytics計測ガイド

## 概要
このガイドでは、ポジティブ変換アプリをGoogle Play Storeに公開し、Google Analyticsで利用状況を計測するまでの全手順を説明します。

## 前提条件

### 必要なアカウント
- [ ] Google Play Developer アカウント（初回$25）
- [ ] Firebase アカウント（無料）
- [ ] Google Analytics アカウント（無料）

### 必要なツール
- [ ] Android Studio
- [ ] JDK 17以上
- [ ] Git

## Phase 1: Firebase & Google Analytics統合

### 1.1 Firebase プロジェクト作成
1. [Firebase Console](https://console.firebase.google.com/)にアクセス
2. 新規プロジェクト作成
3. Google Analyticsを有効化
4. Androidアプリを追加
   - パッケージ名: `com.positive.converter`
   - アプリニックネーム: ポジティブ変換
   - SHA-1証明書フィンガープリント（デバッグ用）を登録

### 1.2 google-services.json配置
```bash
app/google-services.json  # Firebaseコンソールからダウンロード
```

### 1.3 必要な依存関係追加
プロジェクトレベル build.gradle.kts:
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
    id("com.google.firebase.crashlytics") version "2.9.9" apply false
}
```

アプリレベル build.gradle.kts:
```kotlin
plugins {
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

dependencies {
    // Firebase
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-crashlytics-ktx")
}
```

## Phase 2: Analytics実装

### 2.1 基本イベントトラッキング
```kotlin
// AnalyticsManager.kt
class AnalyticsManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val firebaseAnalytics = Firebase.analytics
    
    fun logTextConverted(originalLength: Int, convertedLength: Int) {
        firebaseAnalytics.logEvent("text_converted") {
            param("original_length", originalLength.toLong())
            param("converted_length", convertedLength.toLong())
        }
    }
    
    fun logScreenView(screenName: String) {
        firebaseAnalytics.logEvent(FirebaseAnalytics.Event.SCREEN_VIEW) {
            param(FirebaseAnalytics.Param.SCREEN_NAME, screenName)
            param(FirebaseAnalytics.Param.SCREEN_CLASS, screenName)
        }
    }
    
    fun logHistoryAction(action: String) {
        firebaseAnalytics.logEvent("history_action") {
            param("action_type", action)
        }
    }
}
```

### 2.2 計測すべきKPI
- **DAU/MAU**: 日次・月次アクティブユーザー
- **変換実行回数**: テキスト変換機能の利用頻度
- **平均変換文字数**: ユーザーが入力する文字数
- **画面遷移**: どの機能がよく使われているか
- **リテンション率**: 継続利用率
- **クラッシュ率**: アプリの安定性

## Phase 3: プライバシーポリシー対応

### 3.1 データ収集の同意画面実装
```kotlin
@Composable
fun ConsentDialog(
    onAccept: () -> Unit,
    onDecline: () -> Unit
) {
    AlertDialog(
        onDismissRequest = { },
        title = { Text("データ収集への同意") },
        text = {
            Text(
                "このアプリは品質向上のため、" +
                "匿名の使用状況データを収集します。" +
                "個人情報は収集しません。"
            )
        },
        confirmButton = {
            TextButton(onClick = onAccept) {
                Text("同意する")
            }
        },
        dismissButton = {
            TextButton(onClick = onDecline) {
                Text("同意しない")
            }
        }
    )
}
```

### 3.2 プライバシーポリシーURL設定
アプリ内に表示するプライバシーポリシーのURLが必要です。

## Phase 4: アプリ署名とリリースビルド

### 4.1 キーストア作成
Android Studio: Build → Generate Signed Bundle / APK
- Key store path: 安全な場所に保存
- Key store password: 安全に管理
- Key alias: app-release
- Key password: 安全に管理

### 4.2 署名設定（build.gradle.kts）
```kotlin
android {
    signingConfigs {
        create("release") {
            keyAlias = "app-release"
            keyPassword = System.getenv("KEY_PASSWORD")
            storeFile = file(System.getenv("KEYSTORE_PATH"))
            storePassword = System.getenv("KEYSTORE_PASSWORD")
        }
    }
    
    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### 4.3 App Bundle作成
```bash
./gradlew bundleRelease
```
出力: `app/build/outputs/bundle/release/app-release.aab`

## Phase 5: Google Play Console設定

### 5.1 アプリ作成
1. [Google Play Console](https://play.google.com/console)にログイン
2. 「アプリを作成」クリック
3. アプリ詳細入力:
   - アプリ名: ポジティブ変換
   - デフォルト言語: 日本語
   - アプリまたはゲーム: アプリ
   - 無料または有料: 無料

### 5.2 必須情報の入力

#### アプリのセットアップ
- [x] アプリのアクセス権限（全機能制限なし）
- [x] 広告（広告なし）
- [x] コンテンツのレーティング（全年齢対象）
- [x] ターゲット ユーザー（13歳以上）
- [x] ニュースアプリ（いいえ）
- [x] データセーフティ

#### データセーフティ設定
収集するデータ:
- アプリのインタラクション（Analytics）
- アプリのパフォーマンス（Crashlytics）

データの扱い:
- データは暗号化されて送信
- データ削除リクエスト対応可能
- Google Playファミリーポリシー準拠

### 5.3 ストア掲載情報

#### 必須項目
- **アプリ名**: ポジティブ変換 - ネガティブをポジティブに
- **簡単な説明** (80文字):
  ```
  ネガティブな言葉をポジティブに自動変換！前向きな気持ちになれるテキスト変換アプリ
  ```
- **詳細な説明** (4000文字):
  ```
  「ポジティブ変換」は、ネガティブな言葉や文章を自動的にポジティブな表現に変換するアプリです。

  【こんな時に便利】
  ✓ 日記や記録をポジティブにしたい
  ✓ SNS投稿を前向きにしたい
  ✓ 気持ちを切り替えたい
  ✓ ポジティブシンキングを習慣化したい

  【主な機能】
  • 自動変換：ネガティブワードを瞬時にポジティブに
  • 履歴機能：過去の変換を100件まで保存
  • 共有機能：変換結果をSNSやメールで共有
  • ダークモード対応
  • オフライン動作（インターネット不要）

  【変換例】
  「疲れた」→「よく頑張った！」
  「できない」→「チャレンスする機会がある！」
  「つらい」→「成長の機会！」
  
  完全無料・広告なし・アカウント登録不要
  ```

#### グラフィックアセット
- **アプリアイコン**: 512x512px PNG
- **フィーチャーグラフィック**: 1024x500px
- **スクリーンショット**: 
  - 携帯電話用: 最低2枚（推奨5-8枚）
  - タブレット用: 推奨5枚

### 5.4 リリース管理

#### 内部テスト
1. 内部テストトラックを作成
2. テスター追加（最大100人）
3. App Bundleをアップロード
4. テスト実施（1-2週間）

#### クローズドテスト
1. クローズドテストトラックを作成
2. テスター募集（最大1000人）
3. フィードバック収集
4. 改善実施

#### 本番リリース
1. 製品版トラックにアップロード
2. 段階的公開（1% → 10% → 50% → 100%）
3. リリースノート記載

## Phase 6: Analytics確認と最適化

### 6.1 Firebase Consoleでの確認
- リアルタイムユーザー
- イベント発生状況
- ユーザー属性
- コンバージョン

### 6.2 Google Analytics連携
Firebase → プロジェクト設定 → 統合 → Google Analytics

### 6.3 主要指標のモニタリング
```
日次確認項目:
- インストール数
- アンインストール数
- クラッシュ率
- ANR率
- 評価とレビュー
```

## チェックリスト

### リリース前
- [ ] Firebase設定完了
- [ ] Analytics実装完了
- [ ] プライバシーポリシー作成
- [ ] キーストア作成・保管
- [ ] App Bundle生成
- [ ] 内部テスト実施
- [ ] クラッシュ対策確認

### Play Console
- [ ] アプリ情報入力完了
- [ ] データセーフティ設定
- [ ] ストア掲載情報完成
- [ ] グラフィックアセット準備
- [ ] コンテンツレーティング取得

### リリース後
- [ ] Analytics動作確認
- [ ] クラッシュレポート監視
- [ ] ユーザーレビュー対応
- [ ] 定期的なアップデート

## トラブルシューティング

### よくある問題
1. **SHA-1証明書エラー**: デバッグとリリース両方の証明書を登録
2. **Analytics遅延**: データ反映に24-48時間かかる場合あり
3. **審査リジェクト**: データセーフティの記載漏れが最多

### サポート
- [Firebase Support](https://firebase.google.com/support)
- [Play Console Help](https://support.google.com/googleplay/android-developer)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/google-play-console)