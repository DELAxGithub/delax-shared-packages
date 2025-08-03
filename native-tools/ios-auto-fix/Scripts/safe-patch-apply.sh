#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Safe Patch Application Script
# パッチの安全な適用とロールバック機能
# =============================================================================

PATCH_FILE="${1:-builderror/patch.diff}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${PROJECT_DIR}/.patch-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_TAG="patch_backup_${TIMESTAMP}"

# --- Colors for output ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Cleanup function
cleanup() {
    if [[ -f "/tmp/patch_test.patch" ]]; then
        rm -f "/tmp/patch_test.patch"
    fi
}

trap cleanup EXIT

# Check prerequisites
check_prerequisites() {
    if [[ ! -f "$PATCH_FILE" ]]; then
        log_error "Patch file not found: $PATCH_FILE"
        return 1
    fi
    
    if [[ ! -d "$PROJECT_DIR/.git" ]]; then
        log_error "Not a git repository. Git is required for safe patching."
        return 1
    fi
    
    # Check if we're in a clean git state
    if ! git diff --quiet 2>/dev/null; then
        log_warning "Working directory has uncommitted changes"
        echo "Uncommitted changes found:"
        git status --porcelain
        read -p "Continue anyway? (y/N): " -r response
        if [[ ! $response =~ ^[Yy]$ ]]; then
            log_info "Aborted by user"
            return 1
        fi
    fi
    
    return 0
}

# Create backup
create_backup() {
    log_info "Creating backup..."
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Create a git stash for current state
    if git stash push -m "$BACKUP_TAG" 2>/dev/null; then
        log_success "Git stash created: $BACKUP_TAG"
        echo "$BACKUP_TAG" > "$BACKUP_DIR/latest_stash.txt"
    else
        log_info "No changes to stash"
    fi
    
    # Also create a traditional backup of files that might be affected
    backup_affected_files
}

# Backup files that will be affected by the patch
backup_affected_files() {
    log_info "Backing up affected files..."
    
    local affected_files=()
    
    # Extract file paths from patch
    if grep -E "^\+\+\+ " "$PATCH_FILE" > /dev/null; then
        while read -r line; do
            if [[ $line =~ ^\+\+\+[[:space:]](.+)$ ]]; then
                local file_path="${BASH_REMATCH[1]}"
                # Remove a/ or b/ prefix if present
                file_path="${file_path#a/}"
                file_path="${file_path#b/}"
                affected_files+=("$file_path")
            fi
        done < <(grep -E "^\+\+\+ " "$PATCH_FILE")
    fi
    
    # Backup each affected file
    local backup_subdir="$BACKUP_DIR/$TIMESTAMP"
    mkdir -p "$backup_subdir"
    
    for file in "${affected_files[@]}"; do
        local full_path="$PROJECT_DIR/$file"
        if [[ -f "$full_path" ]]; then
            local backup_path="$backup_subdir/$file"
            mkdir -p "$(dirname "$backup_path")"
            cp "$full_path" "$backup_path"
            log_info "Backed up: $file"
        fi
    done
    
    # Save list of backed up files
    printf "%s\n" "${affected_files[@]}" > "$backup_subdir/affected_files.txt"
}

# Validate patch format
validate_patch() {
    log_info "Validating patch format..."
    
    # Check if it's a valid patch format
    if ! grep -E "^(diff --git|@@|\+\+\+|---)" "$PATCH_FILE" > /dev/null; then
        log_error "Invalid patch format detected"
        return 1
    fi
    
    # Check for suspicious content
    if grep -E "(rm -rf|sudo|eval|\$\()" "$PATCH_FILE" > /dev/null; then
        log_warning "Potentially dangerous commands found in patch"
        cat "$PATCH_FILE"
        read -p "This patch contains potentially dangerous commands. Continue? (y/N): " -r response
        if [[ ! $response =~ ^[Yy]$ ]]; then
            log_info "Aborted by user"
            return 1
        fi
    fi
    
    return 0
}

# Test patch application (dry run)
test_patch() {
    log_info "Testing patch application (dry run)..."
    
    cd "$PROJECT_DIR"
    
    # Test with --dry-run flag
    if git apply --check "$PATCH_FILE" 2>/dev/null; then
        log_success "Patch can be applied cleanly"
        return 0
    else
        log_warning "Patch may not apply cleanly"
        
        # Try with more options
        if git apply --ignore-space-change --ignore-whitespace --check "$PATCH_FILE" 2>/dev/null; then
            log_warning "Patch can be applied with whitespace adjustments"
            return 0
        else
            log_error "Patch cannot be applied"
            git apply --check "$PATCH_FILE" 2>&1 | head -10
            return 1
        fi
    fi
}

# Apply patch
apply_patch() {
    log_info "Applying patch..."
    
    cd "$PROJECT_DIR"
    
    # Try normal application first
    if git apply "$PATCH_FILE" 2>/dev/null; then
        log_success "Patch applied successfully"
        return 0
    fi
    
    # Try with whitespace options
    log_warning "Normal application failed, trying with whitespace adjustments..."
    if git apply --ignore-space-change --ignore-whitespace "$PATCH_FILE" 2>/dev/null; then
        log_success "Patch applied with whitespace adjustments"
        return 0
    fi
    
    # Try 3-way merge
    log_warning "Trying 3-way merge..."
    if git apply --3way "$PATCH_FILE" 2>/dev/null; then
        log_success "Patch applied using 3-way merge"
        return 0
    fi
    
    log_error "Failed to apply patch"
    return 1
}

# Verify patch results
verify_patch() {
    log_info "Verifying patch results..."
    
    # Check if files compile (basic syntax check)
    local swift_files=()
    while IFS= read -r -d '' file; do
        swift_files+=("$file")
    done < <(find "$PROJECT_DIR/Myprojects" -name "*.swift" -print0 2>/dev/null)
    
    if [[ ${#swift_files[@]} -gt 0 ]]; then
        log_info "Running basic Swift syntax check..."
        local syntax_errors=0
        
        for file in "${swift_files[@]:0:5}"; do  # Check first 5 files
            if ! swift -frontend -parse "$file" &>/dev/null; then
                log_warning "Syntax error in: $(basename "$file")"
                ((syntax_errors++))
            fi
        done
        
        if [[ $syntax_errors -gt 0 ]]; then
            log_warning "$syntax_errors files have syntax errors"
            return 1
        else
            log_success "Basic syntax check passed"
        fi
    fi
    
    return 0
}

# Rollback function
rollback() {
    log_warning "Rolling back changes..."
    
    cd "$PROJECT_DIR"
    
    # Try to restore from git stash
    if [[ -f "$BACKUP_DIR/latest_stash.txt" ]]; then
        local stash_name
        stash_name=$(cat "$BACKUP_DIR/latest_stash.txt")
        
        # Check if stash exists
        if git stash list | grep -q "$stash_name"; then
            log_info "Restoring from git stash: $stash_name"
            # Reset working directory first
            git reset --hard HEAD
            # Apply stash
            if git stash pop "stash^{/$stash_name}" 2>/dev/null; then
                log_success "Rollback completed using git stash"
                return 0
            fi
        fi
    fi
    
    # Fallback: reset to HEAD
    log_info "Falling back to git reset"
    git reset --hard HEAD
    log_success "Rollback completed using git reset"
}

# Main execution
main() {
    log_info "Starting safe patch application..."
    log_info "Patch file: $PATCH_FILE"
    log_info "Project dir: $PROJECT_DIR"
    
    # Check prerequisites
    if ! check_prerequisites; then
        return 1
    fi
    
    # Show patch preview
    echo "=== PATCH PREVIEW ==="
    head -20 "$PATCH_FILE"
    if [[ $(wc -l < "$PATCH_FILE") -gt 20 ]]; then
        echo "... (truncated, $(wc -l < "$PATCH_FILE") total lines)"
    fi
    echo "===================="
    
    # Validate patch
    if ! validate_patch; then
        return 1
    fi
    
    # Create backup
    create_backup
    
    # Test patch
    if ! test_patch; then
        log_error "Patch validation failed"
        return 1
    fi
    
    # Apply patch
    if apply_patch; then
        # Verify results
        if verify_patch; then
            log_success "Patch applied and verified successfully! 🎉"
            
            # Show what changed
            echo ""
            echo "=== CHANGES SUMMARY ==="
            git diff --stat HEAD~1 2>/dev/null || git diff --stat --cached 2>/dev/null || echo "No git diff available"
            
            return 0
        else
            log_error "Patch verification failed"
            rollback
            return 1
        fi
    else
        log_error "Patch application failed"
        rollback
        return 1
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi