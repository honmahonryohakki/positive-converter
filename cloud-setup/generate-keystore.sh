#!/bin/bash
#
# キーストア自動生成スクリプト
# Android アプリ署名用のキーストアを自動生成し、Secret Manager に保存
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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
# 設定値の読み込み
# =============================================================================

if [ -f "cloud-setup/cloud-config.env" ]; then
    source cloud-setup/cloud-config.env
fi

# デフォルト値
KEYSTORE_ALIAS=${KEYSTORE_ALIAS:-"app-release"}
KEYSTORE_FILE="release.keystore"
VALIDITY_DAYS=10000  # 約27年

# =============================================================================
# 既存のキーストアチェック
# =============================================================================

if [ -f "$KEYSTORE_FILE" ]; then
    warning "既存のキーストアが見つかりました: $KEYSTORE_FILE"
    read -p "新しいキーストアを生成しますか？（既存のものは上書きされます） [y/N]: " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "キーストア生成をキャンセルしました"
        exit 0
    fi
    
    # バックアップ作成
    backup_file="${KEYSTORE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$KEYSTORE_FILE" "$backup_file"
    log "既存のキーストアをバックアップしました: $backup_file"
fi

# =============================================================================
# パスワード生成
# =============================================================================

log "セキュアなパスワードを生成中..."

# ランダムなパスワードを生成（32文字、英数字と記号）
generate_password() {
    openssl rand -base64 32 | tr -d '\n' | cut -c1-32
}

KEYSTORE_PASSWORD=$(generate_password)
KEY_PASSWORD=$(generate_password)

# パスワードの強度を確認
log "パスワード生成完了（32文字のランダム文字列）"

# =============================================================================
# キーストア情報の入力
# =============================================================================

echo ""
echo "キーストアの識別情報を入力してください（Enterでデフォルト値を使用）:"
echo ""

read -p "組織名 [Positive Converter Team]: " CN
CN=${CN:-"Positive Converter Team"}

read -p "組織単位 [Development]: " OU
OU=${OU:-"Development"}

read -p "組織 [Independent Developer]: " O
O=${O:-"Independent Developer"}

read -p "都市 [Tokyo]: " L
L=${L:-"Tokyo"}

read -p "都道府県 [Tokyo]: " S
S=${S:-"Tokyo"}

read -p "国コード（2文字） [JP]: " C
C=${C:-"JP"}

# =============================================================================
# キーストアの生成
# =============================================================================

log "キーストアを生成中..."

# Distinguished Name (DN) の作成
DN="CN=$CN, OU=$OU, O=$O, L=$L, S=$S, C=$C"

# keytool コマンドで生成
keytool -genkeypair \
    -alias "$KEYSTORE_ALIAS" \
    -keystore "$KEYSTORE_FILE" \
    -keyalg RSA \
    -keysize 2048 \
    -validity $VALIDITY_DAYS \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "$DN" \
    -noprompt

if [ $? -eq 0 ]; then
    log "キーストアの生成に成功しました: $KEYSTORE_FILE"
else
    error "キーストアの生成に失敗しました"
fi

# =============================================================================
# キーストア情報の確認
# =============================================================================

log "キーストア情報を確認中..."

echo ""
keytool -list -v -keystore "$KEYSTORE_FILE" -storepass "$KEYSTORE_PASSWORD" -alias "$KEYSTORE_ALIAS" | head -20
echo ""

# =============================================================================
# gradle.properties の生成
# =============================================================================

log "gradle.properties を生成中..."

cat > gradle.properties <<EOF
# 自動生成された署名設定
# 生成日時: $(date)
KEYSTORE_PATH=../$KEYSTORE_FILE
KEY_ALIAS=$KEYSTORE_ALIAS
KEY_PASSWORD=$KEY_PASSWORD
KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD
EOF

log "gradle.properties を生成しました"

# =============================================================================
# Secret Manager への保存
# =============================================================================

