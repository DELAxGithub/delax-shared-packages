#!/bin/bash

# 手動プル用の汎用コマンド - パラメータ化版
# 任意のプロジェクトでワンコマンドでプル→通知→ビルド推奨まで実行

set -e

# 設定ファイルから設定を読み込み（存在する場合）
CONFIG_FILE="${DELAX_CONFIG_FILE:-./delax-config.yml}"
MAIN_BRANCH="${DELAX_MAIN_BRANCH:-main}"
REMOTE_NAME="${DELAX_REMOTE_NAME:-origin}"
PROJECT_NAME="${DELAX_PROJECT_NAME:-$(basename "$(pwd)")}"
PROJECT_TYPE="${DELAX_PROJECT_TYPE:-generic}"

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Quick Pull - ${PROJECT_NAME} プロジェクト${NC}"
echo ""

# 設定ファイルが存在する場合は読み込み
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${BLUE}📋 Loading config from $CONFIG_FILE${NC}"
    # YAMLの簡単な読み込み（bashでは限定的）
    if command -v yq >/dev/null 2>&1; then
        MAIN_BRANCH=$(yq eval '.git.main_branch // "main"' "$CONFIG_FILE" 2>/dev/null || echo "$MAIN_BRANCH")
        REMOTE_NAME=$(yq eval '.git.remote_name // "origin"' "$CONFIG_FILE" 2>/dev/null || echo "$REMOTE_NAME")
        PROJECT_NAME=$(yq eval '.project.name // ""' "$CONFIG_FILE" 2>/dev/null || echo "$PROJECT_NAME")
        PROJECT_TYPE=$(yq eval '.project.type // "generic"' "$CONFIG_FILE" 2>/dev/null || echo "$PROJECT_TYPE")
    fi
fi

# 現在のディレクトリがGitリポジトリかチェック
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo -e "${RED}❌ Not a git repository${NC}"
    exit 1
fi

# 現在のブランチがmainかチェック
current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
if [ "$current_branch" != "$MAIN_BRANCH" ]; then
    echo -e "${YELLOW}⚠️ Current branch is '$current_branch', switching to '$MAIN_BRANCH'...${NC}"
    git checkout "$MAIN_BRANCH" 2>/dev/null || {
        echo -e "${RED}❌ Failed to switch to main branch${NC}"
        exit 1
    }
fi

# プル前の状態を記録
echo -e "${BLUE}📊 Checking current status...${NC}"
current_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
short_current=$(echo "$current_commit" | cut -c1-8)

# 作業ディレクトリの状態をチェック
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${YELLOW}⚠️ Working directory has uncommitted changes${NC}"
    echo -e "${BLUE}💡 Please commit or stash your changes before pulling${NC}"
    echo ""
    echo -e "${PURPLE}Uncommitted files:${NC}"
    git status --porcelain
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🛑 Pull cancelled${NC}"
        exit 0
    fi
fi

# Fetch to check for updates
echo -e "${BLUE}🔍 Fetching latest changes...${NC}"
if ! git fetch "$REMOTE_NAME" "$MAIN_BRANCH" 2>/dev/null; then
    echo -e "${RED}❌ Failed to fetch from remote${NC}"
    exit 1
fi

# リモートの最新コミットを取得
remote_commit=$(git rev-parse "$REMOTE_NAME/$MAIN_BRANCH" 2>/dev/null || echo "unknown")
short_remote=$(echo "$remote_commit" | cut -c1-8)

# 更新があるかチェック
if [ "$current_commit" = "$remote_commit" ]; then
    echo -e "${GREEN}✅ Already up to date${NC}"
    echo -e "${PURPLE}Current commit: $short_current${NC}"
    
    # 通知は送信（テスト用）
    echo -e "${BLUE}📢 Sending notification anyway...${NC}"
    if command -v delax-notify >/dev/null 2>&1; then
        delax-notify build-recommended
    elif [ -f "$(dirname "$0")/notify.sh" ]; then
        "$(dirname "$0")/notify.sh" build-recommended
    fi
    exit 0
fi

# 変更の概要を表示
echo -e "${YELLOW}📥 New changes detected!${NC}"
echo -e "${PURPLE}Current:  $short_current${NC}"
echo -e "${PURPLE}Remote:   $short_remote${NC}"
echo ""

# コミット履歴を表示（最大5件）
echo -e "${BLUE}📋 Recent commits to pull:${NC}"
git log --oneline "${current_commit}..${remote_commit}" -n 5 2>/dev/null || echo "Unable to show commit history"
echo ""

# プル実行の確認
read -p "Pull these changes? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}🛑 Pull cancelled${NC}"
    exit 0
fi

# プル実行
echo -e "${BLUE}🔄 Pulling changes...${NC}"
if git pull "$REMOTE_NAME" "$MAIN_BRANCH" 2>/dev/null; then
    echo -e "${GREEN}✅ Successfully pulled latest changes!${NC}"
    
    new_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    short_new=$(echo "$new_commit" | cut -c1-8)
    
    echo -e "${PURPLE}Updated: $short_current → $short_new${NC}"
    echo ""
    
    # 成功通知を送信
    echo -e "${BLUE}📢 Sending notifications...${NC}"
    if command -v delax-notify >/dev/null 2>&1; then
        # プル完了通知
        delax-notify merge-pulled "$new_commit"
        echo -e "${GREEN}📱 Pull completion notification sent${NC}"
        
        # 少し待ってからビルド推奨通知
        sleep 1
        echo -e "${GREEN}🔨 Build recommendation sent${NC}"
    elif [ -f "$(dirname "$0")/notify.sh" ]; then
        "$(dirname "$0")/notify.sh" merge-pulled "$new_commit"
    else
        echo -e "${YELLOW}⚠️ Notification script not found, skipping notifications${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Quick pull completed successfully!${NC}"
    echo -e "${BLUE}💡 Next steps (${PROJECT_TYPE} project):${NC}"
    
    case "$PROJECT_TYPE" in
        "ios-swift")
            echo -e "${PURPLE}   1. Open Xcode${NC}"
            echo -e "${PURPLE}   2. Build the project (⌘+B)${NC}"
            echo -e "${PURPLE}   3. Test on simulator or device${NC}"
            ;;
        "react-typescript"|"pm-web")
            echo -e "${PURPLE}   1. Run: pnpm install${NC}"
            echo -e "${PURPLE}   2. Run: pnpm dev${NC}"
            echo -e "${PURPLE}   3. Test in browser${NC}"
            ;;
        "flutter")
            echo -e "${PURPLE}   1. Run: flutter pub get${NC}"
            echo -e "${PURPLE}   2. Run: flutter run${NC}"
            echo -e "${PURPLE}   3. Test on simulator or device${NC}"
            ;;
        *)
            echo -e "${PURPLE}   1. Run project-specific build command${NC}"
            echo -e "${PURPLE}   2. Test the changes${NC}"
            echo -e "${PURPLE}   3. Verify functionality${NC}"
            ;;
    esac
    echo ""
    
else
    echo -e "${RED}❌ Failed to pull changes${NC}"
    echo ""
    echo -e "${BLUE}💡 Possible solutions:${NC}"
    echo -e "${PURPLE}   1. Check for merge conflicts${NC}"
    echo -e "${PURPLE}   2. Ensure you have the latest changes committed${NC}"
    echo -e "${PURPLE}   3. Try: git status${NC}"
    exit 1
fi