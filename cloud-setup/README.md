# 🚀 Google Cloud Shell 完全自動化セットアップ

このディレクトリには、Google Cloud Shell を使用してポジティブ変換アプリを完全自動でビルド・デプロイするためのスクリプトが含まれています。

## 📋 前提条件

- Google Cloud アカウント
- Google Play Console デベロッパーアカウント（$25の登録料が必要）
- GitHub アカウント（ソースコード管理用）

## 🎯 実現できること

1. **完全自動化**: Cloud Shell から数コマンドで全セットアップ完了
2. **CI/CD パイプライン**: Git push するだけで自動ビルド・デプロイ
3. **マルチトラック対応**: 内部テスト、アルファ、ベータ、本番環境への自動デプロイ
4. **セキュア**: すべての秘密情報は Secret Manager で暗号化管理

## 🏗️ アーキテクチャ

```
GitHub Repository
    ↓ (Push)
Cloud Build Trigger
    ↓
Cloud Build
    ├→ Android App Bundle ビルド
    ├→ Firebase App Distribution（テスト配布）
    └→ Google Play Store（本番リリース）
```

## 📦 含まれるスクリプト

| スクリプト | 説明 | 実行タイミング |
|-----------|------|--------------|
| `setup-all.sh` | 完全自動セットアップ | 初回のみ |
| `init-project.sh` | プロジェクト初期化 | Cloud Shell 起動時 |
| `generate-keystore.sh` | キーストア自動生成 | 必要時 |
| `deploy.sh` | ワンコマンドデプロイ | リリース時 |

## 🚀 クイックスタート

### ステップ 1: Cloud Shell を開く

```bash
# ブラウザで Cloud Shell を開く
https://shell.cloud.google.com
```

### ステップ 2: リポジトリをクローン

```bash
# あなたのGitHubリポジトリをクローン
git clone https://github.com/YOUR_USERNAME/positive-converter.git
cd positive-converter
```

### ステップ 3: 完全自動セットアップを実行

```bash
# セットアップスクリプトを実行
cd cloud-setup
bash setup-all.sh
```

このスクリプトが自動で行うこと：
- ✅ GCP プロジェクトの作成/設定
- ✅ 必要な API の有効化
- ✅ Firebase プロジェクトの作成・設定
- ✅ キーストアの自動生成
- ✅ Secret Manager への秘密情報保存
- ✅ サービスアカウントの作成
- ✅ Cloud Build トリガーの設定

### ステップ 4: Play Console の設定（手動・1回のみ）

1. [Google Play Console](https://play.google.com/console) にアクセス
2. 「設定」→「API アクセス」
3. 生成されたサービスアカウント（表示される）に以下の権限を付与：
   - リリース管理
   - 製品版リリースの管理

### ステップ 5: 初回アップロード（手動・1回のみ）

```bash
# アプリをビルド
cd ..
./gradlew bundleRelease

# app/build/outputs/bundle/release/app-release.aab を
# Play Console で手動アップロード（初回のみ必要）
```

## 🎮 日常的な使用方法

### 開発中のテスト

```bash
# ローカルでデバッグビルド
./gradlew assembleDebug

# ユニットテスト実行
./gradlew test
```

### 内部テストへデプロイ

```bash
# develop ブランチにプッシュ → 自動で内部テストへ
git checkout develop
git add .
git commit -m "新機能追加"
git push origin develop
```

### 本番リリース

```bash
# main ブランチにマージ → 自動で本番へ
git checkout main
git merge develop
git push origin main
```

### 手動デプロイ

```bash
# 内部テストトラックへ
bash cloud-setup/deploy.sh

# アルファトラックへ
bash cloud-setup/deploy.sh -t alpha

# ベータトラックへ
bash cloud-setup/deploy.sh -t beta

# 本番へ（確認あり）
bash cloud-setup/deploy.sh -t production -m "Version 1.0.0 リリース"
```

## 📊 ビルド状況の確認

```bash
# 最近のビルドをリスト表示
gcloud builds list --limit=5

# 特定のビルドのログを確認
gcloud builds log BUILD_ID

# Web コンソールで確認
echo "https://console.cloud.google.com/cloud-build/builds?project=$PROJECT_ID"
```

## 🔧 トラブルシューティング

### Secret Manager のエラー

```bash
# シークレットの一覧確認
gcloud secrets list

# シークレットの再作成
gcloud secrets delete SECRET_NAME --quiet
gcloud secrets create SECRET_NAME --data-file=FILE_PATH
```

### ビルドエラー

```bash
# ビルドログの詳細確認
gcloud builds log BUILD_ID --stream

# ローカルでビルドテスト
./gradlew clean build
```

### 権限エラー

```bash
# サービスアカウントの権限確認
gcloud projects get-iam-policy $PROJECT_ID

# 権限の付与
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:SA_EMAIL" \
  --role="roles/ROLE_NAME"
```

## 💰 コスト管理

### 無料枠

- Cloud Build: 120分/日まで無料
- Secret Manager: 6シークレット、10,000アクセス/月まで無料
- Cloud Storage: 5GBまで無料

### 推定月額コスト

- 小規模（100ビルド/月）: **$0〜5**
- 中規模（500ビルド/月）: **$10〜20**
- 大規模（2000ビルド/月）: **$50〜100**

### コスト削減のヒント

1. develop ブランチのビルドを制限
2. ビルドキャッシュを活用
3. 不要なトリガーを削除

## 🔐 セキュリティ

### 保護される情報

- ✅ キーストアと署名情報
- ✅ Google Play API キー
- ✅ Firebase 設定
- ✅ サービスアカウントキー

### ベストプラクティス

1. **キーローテーション**: 年1回キーストアを更新
2. **アクセス制限**: 必要最小限の権限のみ付与
3. **監査ログ**: Cloud Audit Logs で監視
4. **ブランチ保護**: main ブランチは PR 必須

## 📝 カスタマイズ

### 環境変数（cloud-config.env）

```bash
# プロジェクト設定
PROJECT_ID=your-project-id
PACKAGE_NAME=com.your.package

# リリーストラック
DEFAULT_TRACK=internal  # or alpha, beta, production

# 通知設定（オプション）
SLACK_WEBHOOK_URL=https://hooks.slack.com/...
```

### ビルド設定（cloudbuild.yaml）

```yaml
# タイムアウト変更
timeout: '3600s'  # 1時間

# マシンタイプ変更
options:
  machineType: 'N1_HIGHCPU_32'  # より高速なマシン
```

## 🆘 サポート

### よくある質問

**Q: 初回セットアップにどのくらい時間がかかりますか？**
A: 約15-20分です（手動設定含む）

**Q: 複数のアプリを管理できますか？**
A: はい、プロジェクトごとに別々のGCPプロジェクトを作成してください

**Q: ローカル開発環境でも使えますか？**
A: はい、gcloud CLI をインストールすれば使用可能です

### 問題が解決しない場合

1. [Cloud Build のドキュメント](https://cloud.google.com/build/docs)
2. [Firebase のドキュメント](https://firebase.google.com/docs)
3. [Play Console ヘルプ](https://support.google.com/googleplay/android-developer)

## 📈 次のステップ

1. **モニタリング追加**: Firebase Crashlytics, Performance Monitoring
2. **A/Bテスト**: Firebase Remote Config
3. **自動テスト強化**: Firebase Test Lab
4. **コード品質**: SonarQube 統合

---

🎉 **セットアップ完了後は Git push するだけで自動デプロイされます！**