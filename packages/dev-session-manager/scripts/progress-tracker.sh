#!/bin/bash

# 📊 Universal Progress Tracker - 汎用進捗自動更新スクリプト
# Usage: ./scripts/progress-tracker.sh [update|session-start|session-end]
# Part of DELAx Dev Session Manager

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Load configuration parser
if [ -f "$LIB_DIR/config-parser.sh" ]; then
    source "$LIB_DIR/config-parser.sh"
else
    echo "❌ Configuration parser not found. Please run install script."
    exit 1
fi

# Load configuration
load_config

# Get configuration values
PROGRESS_FILE=$(get_progress_file)
BACKUP_DIR=$(get_backup_dir)
PROJECT_NAME=$(get_project_name)
PROJECT_TYPE=$(get_project_type)
BUILD_COMMAND=$(get_build_command)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Current date/time
CURRENT_DATE=$(date '+%Y-%m-%d')
CURRENT_DATETIME=$(date '+%Y-%m-%d %H:%M')

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup function
create_backup() {
    if [ -f "$PROGRESS_FILE" ]; then
        local backup_file="$BACKUP_DIR/progress_backup_$(date +%Y%m%d_%H%M%S).md"
        cp "$PROGRESS_FILE" "$backup_file"
        log_success "Backup created: $backup_file"
    fi
}

