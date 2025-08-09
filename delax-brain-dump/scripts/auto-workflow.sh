#!/bin/bash

# DELAX Brain Dump Auto Workflow
# 新しいファイルを検出したときに自動で分類→GitHub送信を実行

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAIN_DUMP_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$BRAIN_DUMP_DIR/auto-config.json"
LOG_FILE="$BRAIN_DUMP_DIR/auto-workflow.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Send notification
notify() {
    local message="$1"
    local title="${2:-DELAX Brain Dump}"
    local sound="${3:-Glass}"
    
    log "📬 Notification: $message"
    
    # macOS notification
    if command -v osascript &> /dev/null; then
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
    fi
    
    # TODO: Add Slack webhook support
}

# Load configuration
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        # Create default configuration
        cat > "$CONFIG_FILE" << 'EOF'
{
  "auto_github_send": true,
  "review_delay_seconds": 30,
  "notification_enabled": true,
  "slack_webhook": "",
  "auto_archive": true,
  "file_patterns": ["*.md"],
  "exclude_patterns": [".*", "temp*", "draft*"],
  "github_send_mode": "auto"
}
EOF
        log "📝 Created default configuration: $CONFIG_FILE"
    fi
    
    # Read configuration values
    AUTO_GITHUB_SEND=$(jq -r '.auto_github_send // true' "$CONFIG_FILE")
    REVIEW_DELAY=$(jq -r '.review_delay_seconds // 30' "$CONFIG_FILE")
    NOTIFICATION_ENABLED=$(jq -r '.notification_enabled // true' "$CONFIG_FILE")
    GITHUB_SEND_MODE=$(jq -r '.github_send_mode // "auto"' "$CONFIG_FILE")
}

# Check if file should be processed
should_process_file() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    
    # Check exclude patterns
    local exclude_patterns=$(jq -r '.exclude_patterns[]?' "$CONFIG_FILE" 2>/dev/null || echo "")
    for pattern in $exclude_patterns; do
        if [[ "$filename" == $pattern ]]; then
            log "⏭️  Skipping excluded file: $filename (pattern: $pattern)"
            return 1
        fi
    done
    
    # Check if file is markdown
    if [[ ! "$filename" =~ \.md$ ]]; then
        log "⏭️  Skipping non-markdown file: $filename"
        return 1
    fi
    
    return 0
}

# Main workflow function
process_workflow() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    
    log "🚀 Starting auto workflow for: $filename"
    
    # Load configuration
    load_config
    
    # Check if file should be processed
    if ! should_process_file "$file_path"; then
        return 0
    fi
    
    # Step 1: Try filename-based repository mapping first
    log "📂 Step 1a: Checking filename-based repository mapping..."
    local repo_url=""
    local use_filename_mapping=false
    
    if source "$SCRIPT_DIR/repo-mapper.sh" && repo_url=$(map_filename_to_repo "$filename" false) 2>/dev/null; then
        if [ -n "$repo_url" ]; then
            use_filename_mapping=true
            log "✅ Repository mapped from filename: $repo_url"
            
            # Check if file contains multiple issues
            local split_count=0
            if source "$SCRIPT_DIR/issue-splitter.sh" && detect_multiple_issues "$file_path" 2>/dev/null; then
                log "🔢 Multiple issues detected, splitting file..."
                local temp_dir="$BRAIN_DUMP_DIR/temp/split-$(date +%s)"
                mkdir -p "$temp_dir"
                
                if split_count=$(split_issues "$file_path" "$temp_dir" "$filename" 2>/dev/null); then
                    log "📄 Split into $split_count issue files"
                else
                    log "❌ Failed to split issues"
                    return 1
                fi
                
                # Process each split file
                local success_count=0
                for split_file in "$temp_dir"/*.md; do
                    if [ -f "$split_file" ]; then
                        local split_filename=$(basename "$split_file")
                        log "📤 Creating GitHub issue from split file: $split_filename"
                        
                        # Generate issue title from split file
                        local issue_title=$(head -n 10 "$split_file" | grep -E "^##[[:space:]]" | head -n 1 | sed 's/^##[[:space:]]*//' | cut -c1-50)
                        if [ -z "$issue_title" ]; then
                            issue_title=$(head -n 5 "$split_file" | grep -v "^$" | head -n 1 | sed 's/^[#[:space:]]*//' | cut -c1-50)
                        fi
                        if [ -z "$issue_title" ]; then
                            issue_title="Issue $((success_count + 1)) from $filename"
                        fi
                        local issue_body=$(cat "$split_file")
                        
                        if [ "$GITHUB_SEND_MODE" = "dry-run" ]; then
                            log "🧪 DRY RUN - Would create issue: $issue_title"
                        else
                            if gh issue create --repo "$repo_url" --title "$issue_title" --body "$issue_body" >/dev/null 2>&1; then
                                success_count=$((success_count + 1))
                                log "✅ GitHub issue created: $issue_title"
                            else
                                log "❌ Failed to create issue: $issue_title"
                            fi
                        fi
                    fi
                done
                
                # Clean up temp directory
                rm -rf "$temp_dir"
                
                if [ "$NOTIFICATION_ENABLED" = "true" ]; then
                    if [ "$GITHUB_SEND_MODE" = "dry-run" ]; then
                        notify "Dry-run: Would create $split_count issues from $filename" "DELAX Brain Dump" "Glass"
                    else
                        notify "✅ Created $success_count/$split_count GitHub issues from $filename" "DELAX Success" "Hero"
                    fi
                fi
                
                # Archive original file
                mkdir -p "$BRAIN_DUMP_DIR/archive"
                mv "$file_path" "$BRAIN_DUMP_DIR/archive/"
                log "📦 Archived original file to archive/$filename"
                
                if [ "$GITHUB_SEND_MODE" = "dry-run" ]; then
                    log "🎉 Filename-based workflow completed for: $filename (would create $split_count issues)"
                else
                    log "🎉 Filename-based workflow completed for: $filename ($success_count/$split_count issues created)"
                fi
                return 0
            else
                log "📝 Single issue detected, creating single GitHub issue..."
                local issue_title=$(head -n 5 "$file_path" | grep -v "^$" | head -n 1 | sed 's/^[#[:space:]]*//' | cut -c1-50)
                local issue_body=$(cat "$file_path")
                
                if [ -z "$issue_title" ]; then
                    issue_title="Issue from $filename"
                fi
                
                if [ "$GITHUB_SEND_MODE" = "dry-run" ]; then
                    log "🧪 DRY RUN - Would create issue: $issue_title"
                    if [ "$NOTIFICATION_ENABLED" = "true" ]; then
                        notify "Dry-run: Would create issue from $filename" "DELAX Brain Dump" "Glass"
                    fi
                else
                    if gh issue create --repo "$repo_url" --title "$issue_title" --body "$issue_body" >/dev/null 2>&1; then
                        log "✅ GitHub issue created: $issue_title"
                        if [ "$NOTIFICATION_ENABLED" = "true" ]; then
                            notify "✅ GitHub issue created from $filename" "DELAX Success" "Hero"
                        fi
                        
                        # Archive original file
                        mkdir -p "$BRAIN_DUMP_DIR/archive"
                        mv "$file_path" "$BRAIN_DUMP_DIR/archive/"
                        log "📦 Archived original file to archive/$filename"
                        
                        log "🎉 Filename-based workflow completed for: $filename"
                        return 0
                    else
                        log "❌ Failed to create GitHub issue"
                        if [ "$NOTIFICATION_ENABLED" = "true" ]; then
                            notify "❌ GitHub issue creation failed for $filename" "DELAX Error" "Basso"
                        fi
                    fi
                fi
            fi
        fi
    fi
    
    if [ "$use_filename_mapping" = "false" ]; then
        log "⚠️  Filename mapping failed, falling back to AI classification..."
        
        # Step 1b: AI Classification (fallback)
        log "🤖 Step 1b: Running AI classification..."
        if [ "$NOTIFICATION_ENABLED" = "true" ]; then
            notify "Classifying: $filename" "DELAX Brain Dump" "Tink"
        fi
        
        if ! "$SCRIPT_DIR/classify-issues.sh"; then
            log "❌ Classification failed for: $filename"
            notify "Classification failed: $filename" "DELAX Error" "Basso"
            return 1
        fi
        
        log "✅ Classification completed for: $filename"
    fi
    
    # Determine the classified category and file location
    local classified_file=""
    local category=""
    
    # Find where the file was moved to
    for cat_dir in "$BRAIN_DUMP_DIR/projects/"*; do
        if [ -d "$cat_dir" ]; then
            local cat_name=$(basename "$cat_dir")
            if [ -f "$cat_dir/$filename" ]; then
                classified_file="$cat_dir/$filename"
                category="$cat_name"
                break
            fi
        fi
    done
    
    if [ -z "$classified_file" ]; then
        log "❌ Could not find classified file: $filename"
        return 1
    fi
    
    log "📁 File classified as: $category"
    log "📄 Classified file location: $classified_file"
    
    # Step 2: Review delay (if configured)
    if [ "$REVIEW_DELAY" -gt 0 ]; then
        log "⏳ Step 2: Review delay ($REVIEW_DELAY seconds)..."
        if [ "$NOTIFICATION_ENABLED" = "true" ]; then
            notify "Review period: $REVIEW_DELAY seconds for $filename" "DELAX Brain Dump" "Tink"
        fi
        sleep "$REVIEW_DELAY"
    fi
    
    # Step 3: GitHub Integration
    case "$GITHUB_SEND_MODE" in
        "auto")
            if [ "$AUTO_GITHUB_SEND" = "true" ]; then
                log "📤 Step 3: Creating GitHub issue automatically..."
                if [ "$NOTIFICATION_ENABLED" = "true" ]; then
                    notify "Creating GitHub issue: $filename" "DELAX Brain Dump" "Tink"
                fi
                
                # Use relative path for push script
                local relative_path="$category/$filename"
                if "$SCRIPT_DIR/push-to-github.sh" -f "$relative_path"; then
                    log "✅ GitHub issue created successfully for: $filename"
                    if [ "$NOTIFICATION_ENABLED" = "true" ]; then
                        notify "✅ GitHub issue created: $filename" "DELAX Success" "Hero"
                    fi
                else
                    log "❌ GitHub issue creation failed for: $filename"
                    if [ "$NOTIFICATION_ENABLED" = "true" ]; then
                        notify "❌ GitHub issue failed: $filename" "DELAX Error" "Basso"
                    fi
                    return 1
                fi
            else
                log "⏸️  GitHub sending disabled in config"
                if [ "$NOTIFICATION_ENABLED" = "true" ]; then
                    notify "Ready for manual GitHub send: $filename" "DELAX Brain Dump" "Glass"
                fi
            fi
            ;;
        "manual")
            log "🔧 Manual GitHub send mode - skipping auto send"
            if [ "$NOTIFICATION_ENABLED" = "true" ]; then
                notify "Manual send required: $filename" "DELAX Brain Dump" "Glass"
            fi
            ;;
        "dry-run")
            log "🧪 Dry-run mode - testing GitHub send..."
            local relative_path="$category/$filename"
            "$SCRIPT_DIR/push-to-github.sh" --dry-run -f "$relative_path"
            if [ "$NOTIFICATION_ENABLED" = "true" ]; then
                notify "Dry-run completed: $filename" "DELAX Brain Dump" "Glass"
            fi
            ;;
    esac
    
    log "🎉 Auto workflow completed for: $filename"
    return 0
}

# Usage information
usage() {
    echo "Usage: $0 <file_path>"
    echo ""
    echo "Process a single file through the complete Brain Dump workflow:"
    echo "  1. AI classification"
    echo "  2. Review delay (configurable)"  
    echo "  3. GitHub issue creation (configurable)"
    echo ""
    echo "Configuration is read from: auto-config.json"
    echo ""
}

# Main execution
main() {
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi
    
    local file_path="$1"
    
    if [ ! -f "$file_path" ]; then
        echo -e "${RED}❌ File not found: $file_path${NC}"
        exit 1
    fi
    
    log "🎯 Auto workflow triggered for: $(basename "$file_path")"
    
    if process_workflow "$file_path"; then
        log "🎉 Workflow completed successfully"
        exit 0
    else
        log "❌ Workflow failed"
        exit 1
    fi
}

# Handle script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi