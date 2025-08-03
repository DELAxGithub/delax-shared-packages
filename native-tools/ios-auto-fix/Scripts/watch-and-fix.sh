#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Watch and Fix Script
# ファイル変更を監視して自動ビルド＆フィックスを実行
# =============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WATCH_DIRS=("$PROJECT_DIR/Myprojects/Myprojects")
BUILD_SCRIPT="$PROJECT_DIR/scripts/auto-build-fix.sh"
DEBOUNCE_SECONDS=3
LAST_BUILD_TIME=0

# --- Colors for output ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[WATCH]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[WATCH]${NC} $1"
}

log_error() {
    echo -e "${RED}[WATCH]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WATCH]${NC} $1"
}

log_build() {
    echo -e "${PURPLE}[BUILD]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    # Check for fswatch (macOS) or inotifywait (Linux)
    if command -v fswatch &> /dev/null; then
        WATCH_COMMAND="fswatch"
    elif command -v inotifywait &> /dev/null; then
        WATCH_COMMAND="inotifywait"
    else
        log_error "Neither fswatch (macOS) nor inotifywait (Linux) found"
        log_info "Install fswatch: brew install fswatch"
        log_info "Install inotify-tools: apt-get install inotify-tools"
        return 1
    fi
    
    if [[ ! -x "$BUILD_SCRIPT" ]]; then
        log_error "Build script not found or not executable: $BUILD_SCRIPT"
        return 1
    fi
    
    return 0
}

# Get current timestamp
get_timestamp() {
    date +%s
}

# Check if enough time has passed since last build (debouncing)
should_build() {
    local current_time
    current_time=$(get_timestamp)
    local time_diff=$((current_time - LAST_BUILD_TIME))
    
    if [[ $time_diff -ge $DEBOUNCE_SECONDS ]]; then
        return 0
    else
        return 1
    fi
}

# Update last build time
update_build_time() {
    LAST_BUILD_TIME=$(get_timestamp)
}

# Execute build and fix
execute_build_fix() {
    local changed_file="$1"
    
    log_build "File changed: $(basename "$changed_file")"
    log_build "Starting auto build & fix..."
    
    update_build_time
    
    # Run the build script
    if "$BUILD_SCRIPT"; then
        log_success "Build successful! ✅"
    else
        log_warning "Build failed or required manual intervention"
    fi
    
    echo ""
    log_info "Continuing to watch for changes..."
}

# Handle file change events
handle_file_change() {
    local changed_file="$1"
    local filename
    filename=$(basename "$changed_file")
    
    # Skip certain file types and directories
    case "$filename" in
        .DS_Store|*.tmp|*.log|*~|*.swp|*.swo)
            return 0
            ;;
        *.xcuserstate|*.xcscheme|*.xcbkptlist)
            return 0
            ;;
    esac
    
    # Skip directories
    if [[ -d "$changed_file" ]]; then
        return 0
    fi
    
    # Only process Swift files and certain config files
    case "$filename" in
        *.swift|*.plist|*.xcconfig|*.yml|*.yaml)
            if should_build; then
                execute_build_fix "$changed_file"
            else
                log_info "Debouncing: $(basename "$changed_file") (wait $DEBOUNCE_SECONDS seconds between builds)"
            fi
            ;;
        *)
            log_info "Ignored: $(basename "$changed_file")"
            ;;
    esac
}

# Watch using fswatch (macOS)
watch_with_fswatch() {
    log_info "Using fswatch for file monitoring..."
    
    # Build exclude patterns
    local exclude_args=()
    exclude_args+=(--exclude=".git")
    exclude_args+=(--exclude="build")
    exclude_args+=(--exclude="DerivedData")
    exclude_args+=(--exclude=".DS_Store")
    exclude_args+=(--exclude="*.xcuserstate")
    exclude_args+=(--exclude="*.log")
    
    fswatch "${exclude_args[@]}" -o "${WATCH_DIRS[@]}" | while read -r num_changes; do
        if [[ $num_changes -gt 0 ]]; then
            # Get the most recently changed file
            local recent_file
            recent_file=$(find "${WATCH_DIRS[@]}" -name "*.swift" -type f -exec stat -f "%m %N" {} \; 2>/dev/null | \
                         sort -nr | head -1 | cut -d' ' -f2-)
            
            if [[ -n "$recent_file" ]]; then
                handle_file_change "$recent_file"
            fi
        fi
    done
}

