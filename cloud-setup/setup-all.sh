#!/bin/bash
#
# ポジティブ変換アプリ - Google Cloud 完全自動セットアップスクリプト
# Cloud Shell で実行してください
#

set -e

# 色付き出力用の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ログ関数
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# =============================================================================
# 設定値
# =============================================================================

# プロジェクト設定
APP_NAME="positive-converter"
PACKAGE_NAME="com.positive.converter"
REGION="asia-northeast1"
KEYSTORE_ALIAS="app-release"
GITHUB_REPO="" # 自動検出

# Firebase 設定
FIREBASE_PROJECT_NAME="${APP_NAME}-$(date +%s)"

# =============================================================================
# 0. 初期チェック
# =============================================================================

log "Google Cloud Shell 環境をチェック中..."

if [ -z "$CLOUD_SHELL" ]; then
    warning "Cloud Shell 環境ではありません。一部の機能が制限される可能性があります。"
fi

# プロジェクトIDを設定または作成
if [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
    log "新しいGCPプロジェクトを作成します..."
    PROJECT_ID="${APP_NAME}-$(date +%s)"
    
    # プロジェクト作成
    gcloud projects create $PROJECT_ID \
        --name="Positive Converter App" \
        --set-as-default
    
    # 請求アカウントを設定
    BILLING_ACCOUNT=$(gcloud billing accounts list --format="value(name)" --limit=1)
    if [ -n "$BILLING_ACCOUNT" ]; then
        gcloud billing projects link $PROJECT_ID \
            --billing-account=$BILLING_ACCOUNT
    else
        warning "請求アカウントが見つかりません。後で手動で設定してください。"
    fi
else
    PROJECT_ID=$GOOGLE_CLOUD_PROJECT
    log "既存のプロジェクトを使用: $PROJECT_ID"
fi

export PROJECT_ID
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

# =============================================================================
# 1. 必要なAPIを有効化
# =============================================================================

log "必要なGoogle Cloud APIを有効化中..."

apis=(
    "cloudbuild.googleapis.com"
    "secretmanager.googleapis.com"
    "androidpublisher.googleapis.com"
    "firebase.googleapis.com"
    "firebaseanalytics.googleapis.com"
    "firebasecrashlytics.googleapis.com"
    "firebaseappdistribution.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "serviceusage.googleapis.com"
    "iam.googleapis.com"
)

for api in "${apis[@]}"; do
    log "  - $api を有効化中..."
    gcloud services enable $api --project=$PROJECT_ID
done

# =============================================================================
# 2. Firebase プロジェクトの作成と設定
# =============================================================================

log "Firebase プロジェクトを設定中..."

# Firebase CLIのインストール（Cloud Shellには既にインストール済み）
if ! command -v firebase &> /dev/null; then
    log "Firebase CLI をインストール中..."
    npm install -g firebase-tools
fi

# Firebase プロジェクトを作成
log "Firebase プロジェクトを作成中..."
firebase projects:create $PROJECT_ID --display-name="Positive Converter" || true

# Firebase プロジェクトをGCPプロジェクトに関連付け
firebase use $PROJECT_ID

# Androidアプリを追加
log "Firebase に Android アプリを追加中..."
firebase apps:create android --package-name=$PACKAGE_NAME --project=$PROJECT_ID || true

# google-services.json を取得
log "google-services.json をダウンロード中..."
firebase apps:sdkconfig android $PACKAGE_NAME -o google-services.json --project=$PROJECT_ID

# Firebase App IDを取得
FIREBASE_APP_ID=$(firebase apps:list android --project=$PROJECT_ID | grep $PACKAGE_NAME | awk '{print $2}')
log "Firebase App ID: $FIREBASE_APP_ID"

# =============================================================================
# 3. キーストアの自動生成
# =============================================================================

log "リリース用キーストアを生成中..."

# ランダムなパスワードを生成
KEYSTORE_PASSWORD=$(openssl rand -base64 32)
KEY_PASSWORD=$(openssl rand -base64 32)

# キーストア生成用の設定ファイル作成
cat > keystore.conf <<EOF
$KEYSTORE_PASSWORD
$KEYSTORE_PASSWORD
Positive Converter
Development Team
Organization
Tokyo
Tokyo
JP
yes
$KEY_PASSWORD
$KEY_PASSWORD
EOF

# キーストアを生成
keytool -genkey -v \
    -keystore release.keystore \
    -alias $KEYSTORE_ALIAS \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Positive Converter, OU=Development, O=Organization, L=Tokyo, S=Tokyo, C=JP" \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    2>/dev/null

rm -f keystore.conf

log "キーストアを生成しました"

# =============================================================================
# 4. Secret Manager にシークレットを保存
# =============================================================================

log "Secret Manager にシークレットを保存中..."

# キーストアを保存
log "  - キーストアを保存中..."
gcloud secrets create android-keystore \
    --data-file=release.keystore \
    --project=$PROJECT_ID \
    --replication-policy="automatic" || true

# パスワードを保存
log "  - パスワードを保存中..."
echo -n "$KEYSTORE_PASSWORD" | gcloud secrets create keystore-password \
    --data-file=- \
    --project=$PROJECT_ID \
    --replication-policy="automatic" || true

echo -n "$KEY_PASSWORD" | gcloud secrets create key-password \
    --data-file=- \
    --project=$PROJECT_ID \
    --replication-policy="automatic" || true

# google-services.json を保存
log "  - google-services.json を保存中..."
gcloud secrets create google-services-json \
    --data-file=google-services.json \
    --project=$PROJECT_ID \
    --replication-policy="automatic" || true

# Firebase App ID を保存
log "  - Firebase App ID を保存中..."
echo -n "$FIREBASE_APP_ID" | gcloud secrets create firebase-app-id \
    --data-file=- \
    --project=$PROJECT_ID \
    --replication-policy="automatic" || true

# =============================================================================
# 5. Google Play Console サービスアカウントの設定
# =============================================================================

log "Google Play Console 用のサービスアカウントを作成中..."

# サービスアカウントを作成
SA_NAME="play-console-deploy"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud iam service-accounts create $SA_NAME \
    --display-name="Google Play Console Deploy" \
    --project=$PROJECT_ID || true

# サービスアカウントキーを作成
log "サービスアカウントキーを生成中..."
gcloud iam service-accounts keys create play-console-key.json \
    --iam-account=$SA_EMAIL \
    --project=$PROJECT_ID

# Secret Manager に保存
log "サービスアカウントキーを Secret Manager に保存中..."
gcloud secrets create google-play-service-account \
    --data-file=play-console-key.json \
    --project=$PROJECT_ID \
    --replication-policy="automatic" || true

# =============================================================================
# 6. Cloud Build の権限設定
# =============================================================================

log "Cloud Build サービスアカウントに権限を付与中..."

CLOUD_BUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

# Secret Manager へのアクセス権限
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${CLOUD_BUILD_SA}" \
    --role="roles/secretmanager.secretAccessor"

# Firebase App Distribution の権限
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${CLOUD_BUILD_SA}" \
    --role="roles/firebaseappdistribution.admin"

# =============================================================================
# 7. GitHub リポジトリの接続（対話的）
# =============================================================================

log "GitHub リポジトリの設定..."

echo ""
echo "GitHub リポジトリをCloud Buildに接続する必要があります。"
echo "以下のURLを開いて、リポジトリを接続してください："
echo ""
echo "  https://console.cloud.google.com/cloud-build/triggers/connect?project=$PROJECT_ID"
echo ""
echo "接続が完了したら、以下を入力してください："
read -p "GitHub ユーザー名: " GITHUB_USER
read -p "リポジトリ名 (デフォルト: positive-converter): " REPO_NAME
REPO_NAME=${REPO_NAME:-positive-converter}

# =============================================================================
# 8. Cloud Build トリガーの作成
# =============================================================================

log "Cloud Build トリガーを作成中..."

# メインブランチ用トリガー
log "  - main ブランチ用トリガーを作成中..."
gcloud builds triggers create github \
    --repo-name="$REPO_NAME" \
    --repo-owner="$GITHUB_USER" \
    --branch-pattern="^main$" \
    --build-config="cloudbuild.yaml" \
    --project=$PROJECT_ID \
    --substitutions="_PACKAGE_NAME=${PACKAGE_NAME},_PLAY_TRACK=production" \
    --name="deploy-to-production" || true

# 開発ブランチ用トリガー
log "  - develop ブランチ用トリガーを作成中..."
gcloud builds triggers create github \
    --repo-name="$REPO_NAME" \
    --repo-owner="$GITHUB_USER" \
    --branch-pattern="^develop$" \
    --build-config="cloudbuild.yaml" \
    --project=$PROJECT_ID \
    --substitutions="_PACKAGE_NAME=${PACKAGE_NAME},_PLAY_TRACK=internal" \
    --name="deploy-to-internal" || true

# =============================================================================
# 9. 設定情報の保存
# =============================================================================

log "設定情報を保存中..."

cat > cloud-config.env <<EOF
# Google Cloud 設定
export PROJECT_ID=$PROJECT_ID
export PROJECT_NUMBER=$PROJECT_NUMBER
export REGION=$REGION

# アプリ設定
export PACKAGE_NAME=$PACKAGE_NAME
export KEYSTORE_ALIAS=$KEYSTORE_ALIAS

# Firebase設定
export FIREBASE_APP_ID=$FIREBASE_APP_ID

# GitHub設定
export GITHUB_USER=$GITHUB_USER
export GITHUB_REPO=$REPO_NAME

# サービスアカウント
export PLAY_CONSOLE_SA=$SA_EMAIL
EOF

# =============================================================================
# 10. 必要なファイルをローカルに保存
# =============================================================================

log "必要なファイルを生成中..."

# アプリディレクトリに移動するためのスクリプト
cat > ../gradle.properties <<EOF
# 自動生成されたGradle設定
# Cloud Build 用の設定（ローカルビルド時は上書きされます）
KEYSTORE_PATH=../release.keystore
KEY_ALIAS=$KEYSTORE_ALIAS
KEY_PASSWORD=$KEY_PASSWORD
KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD
EOF

# google-services.json をアプリディレクトリにコピー
if [ -f "../app/google-services.json" ]; then
    cp google-services.json ../app/google-services.json
    log "google-services.json をアプリディレクトリにコピーしました"
fi

# =============================================================================
# 完了メッセージ
# =============================================================================

echo ""
echo "========================================================================="
echo -e "${GREEN}セットアップが完了しました！${NC}"
echo "========================================================================="
echo ""
echo "プロジェクト情報:"
echo "  - Project ID: $PROJECT_ID"
echo "  - Project Number: $PROJECT_NUMBER"
echo "  - Firebase App ID: $FIREBASE_APP_ID"
echo ""
echo "次のステップ:"
echo ""
echo "1. Google Play Console にアクセスしてサービスアカウントに権限を付与:"
echo "   https://play.google.com/console"
echo "   - 設定 → API アクセス"
echo "   - サービスアカウント: $SA_EMAIL"
echo "   - 必要な権限を付与"
echo ""
echo "2. 初回のアプリアップロード（手動）:"
echo "   ./gradlew bundleRelease"
echo "   Play Console で手動アップロード"
echo ""
echo "3. GitHub にプッシュして自動デプロイ開始:"
echo "   git add ."
echo "   git commit -m 'Setup Cloud Build CI/CD'"
echo "   git push origin main"
echo ""
echo "設定ファイル:"
echo "  - cloud-config.env: 環境変数"
echo "  - play-console-key.json: Play Console APIキー（要保管）"
echo "  - release.keystore: 署名キー（要保管）"
echo ""
echo "========================================================================="

# クリーンアップの提案
echo ""
read -p "ローカルの機密ファイルを削除しますか？(Cloud に保存済み) [y/N]: " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f release.keystore
    rm -f play-console-key.json
    rm -f google-services.json
    log "機密ファイルを削除しました（Secret Manager に保存済み）"
fi