if [ -n "$PROJECT_ID" ]; then
    log "Secret Manager に保存中..."
    
    # キーストアを保存
    gcloud secrets delete android-keystore --project=$PROJECT_ID --quiet 2>/dev/null || true
    gcloud secrets create android-keystore \
        --data-file="$KEYSTORE_FILE" \
        --project=$PROJECT_ID \
        --replication-policy="automatic"
    
    # パスワードを保存
    echo -n "$KEYSTORE_PASSWORD" | \
        gcloud secrets delete keystore-password --project=$PROJECT_ID --quiet 2>/dev/null || true
    echo -n "$KEYSTORE_PASSWORD" | \
        gcloud secrets create keystore-password \
        --data-file=- \
        --project=$PROJECT_ID \
        --replication-policy="automatic"
    
    echo -n "$KEY_PASSWORD" | \
        gcloud secrets delete key-password --project=$PROJECT_ID --quiet 2>/dev/null || true
    echo -n "$KEY_PASSWORD" | \
        gcloud secrets create key-password \
        --data-file=- \
        --project=$PROJECT_ID \
        --replication-policy="automatic"
    
    log "Secret Manager への保存完了"
fi

# =============================================================================
# セキュリティ情報の保存
# =============================================================================

# パスワード情報を安全な場所に保存
CREDENTIALS_FILE="keystore-credentials.txt"
cat > "$CREDENTIALS_FILE" <<EOF
========================================
キーストア認証情報
生成日時: $(date)
========================================

キーストアファイル: $KEYSTORE_FILE
キーエイリアス: $KEYSTORE_ALIAS

キーストアパスワード:
$KEYSTORE_PASSWORD

キーパスワード:
$KEY_PASSWORD

DN情報:
$DN

有効期限: $VALIDITY_DAYS 日（約 $(($VALIDITY_DAYS / 365)) 年）

========================================
重要: この情報は安全な場所に保管してください！
========================================
EOF

chmod 600 "$CREDENTIALS_FILE"
log "認証情報を $CREDENTIALS_FILE に保存しました（権限: 600）"

# =============================================================================
# SHA証明書フィンガープリントの取得
# =============================================================================

log "SHA証明書フィンガープリントを取得中..."

echo ""
echo "SHA-1 フィンガープリント:"
keytool -list -v -keystore "$KEYSTORE_FILE" -storepass "$KEYSTORE_PASSWORD" -alias "$KEYSTORE_ALIAS" | grep SHA1

echo ""
echo "SHA-256 フィンガープリント:"
keytool -list -v -keystore "$KEYSTORE_FILE" -storepass "$KEYSTORE_PASSWORD" -alias "$KEYSTORE_ALIAS" | grep SHA256

# =============================================================================
# 完了メッセージ
# =============================================================================

echo ""
echo "========================================================================="
echo -e "${GREEN}キーストアの生成が完了しました！${NC}"
echo "========================================================================="
echo ""
echo "生成されたファイル:"
echo "  - $KEYSTORE_FILE: キーストアファイル"
echo "  - gradle.properties: Gradle 設定ファイル"
echo "  - $CREDENTIALS_FILE: 認証情報（安全に保管してください）"
echo ""
echo "次のステップ:"
echo "  1. $CREDENTIALS_FILE を安全な場所にバックアップ"
echo "  2. Firebase Console でSHA証明書フィンガープリントを登録"
echo "  3. Play Console でアップロード鍵証明書を設定"
echo ""
echo "========================================================================="

# クリーンアップの提案
if [ -n "$PROJECT_ID" ]; then
    echo ""
    read -p "ローカルのキーストアを削除しますか？（Secret Manager に保存済み） [y/N]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$KEYSTORE_FILE"
        log "ローカルのキーストアを削除しました"
        
        # gradle.properties も更新
        cat > gradle.properties <<EOF
# Cloud Build 用の設定
# ローカルビルド時は cloud-setup/init-project.sh を実行してキーストアを取得してください
KEYSTORE_PATH=NEEDS_TO_BE_RETRIEVED
KEY_ALIAS=$KEYSTORE_ALIAS
KEY_PASSWORD=STORED_IN_SECRET_MANAGER
KEYSTORE_PASSWORD=STORED_IN_SECRET_MANAGER
EOF
        log "gradle.properties を更新しました"
    fi
fi