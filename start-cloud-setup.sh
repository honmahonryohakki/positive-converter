#!/bin/bash
#
# Google Cloud Shell ワンライナー実行用スクリプト
# Cloud Shell で以下のコマンドを実行:
# curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/positive-converter/main/start-cloud-setup.sh | bash
#

set -e

echo "============================================"
echo "  ポジティブ変換アプリ 自動セットアップ"
echo "============================================"
echo ""

# Cloud Shell チェック
if [ -z "$CLOUD_SHELL" ]; then
    echo "⚠️  このスクリプトは Google Cloud Shell での実行を推奨します"
    echo "    https://shell.cloud.google.com で Cloud Shell を開いてください"
    echo ""
    read -p "このまま続行しますか？ [y/N]: " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# リポジトリ情報の入力
echo "GitHub リポジトリ情報を入力してください："
read -p "GitHubユーザー名: " GITHUB_USER
read -p "リポジトリ名 [positive-converter]: " REPO_NAME
REPO_NAME=${REPO_NAME:-positive-converter}

# クローンまたは更新
if [ -d "$REPO_NAME" ]; then
    echo "既存のリポジトリを更新中..."
    cd $REPO_NAME
    git pull origin main
else
    echo "リポジトリをクローン中..."
    git clone https://github.com/${GITHUB_USER}/${REPO_NAME}.git
    cd $REPO_NAME
fi

# セットアップスクリプトの実行
if [ -f "cloud-setup/setup-all.sh" ]; then
    echo ""
    echo "セットアップを開始します..."
    bash cloud-setup/setup-all.sh
else
    echo "エラー: cloud-setup/setup-all.sh が見つかりません"
    echo "リポジトリ構造を確認してください"
    exit 1
fi