# Collect project statistics
collect_project_stats() {
    local stats_result=""
    
    # Get source directories and file extensions from config
    local source_dirs
    local file_extensions
    
    # Convert config arrays to bash arrays
    mapfile -t source_dirs < <(get_source_dirs)
    mapfile -t file_extensions < <(get_file_extensions)
    
    # Default fallback if no config
    if [ ${#source_dirs[@]} -eq 0 ]; then
        case "$PROJECT_TYPE" in
            "ios")
                source_dirs=("$PROJECT_NAME/" "Sources/" "App/")
                file_extensions=(".swift" ".h" ".m")
                ;;
            "web")
                source_dirs=("src/" "lib/" "components/")
                file_extensions=(".js" ".ts" ".jsx" ".tsx")
                ;;
            "python")
                source_dirs=("src/" "lib/" "app/")
                file_extensions=(".py")
                ;;
            *)
                source_dirs=("src/" "lib/")
                file_extensions=(".js" ".ts" ".py")
                ;;
        esac
    fi
    
    # Count files and lines
    local total_files=0
    local total_lines=0
    
    for dir in "${source_dirs[@]}"; do
        if [ -d "$dir" ]; then
            for ext in "${file_extensions[@]}"; do
                local files
                files=$(find "$dir" -name "*$ext" 2>/dev/null | wc -l | xargs)
                total_files=$((total_files + files))
                
                local lines
                lines=$(find "$dir" -name "*$ext" -exec cat {} \; 2>/dev/null | wc -l | xargs)
                total_lines=$((total_lines + lines))
            done
        fi
    done
    
    # Count TODOs
    local todo_count=0
    local todo_patterns
    mapfile -t todo_patterns < <(get_todo_patterns)
    
    if [ ${#todo_patterns[@]} -eq 0 ]; then
        todo_patterns=("TODO" "FIXME" "HACK" "NOTE")
    fi
    
    for pattern in "${todo_patterns[@]}"; do
        for dir in "${source_dirs[@]}"; do
            if [ -d "$dir" ]; then
                for ext in "${file_extensions[@]}"; do
                    local count
                    count=$(find "$dir" -name "*$ext" -exec grep -c "$pattern" {} \; 2>/dev/null | awk '{sum += $1} END {print sum+0}')
                    todo_count=$((todo_count + count))
                done
            fi
        done
    done
    
    # Git information
    local changed_files
    changed_files=$(git status --porcelain 2>/dev/null | wc -l | xargs)
    
    local last_commit
    last_commit=$(git log -1 --pretty=format:'%h - %s' 2>/dev/null || echo 'No commits')
    
    # Return statistics
    echo "project_files:$total_files"
    echo "total_lines:$total_lines"
    echo "todo_count:$todo_count"
    echo "changed_files:$changed_files"
    echo "last_commit:$last_commit"
}

# Session start function
session_start() {
    echo "🚀 Session Start - Universal Progress Tracker"
    echo "============================================="
    echo "Project: $PROJECT_NAME ($PROJECT_TYPE)"
    echo ""
    
    create_backup
    
    # Collect project statistics
    log_info "Collecting project statistics..."
    local stats
    stats=$(collect_project_stats)
    
    # Parse statistics
    local project_files=$(echo "$stats" | grep "project_files:" | cut -d':' -f2)
    local total_lines=$(echo "$stats" | grep "total_lines:" | cut -d':' -f2)
    local todo_count=$(echo "$stats" | grep "todo_count:" | cut -d':' -f2)
    local changed_files=$(echo "$stats" | grep "changed_files:" | cut -d':' -f2)
    local last_commit=$(echo "$stats" | grep "last_commit:" | cut -d':' -f2-)
    
    echo "📊 Session Start Stats:"
    echo "  Project Files: $project_files"
    echo "  Lines of Code: $total_lines"
    echo "  TODO Items: $todo_count"
    echo "  Changed Files: $changed_files"
    echo "  Last Commit: $last_commit"
    echo ""
    
    # Update progress file if it exists
    if [ -f "$PROGRESS_FILE" ]; then
        # Update Last Updated timestamp
        if grep -q "Last Updated:" "$PROGRESS_FILE"; then
            sed -i.bak "s/Last Updated: .*/Last Updated: $CURRENT_DATE/" "$PROGRESS_FILE"
        fi
        log_success "Progress file updated with session start time"
    else
        log_warning "Progress file not found: $PROGRESS_FILE"
        log_info "Consider running: cp templates/PROGRESS_UNIFIED.template.md $PROGRESS_FILE"
    fi
    
    echo "🎯 Development session ready!"
    echo ""
    echo "💡 Quick commands:"
    echo "  ./scripts/quick-status.sh     - Check current status"
    echo "  ./scripts/progress-tracker.sh session-end  - End session"
}

# Session end function
session_end() {
    echo "🏁 Session End - Universal Progress Tracker"
    echo "==========================================="
    echo "Project: $PROJECT_NAME ($PROJECT_TYPE)"
    echo ""
    
    create_backup
    
    # Git information
    local commits_since_start
    commits_since_start=$(git log --since="2 hours ago" --oneline 2>/dev/null | wc -l | xargs)
    
    local changed_files
    changed_files=$(git status --porcelain 2>/dev/null | wc -l | xargs)
    
    local recent_commits
    recent_commits=$(git log --since="2 hours ago" --pretty=format:'- %s' 2>/dev/null)
    
    echo "📊 Session Summary:"
    echo "  Commits Made: $commits_since_start"
    echo "  Files Changed: $changed_files"
    
    if [ -n "$recent_commits" ]; then
        echo "  Recent Commits:"
        echo "$recent_commits" | head -3
    fi
    
    # Check build status if build command is available
    if [ "$BUILD_COMMAND" != "make build" ]; then
        echo "  Build Command: $BUILD_COMMAND"
        echo "  (Run manually to verify build status)"
    fi
    
    echo ""
    
    # Update progress file
    if [ -f "$PROGRESS_FILE" ]; then
        # Update timestamp
        if grep -q "Last Updated:" "$PROGRESS_FILE"; then
            sed -i.bak "s/Last Updated: .*/Last Updated: $CURRENT_DATE/" "$PROGRESS_FILE"
        fi
        
        # Create session summary
        cat > session_summary_temp.md << EOF

## 🔄 Session Summary ($CURRENT_DATETIME)
- Project: $PROJECT_NAME ($PROJECT_TYPE)
- Commits: $commits_since_start
- Changed Files: $changed_files
EOF

        if [ -n "$recent_commits" ]; then
            echo "- Key Changes:" >> session_summary_temp.md
            echo "$recent_commits" | head -3 >> session_summary_temp.md
        fi
        
        echo "" >> session_summary_temp.md
        
        log_success "Session summary created: session_summary_temp.md"
        log_info "You can manually add this to $PROGRESS_FILE if needed"
    else
        log_warning "Progress file not found: $PROGRESS_FILE"
    fi
    
    echo "🎯 Session completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Review session_summary_temp.md"
    echo "  2. Update $PROGRESS_FILE with completed work"
    echo "  3. Commit changes: git add . && git commit -m \"Session completed\""
}

# Basic update function
update_progress() {
    echo "🔄 Updating Progress Information"
    echo "==============================="
    echo "Project: $PROJECT_NAME ($PROJECT_TYPE)"
    echo ""
    
    create_backup
    
    if [ -f "$PROGRESS_FILE" ]; then
        # Update timestamp
        if grep -q "Last Updated:" "$PROGRESS_FILE"; then
            sed -i.bak "s/Last Updated: .*/Last Updated: $CURRENT_DATE/" "$PROGRESS_FILE"
            log_success "Progress file date updated"
        else
            echo "Last Updated: $CURRENT_DATE" >> "$PROGRESS_FILE"
            log_success "Added timestamp to progress file"
        fi
    else
        log_error "Progress file not found: $PROGRESS_FILE"
        echo "Create it by copying from template:"
        echo "  cp templates/PROGRESS_UNIFIED.template.md $PROGRESS_FILE"
        exit 1
    fi
    
    # Show project statistics
    echo ""
    echo "📊 Current Project Stats:"
    if [ -f "./scripts/quick-status.sh" ]; then
        ./scripts/quick-status.sh
    else
        collect_project_stats | while IFS=':' read -r key value; do
            case "$key" in
                "project_files") echo "  Project Files: $value" ;;
                "total_lines") echo "  Lines of Code: $value" ;;
                "todo_count") echo "  TODO Items: $value" ;;
                "changed_files") echo "  Changed Files: $value" ;;
                "last_commit") echo "  Last Commit: $value" ;;
            esac
        done
    fi
}

# Main execution
main() {
    # Validate configuration first
    if ! validate_config >/dev/null 2>&1; then
        log_error "Invalid or missing configuration"
        echo "Run: ./lib/project-detector.sh to generate configuration"
        exit 1
    fi
    
    case "${1:-update}" in
        "session-start")
            session_start
            ;;
        "session-end")
            session_end
            ;;
        "update")
            update_progress
            ;;
        "config")
            print_config_summary
            ;;
        *)
            echo "Usage: $0 [update|session-start|session-end|config]"
            echo ""
            echo "Commands:"
            echo "  update        - Update progress file with current date"
            echo "  session-start - Initialize session and record start stats"
            echo "  session-end   - Finalize session and create summary"
            echo "  config        - Show current configuration"
            echo ""
            echo "Configuration file: dev-session-config.json"
            exit 1
            ;;
    esac
}

main "$@"