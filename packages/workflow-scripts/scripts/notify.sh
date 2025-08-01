#!/bin/bash

# 汎用通知システムスクリプト - パラメータ化版
# GitHub Actions や手動実行から呼び出し可能

set -e

# 設定読み込み
CONFIG_FILE="${DELAX_CONFIG_FILE:-./delax-config.yml}"
PROJECT_NAME="${DELAX_PROJECT_NAME:-$(basename "$(pwd)")}"
PROJECT_TYPE="${DELAX_PROJECT_TYPE:-generic}"

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 設定ファイルから設定を読み込み
if [ -f "$CONFIG_FILE" ] && command -v yq >/dev/null 2>&1; then
    PROJECT_NAME=$(yq eval '.project.name // ""' "$CONFIG_FILE" 2>/dev/null || echo "$PROJECT_NAME")
    PROJECT_TYPE=$(yq eval '.project.type // "generic"' "$CONFIG_FILE" 2>/dev/null || echo "$PROJECT_TYPE")
fi

# 使用方法を表示
show_help() {
    echo -e "${BLUE}📢 DELAX 汎用通知システム${NC}"
    echo ""
    echo "使用方法:"
    echo "  delax-notify <通知タイプ> [オプション]"
    echo "  または"
    echo "  ./scripts/notify.sh <通知タイプ> [オプション]"
    echo ""
    echo "通知タイプ:"
    echo "  pr-created <PR番号>         - PR作成通知"
    echo "  build-success <PR番号>      - ビルド成功通知"
    echo "  build-failure <PR番号>      - ビルド失敗通知"
    echo "  ready-to-merge <PR番号>     - マージ準備完了通知"
    echo "  issue-fixed <Issue番号>     - Issue修正完了通知"
    echo "  merge-completed <PR番号>    - マージ完了通知"
    echo "  merge-pulled <コミット>      - プル完了通知"
    echo "  build-recommended           - ビルド推奨通知"
    echo ""
    echo "プロジェクト設定:"
    echo "  PROJECT_NAME: $PROJECT_NAME"
    echo "  PROJECT_TYPE: $PROJECT_TYPE"
    echo ""
    echo "例:"
    echo "  delax-notify pr-created 30"
    echo "  delax-notify build-success 30"
    echo "  delax-notify merge-completed 30"
    echo "  delax-notify merge-pulled abc1234"
    echo "  delax-notify build-recommended"
    echo ""
}

# macOS通知を送信
send_macos_notification() {
    local title="$1"
    local message="$2"
    local sound="${3:-Blow}"
    
    if command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
        echo -e "${GREEN}📱 macOS通知を送信しました${NC}"
    else
        echo -e "${YELLOW}⚠️  macOS通知機能が利用できません${NC}"
    fi
}

# Slack通知（環境変数 SLACK_WEBHOOK_URL が設定されている場合）
send_slack_notification() {
    local message="$1"
    local emoji="${2:-:bell:}"
    
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$emoji [$PROJECT_NAME] $message\"}" \
            "$SLACK_WEBHOOK_URL" >/dev/null 2>&1
        echo -e "${GREEN}📤 Slack通知を送信しました${NC}"
    else
        echo -e "${YELLOW}ℹ️  Slack通知をスキップ（SLACK_WEBHOOK_URL未設定）${NC}"
    fi
}

# メール通知（環境変数 NOTIFICATION_EMAIL が設定されている場合）
send_email_notification() {
    local subject="$1"
    local body="$2"
    
    if [ -n "$NOTIFICATION_EMAIL" ] && command -v mail >/dev/null 2>&1; then
        echo "$body" | mail -s "[$PROJECT_NAME] $subject" "$NOTIFICATION_EMAIL"
        echo -e "${GREEN}📧 メール通知を送信しました${NC}"
    else
        echo -e "${YELLOW}ℹ️  メール通知をスキップ（設定未完了）${NC}"
    fi
}

# PR情報を取得
get_pr_info() {
    local pr_number="$1"
    if command -v gh >/dev/null 2>&1; then
        gh pr view "$pr_number" --json title,url,author,headRefName 2>/dev/null || {
            echo -e "${RED}❌ PR #${pr_number} の情報取得に失敗${NC}"
            return 1
        }
    else
        echo -e "${YELLOW}⚠️ GitHub CLI (gh) が利用できません${NC}"
        return 1
    fi
}

# Issue情報を取得
get_issue_info() {
    local issue_number="$1"
    if command -v gh >/dev/null 2>&1; then
        gh issue view "$issue_number" --json title,url,author 2>/dev/null || {
            echo -e "${RED}❌ Issue #${issue_number} の情報取得に失敗${NC}"
            return 1
        }
    else
        echo -e "${YELLOW}⚠️ GitHub CLI (gh) が利用できません${NC}"
        return 1
    fi
}

# プロジェクト種別に応じたビルドコマンドを取得
get_build_command() {
    case "$PROJECT_TYPE" in
        "ios-swift")
            echo "./build.sh または Xcodeで⌘+B"
            ;;
        "react-typescript"|"pm-web")
            echo "pnpm run build または pnpm dev"
            ;;
        "flutter")
            echo "flutter build または flutter run"
            ;;
        *)
            echo "プロジェクト固有のビルドコマンド"
            ;;
    esac
}

# 引数チェック
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

NOTIFICATION_TYPE="$1"
TARGET_NUMBER="$2"

echo -e "${BLUE}📢 通知システムを開始: $NOTIFICATION_TYPE (${PROJECT_NAME})${NC}"

case "$NOTIFICATION_TYPE" in
    "pr-created")
        if [ -z "$TARGET_NUMBER" ]; then
            echo -e "${RED}❌ PR番号が必要です${NC}"
            exit 1
        fi
        
        PR_INFO=$(get_pr_info "$TARGET_NUMBER")
        if [ $? -eq 0 ] && command -v jq >/dev/null 2>&1; then
            PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')
            PR_URL=$(echo "$PR_INFO" | jq -r '.url')
            PR_AUTHOR=$(echo "$PR_INFO" | jq -r '.author.login')
            
            TITLE="🆕 新しいPRが作成されました"
            MESSAGE="PR #${TARGET_NUMBER}: ${PR_TITLE} by ${PR_AUTHOR}"
            
            echo -e "${GREEN}✅ PR作成通知${NC}"
            echo "  📝 $PR_TITLE"
            echo "  👤 作成者: $PR_AUTHOR"
            echo "  🔗 $PR_URL"
            
            send_macos_notification "$TITLE" "$MESSAGE" "Glass"
            send_slack_notification "🆕 新しいPR作成: [#${TARGET_NUMBER} ${PR_TITLE}]($PR_URL) by @${PR_AUTHOR}" ":git:"
            send_email_notification "$TITLE" "PR詳細:\nタイトル: ${PR_TITLE}\n作成者: ${PR_AUTHOR}\nURL: ${PR_URL}"
        fi
        ;;
        
    "build-success")
        if [ -z "$TARGET_NUMBER" ]; then
            echo -e "${RED}❌ PR番号が必要です${NC}"
            exit 1
        fi
        
        PR_INFO=$(get_pr_info "$TARGET_NUMBER")
        if [ $? -eq 0 ] && command -v jq >/dev/null 2>&1; then
            PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')
            PR_URL=$(echo "$PR_INFO" | jq -r '.url')
            
            TITLE="✅ ビルド成功"
            MESSAGE="PR #${TARGET_NUMBER} の${PROJECT_TYPE}ビルドが成功しました"
            
            echo -e "${GREEN}✅ ビルド成功通知${NC}"
            echo "  📝 $PR_TITLE"
            echo "  🔗 $PR_URL"
            
            send_macos_notification "$TITLE" "$MESSAGE" "Hero"
            send_slack_notification "✅ ビルド成功: [PR #${TARGET_NUMBER}]($PR_URL) - レビュー・マージの準備ができました！" ":white_check_mark:"
            send_email_notification "$TITLE" "PR #${TARGET_NUMBER} のビルドが成功しました。\n\n詳細: ${PR_URL}"
        fi
        ;;
        
    "build-failure")
        if [ -z "$TARGET_NUMBER" ]; then
            echo -e "${RED}❌ PR番号が必要です${NC}"
            exit 1
        fi
        
        PR_INFO=$(get_pr_info "$TARGET_NUMBER")
        if [ $? -eq 0 ] && command -v jq >/dev/null 2>&1; then
            PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')
            PR_URL=$(echo "$PR_INFO" | jq -r '.url')
            
            TITLE="❌ ビルド失敗"
            MESSAGE="PR #${TARGET_NUMBER} の${PROJECT_TYPE}ビルドが失敗しました"
            
            echo -e "${RED}❌ ビルド失敗通知${NC}"
            echo "  📝 $PR_TITLE"
            echo "  🔗 $PR_URL"
            
            send_macos_notification "$TITLE" "$MESSAGE" "Basso"
            send_slack_notification "❌ ビルド失敗: [PR #${TARGET_NUMBER}]($PR_URL) - 修正が必要です" ":x:"
            send_email_notification "$TITLE" "PR #${TARGET_NUMBER} のビルドが失敗しました。\n\n確認してください: ${PR_URL}"
        fi
        ;;
        
    "merge-pulled")
        if [ -z "$TARGET_NUMBER" ]; then
            echo -e "${RED}❌ コミットハッシュが必要です${NC}"
            exit 1
        fi
        
        COMMIT_HASH="$TARGET_NUMBER"
        SHORT_HASH="${COMMIT_HASH:0:8}"
        
        TITLE="📥 プル完了"
        MESSAGE="最新の変更をローカルに同期しました (${SHORT_HASH})"
        
        echo -e "${GREEN}📥 プル完了通知${NC}"
        echo "  🔄 コミット: $SHORT_HASH"
        echo "  💡 $(get_build_command)でテストを実行してください"
        
        send_macos_notification "$TITLE" "$MESSAGE" "Hero"
        send_slack_notification "📥 プル完了: 最新の変更を同期 (\`${SHORT_HASH}\`) - ローカルテストしてください" ":arrow_down:"
        send_email_notification "$TITLE" "最新の変更をローカルに同期しました。\\n\\nコミット: ${COMMIT_HASH}\\n\\n次のステップ: $(get_build_command)でテストを実行してください。"
        
        # ビルド推奨通知も送信
        sleep 2
        if command -v delax-notify >/dev/null 2>&1; then
            delax-notify build-recommended
        else
            "$0" build-recommended
        fi
        ;;
        
    "build-recommended")
        TITLE="🔨 ビルド推奨"
        MESSAGE="最新の変更を$(get_build_command)でテストしてください"
        
        echo -e "${BLUE}🔨 ビルド推奨通知${NC}"
        echo "  💡 $(get_build_command)"
        echo "  🧪 動作確認・テスト推奨"
        
        send_macos_notification "$TITLE" "$MESSAGE" "Ping"
        send_slack_notification "🔨 ビルド推奨: 最新の変更をローカルでテストしてください" ":hammer:"
        send_email_notification "$TITLE" "最新の変更がプルされました。\\n\\n$(get_build_command)でビルド・テストを実行してください。"
        ;;
        
    *)
        echo -e "${RED}❌ 不明な通知タイプ: $NOTIFICATION_TYPE${NC}"
        show_help
        exit 1
        ;;
esac

echo -e "${BLUE}📢 通知送信完了${NC}"