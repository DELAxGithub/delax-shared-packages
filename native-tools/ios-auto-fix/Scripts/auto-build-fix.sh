#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# iOS Xcode Auto Build & Fix Script (Generic Version)
# Universal iOS project build error auto-fix system
# =============================================================================

# --- Default Configuration ---
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XCODE_PROJECT=""
SCHEME=""
CONFIGURATION="Debug"
BUILD_LOG="${PROJECT_DIR}/build.log"
ERROR_FILE="${PROJECT_DIR}/builderror/errors.txt"
PATCH_FILE="${PROJECT_DIR}/builderror/patch.diff"
CONFIG_FILE="${PROJECT_DIR}/auto-fix-config.yml"
MAX_ATTEMPTS=5
CURRENT_ATTEMPT=0

# --- Load Configuration ---
load_config() {
    # Look for config file in multiple locations
    local config_paths=(
        "${PROJECT_DIR}/auto-fix-config.yml"
        "${PROJECT_DIR}/config/auto-fix-config.yml"
        "${HOME}/.config/ios-auto-fix/config.yml"
        "$(dirname "${BASH_SOURCE[0]}")/../Templates/auto-fix-config.yml"
    )
    
    for config_path in "${config_paths[@]}"; do
        if [[ -f "$config_path" ]]; then
            CONFIG_FILE="$config_path"
            log_info "Using config file: $config_path"
            break
        fi
    done
    
    # Parse YAML config (simplified - assumes key: value format)
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS=': ' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            
            # Remove quotes and whitespace
            value=$(echo "$value" | sed 's/^[[:space:]]*"//;s/"[[:space:]]*$//;s/^[[:space:]]*//;s/[[:space:]]*$//')
            
            case "$key" in
                "xcode_project")
                    XCODE_PROJECT="$value"
                    ;;
                "scheme")
                    SCHEME="$value"
                    ;;
                "configuration")
                    CONFIGURATION="$value"
                    ;;
                "max_attempts")
                    MAX_ATTEMPTS="$value"
                    ;;
            esac
        done < <(grep -E '^\s*(xcode_project|scheme|configuration|max_attempts):' "$CONFIG_FILE")
    fi
    
    # Validate required configuration
    if [[ -z "$XCODE_PROJECT" ]]; then
        log_error "XCODE_PROJECT not configured. Please set it in $CONFIG_FILE"
        exit 1
    fi
    
    if [[ -z "$SCHEME" ]]; then
        log_error "SCHEME not configured. Please set it in $CONFIG_FILE"
        exit 1
    fi
}

# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper Functions ---
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

cleanup() {
    log_info "Cleaning up temporary files..."
    rm -f "$BUILD_LOG" "$PATCH_FILE"
}

# --- Trap for cleanup ---
trap cleanup EXIT

# --- Main Functions ---
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v xcodebuild &> /dev/null; then
        log_error "xcodebuild not found. Make sure Xcode is installed."
        exit 1
    fi
    
    if ! command -v claude &> /dev/null; then
        log_warning "Claude CLI not found. Will skip AI-powered fixes."
        return 1
    fi
    
    if [[ ! -f "$PROJECT_DIR/$XCODE_PROJECT/project.pbxproj" ]]; then
        log_error "Xcode project not found at $XCODE_PROJECT"
        exit 1
    fi
    
    # Create builderror directory if it doesn't exist
    mkdir -p "$(dirname "$ERROR_FILE")"
    
    return 0
}

build_project() {
    log_info "Building project (Attempt $((CURRENT_ATTEMPT + 1))/$MAX_ATTEMPTS)..."
    
    cd "$PROJECT_DIR"
    
    # Clean and build with detailed logging
    xcodebuild \
        -project "$XCODE_PROJECT" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' \
        clean build \
        2>&1 | tee "$BUILD_LOG"
    
    return ${PIPESTATUS[0]}
}

extract_errors() {
    log_info "Extracting build errors..."
    
    if [[ ! -f "$BUILD_LOG" ]]; then
        log_error "Build log not found"
        return 1
    fi
    
    # Call our error extraction script
    "$(dirname "${BASH_SOURCE[0]}")/extract-xcode-errors.sh" "$BUILD_LOG" > "$ERROR_FILE"
    
    if [[ ! -s "$ERROR_FILE" ]]; then
        log_info "No errors found in build log"
        return 1
    fi
    
    local error_count=$(wc -l < "$ERROR_FILE")
    log_info "Found $error_count build errors"
    return 0
}

generate_fix() {
    log_info "Generating AI-powered fix..."
    
    if ! command -v claude &> /dev/null; then
        log_warning "Claude CLI not available, skipping AI fix"
        return 1
    fi
    
    # Call our Claude patch generator
    "$(dirname "${BASH_SOURCE[0]}")/claude-patch-generator.sh" "$ERROR_FILE" > "$PATCH_FILE"
    
    if [[ ! -s "$PATCH_FILE" ]]; then
        log_warning "No patch generated"
        return 1
    fi
    
    log_success "Patch generated successfully"
    return 0
}

apply_fix() {
    log_info "Applying fix..."
    
    if [[ ! -f "$PATCH_FILE" ]]; then
        log_error "No patch file found"
        return 1
    fi
    
    # Call our safe patch application script
    "$(dirname "${BASH_SOURCE[0]}")/safe-patch-apply.sh" "$PATCH_FILE"
    return $?
}

main() {
    # Load configuration first
    load_config
    
    log_info "Starting iOS Auto Build & Fix System"
    log_info "Project: $PROJECT_DIR"
    log_info "Xcode Project: $XCODE_PROJECT"
    log_info "Scheme: $SCHEME"
    log_info "Max attempts: $MAX_ATTEMPTS"
    
    # Check prerequisites
    check_prerequisites
    local has_claude=$?
    
    # Main build-fix loop
    while [[ $CURRENT_ATTEMPT -lt $MAX_ATTEMPTS ]]; do
        log_info "=== Build Attempt $((CURRENT_ATTEMPT + 1)) ==="
        
        # Try to build
        if build_project; then
            log_success "Build successful! 🎉"
            exit 0
        fi
        
        # Extract errors from build log
        if ! extract_errors; then
            log_error "Failed to extract errors or no errors found"
            break
        fi
        
        # Show errors to user
        log_warning "Build errors found:"
        cat "$ERROR_FILE" | head -10  # Show first 10 errors
        
        # If Claude CLI is available, try to generate and apply fix
        if [[ $has_claude -eq 0 ]]; then
            if generate_fix && apply_fix; then
                log_success "Fix applied, retrying build..."
                ((CURRENT_ATTEMPT++))
                continue
            else
                log_warning "Failed to generate or apply fix"
            fi
        fi
        
        # Manual intervention required
        log_warning "Manual intervention required."
        log_info "Error details saved to: $ERROR_FILE"
        
        read -p "Fix errors manually and press Enter to retry, or 'q' to quit: " -r response
        if [[ $response == "q" ]]; then
            log_info "Quitting as requested"
            exit 0
        fi
        
        ((CURRENT_ATTEMPT++))
    done
    
    log_error "Maximum attempts ($MAX_ATTEMPTS) reached. Build still failing."
    log_info "Error details: $ERROR_FILE"
    exit 1
}

# --- Script Entry Point ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi