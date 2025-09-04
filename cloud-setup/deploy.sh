#!/bin/bash
#
# ワンコマンドデプロイスクリプト
# Cloud Build を使用して Android アプリをビルド・デプロイ
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# =============================================================================
# 引数の解析
# =============================================================================

TRACK="internal"  # デフォルトは内部テスト
BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
RELEASE_NOTES=""
SKIP_TESTS=false
WAIT_FOR_BUILD=true

# ヘルプメッセージ
show_help() {
    cat << EOF
使用方法: $(basename "$0") [オプション]

オプション:
    -t, --track TRACK        リリーストラック (internal/alpha/beta/production)
                            デフォルト: internal
    -b, --branch BRANCH      ビルドするブランチ
                            デフォルト: 現在のブランチ
    -m, --message MESSAGE    リリースノート
    -s, --skip-tests        テストをスキップ
    -n, --no-wait           ビルド完了を待たずに終了
    -h, --help              このヘルプを表示

例:
    # 内部テストトラックにデプロイ
    $(basename "$0")
    
    # 本番環境にリリース
    $(basename "$0") -t production -m "Version 1.0.0 release"
    
    # テストをスキップして alpha トラックにデプロイ
    $(basename "$0") -t alpha -s

EOF
    exit 0
}

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--track)
            TRACK="$2"
            shift 2
            ;;
        -b|--branch)
            BRANCH="$2"
            shift 2
            ;;
        -m|--message)
            RELEASE_NOTES="$2"
            shift 2
            ;;
        -s|--skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        -n|--no-wait)
            WAIT_FOR_BUILD=false
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            error "不明なオプション: $1"
            ;;
    esac
done

# =============================================================================
# 設定の読み込み
# =============================================================================

if [ -f "cloud-setup/cloud-config.env" ]; then
    source cloud-setup/cloud-config.env
else
    error "cloud-config.env が見つかりません。setup-all.sh を先に実行してください。"
fi

# 必須変数のチェック
if [ -z "$PROJECT_ID" ]; then
    error "PROJECT_ID が設定されていません"
fi

if [ -z "$PACKAGE_NAME" ]; then
    error "PACKAGE_NAME が設定されていません"
fi

# =============================================================================
# 事前チェック
# =============================================================================

log "デプロイ前チェックを実行中..."

# Git の状態確認
if [ -d ".git" ]; then
    # コミットされていない変更がないかチェック
    if ! git diff --quiet || ! git diff --cached --quiet; then
        warning "コミットされていない変更があります:"
        git status --short
        echo ""
        read -p "このまま続行しますか？ [y/N]: " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "デプロイをキャンセルしました"
            exit 0
        fi
    fi
    
    # リモートとの同期確認
    git fetch origin >/dev/null 2>&1 || true
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/$BRANCH 2>/dev/null || echo "")
    
    if [ -n "$REMOTE" ] && [ "$LOCAL" != "$REMOTE" ]; then
        warning "ローカルブランチがリモートと同期していません"
        info "ローカル: $LOCAL"
        info "リモート: $REMOTE"
    fi
fi

# =============================================================================
# ローカルテスト（オプション）
# =============================================================================

if [ "$SKIP_TESTS" = false ]; then
    log "ローカルテストを実行中..."
    
    # Unit テスト
    if ./gradlew test --no-daemon; then
        log "Unit テストが成功しました"
    else
        error "Unit テストが失敗しました"
    fi
    
    # Lint チェック
    if ./gradlew lint --no-daemon; then
        log "Lint チェックが成功しました"
    else
        warning "Lint の警告があります（続行します）"
    fi
else
    warning "テストをスキップします"
fi

# =============================================================================
# ビルド設定の確認
# =============================================================================

log "ビルド設定:"
echo "  - プロジェクト: $PROJECT_ID"
echo "  - パッケージ: $PACKAGE_NAME"
echo "  - ブランチ: $BRANCH"
echo "  - コミット: $COMMIT_SHA"
echo "  - トラック: $TRACK"
echo "  - リリースノート: ${RELEASE_NOTES:-なし}"
echo ""