# Watch using inotifywait (Linux)
watch_with_inotifywait() {
    log_info "Using inotifywait for file monitoring..."
    
    while true; do
        # Monitor for modify, create, and move events
        local changed_file
        changed_file=$(inotifywait -r -e modify,create,moved_to --format '%w%f' "${WATCH_DIRS[@]}" 2>/dev/null)
        
        if [[ -n "$changed_file" ]]; then
            handle_file_change "$changed_file"
        fi
    done
}

# Signal handlers
cleanup() {
    log_info "Shutting down file watcher..."
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Show help
show_help() {
    cat << EOF
iOS Auto Build & Fix Watcher

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -d, --debounce SEC  Set debounce time in seconds (default: $DEBOUNCE_SECONDS)
    --dry-run          Show what would be watched without actually starting
    
DESCRIPTION:
    Watches Swift source files for changes and automatically runs the
    build & fix process when files are modified.
    
    Monitored directories:
$(printf "    - %s\n" "${WATCH_DIRS[@]}")
    
    Build script: $BUILD_SCRIPT
    
EXAMPLES:
    $0                          # Start watching with default settings
    $0 -d 5                     # Use 5 second debounce time
    $0 --dry-run               # Show what would be monitored
    
NOTES:
    - Uses fswatch on macOS, inotifywait on Linux
    - Ignores temporary files, user state files, and non-Swift files
    - Includes debouncing to avoid excessive builds
    - Press Ctrl+C to stop watching
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--debounce)
                if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                    DEBOUNCE_SECONDS="$2"
                    shift 2
                else
                    log_error "Invalid debounce time: $2"
                    exit 1
                fi
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Dry run mode
dry_run() {
    log_info "DRY RUN MODE - No actual watching will occur"
    echo ""
    echo "Configuration:"
    echo "  Watch command: $WATCH_COMMAND"
    echo "  Debounce time: $DEBOUNCE_SECONDS seconds"
    echo "  Build script: $BUILD_SCRIPT"
    echo ""
    echo "Monitored directories:"
    for dir in "${WATCH_DIRS[@]}"; do
        echo "  - $dir"
        if [[ -d "$dir" ]]; then
            local swift_count
            swift_count=$(find "$dir" -name "*.swift" -type f | wc -l)
            echo "    (Contains $swift_count Swift files)"
        else
            echo "    (Directory does not exist)"
        fi
    done
    echo ""
    echo "File patterns that will trigger builds:"
    echo "  - *.swift"
    echo "  - *.plist"
    echo "  - *.xcconfig"
    echo "  - *.yml, *.yaml"
    echo ""
    echo "Ignored patterns:"
    echo "  - .DS_Store, *.tmp, *.log, *~, *.swp"
    echo "  - *.xcuserstate, *.xcscheme, *.xcbkptlist"
    echo "  - .git/, build/, DerivedData/"
}

# Main execution
main() {
    parse_args "$@"
    
    log_info "Starting iOS Auto Build & Fix Watcher"
    log_info "Project: $PROJECT_DIR"
    log_info "Debounce: ${DEBOUNCE_SECONDS}s"
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        # Check prerequisites for dry run to set WATCH_COMMAND
        if ! check_prerequisites; then
            WATCH_COMMAND="not_available"
        fi
        dry_run
        return 0
    fi
    
    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi
    
    log_info "Using $WATCH_COMMAND for file monitoring"
    log_success "Watching for file changes... (Press Ctrl+C to stop)"
    echo ""
    
    # Start appropriate watcher
    case "$WATCH_COMMAND" in
        fswatch)
            watch_with_fswatch
            ;;
        inotifywait)
            watch_with_inotifywait
            ;;
        *)
            log_error "Unknown watch command: $WATCH_COMMAND"
            exit 1
            ;;
    esac
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi