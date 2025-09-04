#!/bin/bash
#
# プロジェクト初期化スクリプト（Cloud Shell用）
# リポジトリをクローンして初期セットアップを実行
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

# =============================================================================
# Cloud Shell 起動時の自動セットアップ
# =============================================================================

log "Cloud Shell 環境を初期化中..."

# 必要なツールのインストール
log "必要なツールをインストール中..."

# Android SDK のインストール（Cloud Shell にはプリインストールされていない場合）
if [ ! -d "$HOME/android-sdk" ]; then
    log "Android SDK をインストール中..."
    
    # Command line tools のダウンロード
    mkdir -p $HOME/android-sdk
    cd $HOME/android-sdk
    
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
    unzip -q commandlinetools-linux-9477386_latest.zip
    rm commandlinetools-linux-9477386_latest.zip
    
    # 環境変数の設定
    export ANDROID_HOME=$HOME/android-sdk
    export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
    
    # .bashrc に追加
    echo "export ANDROID_HOME=$HOME/android-sdk" >> ~/.bashrc
    echo "export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools" >> ~/.bashrc
    
    # SDK のセットアップ
    yes | $ANDROID_HOME/cmdline-tools/bin/sdkmanager --sdk_root=$ANDROID_HOME --licenses
    $ANDROID_HOME/cmdline-tools/bin/sdkmanager --sdk_root=$ANDROID_HOME \
        "platform-tools" \
        "platforms;android-34" \
        "build-tools;34.0.0"
    
    log "Android SDK のインストール完了"
fi

# Gradle のインストール（必要に応じて）
if [ ! -d "$HOME/gradle" ]; then
    log "Gradle をインストール中..."
    
    GRADLE_VERSION="8.5"
    wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
    unzip -q gradle-${GRADLE_VERSION}-bin.zip -d $HOME
    mv $HOME/gradle-${GRADLE_VERSION} $HOME/gradle
    rm gradle-${GRADLE_VERSION}-bin.zip
    
    export PATH=$PATH:$HOME/gradle/bin
    echo "export PATH=\$PATH:$HOME/gradle/bin" >> ~/.bashrc
    
    log "Gradle のインストール完了"
fi

# =============================================================================
# プロジェクトのクローンとセットアップ
# =============================================================================

log "プロジェクトをセットアップ中..."

# GitHubからクローン
if [ ! -d "positive-converter" ]; then
    read -p "GitHub リポジトリのURL（HTTPS）を入力してください: " REPO_URL
    
    if [ -z "$REPO_URL" ]; then
        error "リポジトリURLが入力されていません"
    fi
    
    git clone $REPO_URL positive-converter
fi

cd positive-converter

# cloud-setup ディレクトリが存在しない場合は作成
if [ ! -d "cloud-setup" ]; then
    mkdir -p cloud-setup
    log "cloud-setup ディレクトリを作成しました"
fi

# =============================================================================
# 環境変数の読み込み
# =============================================================================

if [ -f "cloud-setup/cloud-config.env" ]; then
    log "既存の設定を読み込み中..."
    source cloud-setup/cloud-config.env
else
    log "新規セットアップを開始します"
    
    # setup-all.sh を実行
    if [ -f "cloud-setup/setup-all.sh" ]; then
        bash cloud-setup/setup-all.sh
    else
        error "setup-all.sh が見つかりません"
    fi
fi

# =============================================================================
# ローカルビルドの準備
# =============================================================================

log "ローカルビルド環境を準備中..."

# Secret Manager から必要なファイルを取得
if [ -n "$PROJECT_ID" ]; then
    log "Secret Manager から設定ファイルを取得中..."
    
    # google-services.json を取得
    if [ ! -f "app/google-services.json" ]; then
        gcloud secrets versions access latest \
            --secret="google-services-json" \
            --project=$PROJECT_ID > app/google-services.json
        log "google-services.json を取得しました"
    fi
    
    # キーストアを取得（ローカルビルド用）
    if [ ! -f "release.keystore" ]; then
        read -p "ローカルビルド用にキーストアを取得しますか？ [y/N]: " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gcloud secrets versions access latest \
                --secret="android-keystore" \
                --project=$PROJECT_ID > release.keystore
            
            # パスワードも取得してgradle.propertiesに設定
            KEYSTORE_PASSWORD=$(gcloud secrets versions access latest \
                --secret="keystore-password" \
                --project=$PROJECT_ID)
            KEY_PASSWORD=$(gcloud secrets versions access latest \
                --secret="key-password" \
                --project=$PROJECT_ID)
            
            cat > gradle.properties <<EOF
KEYSTORE_PATH=../release.keystore
KEY_ALIAS=app-release
KEY_PASSWORD=$KEY_PASSWORD
KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD
EOF
            
            log "キーストアとgradle.properties を設定しました"
        fi
    fi
fi

# =============================================================================
# 依存関係のインストール
# =============================================================================

log "プロジェクトの依存関係をインストール中..."

# Gradle の依存関係をダウンロード
./gradlew --no-daemon dependencies

log "依存関係のインストール完了"

# =============================================================================
# 完了メッセージ
# =============================================================================

echo ""
echo "========================================================================="
echo -e "${GREEN}プロジェクトの初期化が完了しました！${NC}"
echo "========================================================================="
echo ""
echo "利用可能なコマンド:"
echo ""
echo "  # ローカルビルド（デバッグ）"
echo "  ./gradlew assembleDebug"
echo ""
echo "  # ローカルビルド（リリース）"
echo "  ./gradlew bundleRelease"
echo ""
echo "  # Cloud Build で手動ビルド"
echo "  bash cloud-setup/deploy.sh"
echo ""
echo "  # テスト実行"
echo "  ./gradlew test"
echo ""
echo "  # クリーンビルド"
echo "  ./gradlew clean build"
echo ""
echo "========================================================================="