if [ "$TRACK" = "production" ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  ⚠️  本番環境へのデプロイです！${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    read -p "本番環境にデプロイしてもよろしいですか？ [yes/NO]: " -r
    if [ "$REPLY" != "yes" ]; then
        log "デプロイをキャンセルしました"
        exit 0
    fi
fi

# =============================================================================
# Cloud Build の実行
# =============================================================================

log "Cloud Build を開始中..."

# substitutions の作成
SUBSTITUTIONS="_PACKAGE_NAME=${PACKAGE_NAME},_PLAY_TRACK=${TRACK}"
if [ -n "$KEYSTORE_ALIAS" ]; then
    SUBSTITUTIONS="${SUBSTITUTIONS},_KEY_ALIAS=${KEYSTORE_ALIAS}"
fi

# Cloud Build の実行
BUILD_ID=$(gcloud builds submit \
    --config=cloudbuild.yaml \
    --project=$PROJECT_ID \
    --substitutions="BRANCH_NAME=${BRANCH},SHORT_SHA=${COMMIT_SHA},${SUBSTITUTIONS}" \
    --async \
    --format="value(name)")

if [ -z "$BUILD_ID" ]; then
    error "Cloud Build の開始に失敗しました"
fi

# ビルドIDを抽出（operations/build/xxx形式から xxx を取得）
BUILD_ID=$(echo $BUILD_ID | sed 's|.*/||')

log "ビルドを開始しました: $BUILD_ID"
echo ""
echo "ビルドの詳細はこちらで確認できます:"
echo "  https://console.cloud.google.com/cloud-build/builds/${BUILD_ID}?project=${PROJECT_ID}"
echo ""

# =============================================================================
# ビルドの監視
# =============================================================================

if [ "$WAIT_FOR_BUILD" = true ]; then
    log "ビルドの完了を待っています..."
    
    # ビルドログをストリーミング
    gcloud builds log $BUILD_ID --stream --project=$PROJECT_ID
    
    # ビルド結果の確認
    STATUS=$(gcloud builds describe $BUILD_ID --project=$PROJECT_ID --format="value(status)")
    
    if [ "$STATUS" = "SUCCESS" ]; then
        log "ビルドが成功しました！"
        
        # アーティファクトの情報を表示
        echo ""
        echo "ビルド成果物:"
        gsutil ls gs://${PROJECT_ID}-build-artifacts/${BUILD_ID}/ 2>/dev/null || true
        
    else
        error "ビルドが失敗しました: $STATUS"
    fi
else
    log "バックグラウンドでビルドを実行中です"
    echo "ビルドの状態を確認するには以下のコマンドを実行してください:"
    echo "  gcloud builds describe $BUILD_ID --project=$PROJECT_ID"
fi

# =============================================================================
# デプロイ後の処理
# =============================================================================

if [ "$STATUS" = "SUCCESS" ] && [ "$WAIT_FOR_BUILD" = true ]; then
    echo ""
    echo "========================================================================="
    echo -e "${GREEN}デプロイが完了しました！${NC}"
    echo "========================================================================="
    echo ""
    
    case $TRACK in
        internal)
            echo "内部テストトラックにデプロイされました。"
            echo "Firebase App Distribution でテスターに配布されています。"
            ;;
        alpha)
            echo "アルファトラックにデプロイされました。"
            echo "限定されたテスターグループで利用可能です。"
            ;;
        beta)
            echo "ベータトラックにデプロイされました。"
            echo "オープンベータテストで利用可能です。"
            ;;
        production)
            echo "本番環境にデプロイされました！"
            echo "Google Play Store で公開されます。"
            echo ""
            echo "注意: 実際の公開には Google Play の審査が必要です。"
            ;;
    esac
    
    echo ""
    echo "Google Play Console:"
    echo "  https://play.google.com/console/developers/${DEVELOPER_ID}/app/${PACKAGE_NAME}"
    echo ""
    
    # デプロイ履歴をログに記録
    DEPLOY_LOG="cloud-setup/deploy-history.log"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Track: $TRACK, Build: $BUILD_ID, Branch: $BRANCH, Commit: $COMMIT_SHA" >> $DEPLOY_LOG
    
    # Slack/Discord 通知（設定されている場合）
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -X POST $SLACK_WEBHOOK_URL \
            -H 'Content-Type: application/json' \
            -d "{\"text\": \"✅ デプロイ完了: ${PACKAGE_NAME} を ${TRACK} トラックにリリースしました\"}" \
            2>/dev/null || true
    fi
fi

# =============================================================================
# クリーンアップ
# =============================================================================

# 一時ファイルのクリーンアップ
rm -f /tmp/build-*.log 2>/dev/null || true

log "処理が完了しました"