# 🚀 Positive Converter - 完全自動化セットアップガイド

## 概要
このガイドでは、mainブランチへのプッシュで自動的にGoogle Play Storeにアプリをデプロイする完全自動化環境の構築手順を説明します。

## 前提条件
- ✅ GitHub リポジトリ: `honmahonryohakki/positive-converter`
- ✅ Android Keystore: `release.keystore` (作成済み)
- ✅ CI/CD設定: `cloudbuild.yaml` (設定済み)
- ✅ デプロイスクリプト: `deploy_to_play.py` (設定済み)

## セットアップ手順

### 1️⃣ Google Cloud Project作成
1. **Google Cloud Console**: https://console.cloud.google.com
2. **新しいプロジェクトを作成**
   - プロジェクト名: `positive-converter-app`
   - プロジェクトID: `positive-converter-app-[ランダム]`
3. **プロジェクトを選択**

### 2️⃣ 必要なAPIを有効化
```bash
# Google Cloud Console → API とサービス → ライブラリ
# 以下のAPIを検索して有効化：

✅ Cloud Build API
✅ Secret Manager API  
✅ Google Play Developer API
✅ Firebase Management API
```

### 3️⃣ Firebase プロジェクト設定
1. **Firebase Console**: https://console.firebase.google.com
2. **プロジェクトを追加** → 既存のGoogle Cloudプロジェクトを選択
3. **Analytics** → 有効化
4. **Android アプリを追加**
   - パッケージ名: `com.positive.converter`
   - アプリ名: `Positive Converter`
5. **google-services.json をダウンロード**

### 4️⃣ Google Play Console設定
1. **Play Console**: https://play.google.com/console
2. **アプリを作成**
   - アプリ名: `Positive Converter`
   - パッケージ名: `com.positive.converter`
3. **設定 → API アクセス**
   - **新しいサービスアカウントを作成**
   - **権限**: Google Play Developer
   - **JSON キーをダウンロード**

### 5️⃣ Secret Manager設定

Google Cloud Console → Security → Secret Manager で以下を作成：

| シークレット名 | 値 | 説明 |
|---------------|-----|------|
| `keystore-password` | `positive123` | キーストアパスワード |
| `key-password` | `positive123` | キーパスワード |
| `android-keystore` | [base64] | release.keystore を base64 エンコード |
| `google-services-json` | [base64] | google-services.json を base64 エンコード |
| `google-play-service-account` | [JSON] | Play Console APIキー（JSON文字列） |
| `firebase-app-id` | `1:xxx:android:xxx` | Firebase App ID |

#### Base64エンコード手順:
```bash
# キーストアをbase64エンコード
base64 release.keystore > keystore.base64

# google-services.jsonをbase64エンコード  
base64 app/google-services.json > google-services.base64
```

### 6️⃣ Cloud Build トリガー設定
1. **Cloud Build → トリガー → トリガーを作成**
2. **設定:**
   - **名前**: `deploy-to-play-store`
   - **ソース**: GitHub (Cloud Build GitHub App)
   - **リポジトリ**: `honmahonryohakki/positive-converter`
   - **ブランチ**: `^main$`
   - **構成**: Cloud Build 構成ファイル
   - **ファイルの場所**: `cloudbuild.yaml`

### 7️⃣ 権限設定
Cloud Build サービスアカウントに以下の権限を付与：
- **Secret Manager Secret Accessor**
- **Firebase Admin**

## 🎯 完全自動化フロー

```
GitHub Push (main) 
    ↓
Cloud Build Trigger
    ↓
Build Android App
    ↓
Upload to Play Store
    ↓
✅ 本番環境デプロイ完了
```

## ⚠️ 注意事項
- **mainブランチ** = 本番環境デプロイ
- **developブランチ** = Firebase App Distribution（テスト配布）
- **リリーストラック**: `internal` （内部テスト）

## 🔧 トラブルシューティング
- Build失敗 → Cloud Build ログを確認
- Secret Manager アクセスエラー → 権限設定を確認
- Play Store アップロードエラー → APIキー設定を確認

## 📞 サポート
設定で問題が発生した場合は、Cloud Build のログとエラーメッセージを確認してください。