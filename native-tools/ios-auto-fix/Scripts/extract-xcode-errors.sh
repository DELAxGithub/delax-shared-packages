#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Xcode Build Error Extraction Script
# Xcodeビルドログから構造化されたエラー情報を抽出
# =============================================================================

BUILD_LOG="${1:-build.log}"

# --- Colors for output ---
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

# Check if build log exists
if [[ ! -f "$BUILD_LOG" ]]; then
    log_error "Build log file not found: $BUILD_LOG"
    exit 1
fi

# Extract and format Swift compilation errors
extract_swift_errors() {
    # Swift compiler errors pattern: /path/file.swift:line:column: error: message
    grep -E "^[^[:space:]]+\.swift:[0-9]+:[0-9]+: error:" "$BUILD_LOG" | while IFS= read -r line; do
        # Parse the error line
        if [[ $line =~ ^([^:]+):([0-9]+):([0-9]+):[[:space:]]*error:[[:space:]]*(.+)$ ]]; then
            local file_path="${BASH_REMATCH[1]}"
            local line_number="${BASH_REMATCH[2]}"
            local column="${BASH_REMATCH[3]}"
            local error_message="${BASH_REMATCH[4]}"
            
            # Get just the filename for cleaner output
            local filename=$(basename "$file_path")
            
            echo "SWIFT_ERROR|$filename:$line_number:$column|$error_message"
            
            # Look ahead for additional context lines (notes, suggestions)
            local context_lines=$(grep -A 3 -F "$line" "$BUILD_LOG" | tail -n +2 | grep -E "^[[:space:]]*(note:|help:|suggestion:)" || true)
            if [[ -n "$context_lines" ]]; then
                echo "CONTEXT|$context_lines"
            fi
        fi
    done
}

# Extract SwiftUI-specific errors
extract_swiftui_errors() {
    # SwiftUI specific patterns
    grep -E "(SwiftUI|@State|@Binding|@ObservedObject|@EnvironmentObject)" "$BUILD_LOG" | \
    grep -E "error:" | while IFS= read -r line; do
        if [[ $line =~ ^([^:]+):([0-9]+):([0-9]+):[[:space:]]*error:[[:space:]]*(.+)$ ]]; then
            local file_path="${BASH_REMATCH[1]}"
            local line_number="${BASH_REMATCH[2]}"
            local column="${BASH_REMATCH[3]}"
            local error_message="${BASH_REMATCH[4]}"
            local filename=$(basename "$file_path")
            
            echo "SWIFTUI_ERROR|$filename:$line_number:$column|$error_message"
        fi
    done
}

# Extract build system errors
extract_build_errors() {
    # Build system errors (linking, resources, etc.)
    grep -E "(ld:|clang:|error: linker command failed|error: build input file cannot be found)" "$BUILD_LOG" | \
    while IFS= read -r line; do
        # Clean up the line
        local clean_line=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        echo "BUILD_ERROR||$clean_line"
    done
}

# Extract dependency/import errors
extract_import_errors() {
    grep -E "(No such module|could not build module|failed to import)" "$BUILD_LOG" | \
    while IFS= read -r line; do
        if [[ $line =~ ^([^:]+):([0-9]+):([0-9]+):[[:space:]]*error:[[:space:]]*(.+)$ ]]; then
            local file_path="${BASH_REMATCH[1]}"
            local line_number="${BASH_REMATCH[2]}"
            local column="${BASH_REMATCH[3]}"
            local error_message="${BASH_REMATCH[4]}"
            local filename=$(basename "$file_path")
            
            echo "IMPORT_ERROR|$filename:$line_number:$column|$error_message"
        fi
    done
}

# Extract code signing errors
extract_codesign_errors() {
    grep -E "(Code Sign error|Provisioning profile|codesign failed)" "$BUILD_LOG" | \
    while IFS= read -r line; do
        local clean_line=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        echo "CODESIGN_ERROR||$clean_line"
    done
}

# Extract warnings that might become errors
extract_critical_warnings() {
    grep -E "warning:.*will be an error" "$BUILD_LOG" | \
    while IFS= read -r line; do
        if [[ $line =~ ^([^:]+):([0-9]+):([0-9]+):[[:space:]]*warning:[[:space:]]*(.+)$ ]]; then
            local file_path="${BASH_REMATCH[1]}"
            local line_number="${BASH_REMATCH[2]}"
            local column="${BASH_REMATCH[3]}"
            local warning_message="${BASH_REMATCH[4]}"
            local filename=$(basename "$file_path")
            
            echo "CRITICAL_WARNING|$filename:$line_number:$column|$warning_message"
        fi
    done
}

# Generate summary for Claude Code
generate_summary() {
    local total_errors=0
    local swift_errors=0
    local swiftui_errors=0
    local build_errors=0
    local import_errors=0
    local codesign_errors=0
    local warnings=0
    
    # Count different types of errors
    if [[ -f /tmp/extracted_errors.txt ]]; then
        total_errors=$(wc -l < /tmp/extracted_errors.txt)
        swift_errors=$(grep -c "^SWIFT_ERROR" /tmp/extracted_errors.txt || true)
        swiftui_errors=$(grep -c "^SWIFTUI_ERROR" /tmp/extracted_errors.txt || true)
        build_errors=$(grep -c "^BUILD_ERROR" /tmp/extracted_errors.txt || true)
        import_errors=$(grep -c "^IMPORT_ERROR" /tmp/extracted_errors.txt || true)
        codesign_errors=$(grep -c "^CODESIGN_ERROR" /tmp/extracted_errors.txt || true)
        warnings=$(grep -c "^CRITICAL_WARNING" /tmp/extracted_errors.txt || true)
    fi
    
    echo "=== BUILD ERROR SUMMARY ==="
    echo "Total Issues: $total_errors"
    echo "Swift Errors: $swift_errors"
    echo "SwiftUI Errors: $swiftui_errors"
    echo "Build System Errors: $build_errors"
    echo "Import Errors: $import_errors"
    echo "Code Signing Errors: $codesign_errors"
    echo "Critical Warnings: $warnings"
    echo ""
    echo "=== DETAILED ERRORS ==="
}

# Main execution
main() {
    # Create temporary file for collection
    local temp_file="/tmp/extracted_errors.txt"
    > "$temp_file"
    
    # Extract all types of errors
    extract_swift_errors >> "$temp_file"
    extract_swiftui_errors >> "$temp_file"
    extract_build_errors >> "$temp_file"
    extract_import_errors >> "$temp_file"
    extract_codesign_errors >> "$temp_file"
    extract_critical_warnings >> "$temp_file"
    
    # Generate output
    generate_summary
    
    # Output structured errors
    if [[ -s "$temp_file" ]]; then
        cat "$temp_file"
    else
        echo "No errors found in build log."
        log_warning "This might indicate a successful build or issues with error detection."
    fi
    
    # Cleanup
    rm -f "$temp_file"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi