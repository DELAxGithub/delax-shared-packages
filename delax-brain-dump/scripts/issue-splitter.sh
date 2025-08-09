#!/bin/bash

# DELAX Issue Splitter
# 1つのファイルから複数のissueを検出・分割する

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAIN_DUMP_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Detect multiple issues in content
detect_multiple_issues() {
    local file_path="$1"
    
    if [ ! -f "$file_path" ]; then
        return 1
    fi
    
    local content=$(cat "$file_path")
    
    # Check for patterns that indicate multiple issues
    local patterns_found=0
    
    # Pattern 1: Numbered lists (1. 2. 3.)
    if echo "$content" | grep -q "^[[:space:]]*[0-9][0-9]*\.[[:space:]]"; then
        patterns_found=$((patterns_found + 1))
    fi
    
    # Pattern 2: Headers (# ## ###)
    if echo "$content" | grep -q "^[[:space:]]*#[[:space:]]"; then
        patterns_found=$((patterns_found + 1))
    fi
    
    # Pattern 3: Dividers (--- ***)
    if echo "$content" | grep -q "^[[:space:]]*\(-\{3,\}\|\*\{3,\}\)[[:space:]]*$"; then
        patterns_found=$((patterns_found + 1))
    fi
    
    # Pattern 4: Issue keywords
    if echo "$content" | grep -qi "問題[[:space:]]*[0-9]\|課題[[:space:]]*[0-9]\|バグ[[:space:]]*[0-9]\|issue[[:space:]]*[0-9]"; then
        patterns_found=$((patterns_found + 1))
    fi
    
    # Return 0 if multiple issue patterns detected
    if [ $patterns_found -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# Split content into multiple issues
split_issues() {
    local file_path="$1"
    local output_dir="$2"
    local base_filename="$3"
    
    if [ ! -f "$file_path" ]; then
        log "❌ File not found: $file_path"
        return 1
    fi
    
    mkdir -p "$output_dir"
    
    local content=$(cat "$file_path")
    local temp_dir=$(mktemp -d)
    
    # Method 1: Split by numbered lists
    if echo "$content" | grep -q "^[[:space:]]*[0-9][0-9]*\.[[:space:]]"; then
        split_by_numbered_list "$file_path" "$temp_dir" "$base_filename"
    # Method 2: Split by headers
    elif echo "$content" | grep -q "^[[:space:]]*#[[:space:]]"; then
        split_by_headers "$file_path" "$temp_dir" "$base_filename"
    # Method 3: Split by dividers
    elif echo "$content" | grep -q "^[[:space:]]*\(-\{3,\}\|\*\{3,\}\)[[:space:]]*$"; then
        split_by_dividers "$file_path" "$temp_dir" "$base_filename"
    # Method 4: Split by issue keywords
    elif echo "$content" | grep -qi "問題[[:space:]]*[0-9]\|課題[[:space:]]*[0-9]\|バグ[[:space:]]*[0-9]"; then
        split_by_keywords "$file_path" "$temp_dir" "$base_filename"
    else
        log "⚠️  No clear splitting pattern found, treating as single issue"
        cp "$file_path" "$output_dir/$base_filename"
        echo 1
        return 0
    fi
    
    # Move split files to output directory
    local count=0
    for split_file in "$temp_dir"/*.md; do
        if [ -f "$split_file" ]; then
            count=$((count + 1))
            local split_filename=$(basename "$split_file")
            mv "$split_file" "$output_dir/$split_filename"
            log "📄 Created split issue: $split_filename"
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
    
    echo $count
}

# Split by numbered lists (1. 2. 3.)
split_by_numbered_list() {
    local file_path="$1"
    local output_dir="$2"
    local base_filename="$3"
    
    local base_name="${base_filename%.md}"
    local content=$(cat "$file_path")
    local current_issue=""
    local issue_count=0
    
    # Extract header (everything before first numbered item)
    local header=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*[0-9][0-9]*\.[[:space:]] ]]; then
            break
        fi
        header="$header$line"$'\n'
    done <<< "$content"
    
    # Split content by numbered items
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*[0-9][0-9]*\.[[:space:]] ]]; then
            # Save previous issue if exists
            if [ -n "$current_issue" ]; then
                echo -e "$header$current_issue" > "$output_dir/${base_name}-issue-${issue_count}.md"
            fi
            
            # Start new issue
            issue_count=$((issue_count + 1))
            current_issue="$line"$'\n'
        else
            # Continue current issue
            if [ -n "$current_issue" ]; then
                current_issue="$current_issue$line"$'\n'
            fi
        fi
    done <<< "$content"
    
    # Save last issue
    if [ -n "$current_issue" ]; then
        echo -e "$header$current_issue" > "$output_dir/${base_name}-issue-${issue_count}.md"
    fi
}

# Split by headers (# ## ###)
split_by_headers() {
    local file_path="$1"
    local output_dir="$2" 
    local base_filename="$3"
    
    local base_name="${base_filename%.md}"
    local content=$(cat "$file_path")
    local current_issue=""
    local issue_count=0
    local header=""
    local in_issue=false
    
    # Extract main header (first line or title before any ## headers)
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*##[[:space:]] ]]; then
            break
        fi
        header="$header$line"$'\n'
    done <<< "$content"
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*##[[:space:]] ]]; then
            # Save previous issue if exists
            if [ -n "$current_issue" ] && [ "$in_issue" = "true" ]; then
                issue_count=$((issue_count + 1))
                echo -e "$header$current_issue" > "$output_dir/${base_name}-issue-${issue_count}.md"
            fi
            
            # Start new issue
            current_issue="$line"$'\n'
            in_issue=true
        else
            # Continue current issue or add to header
            if [ "$in_issue" = "true" ]; then
                current_issue="$current_issue$line"$'\n'
            fi
        fi
    done <<< "$content"
    
    # Save last issue
    if [ -n "$current_issue" ] && [ "$in_issue" = "true" ]; then
        issue_count=$((issue_count + 1))
        echo -e "$header$current_issue" > "$output_dir/${base_name}-issue-${issue_count}.md"
    fi
}

# Split by dividers (--- ***)
split_by_dividers() {
    local file_path="$1"
    local output_dir="$2"
    local base_filename="$3"
    
    local base_name="${base_filename%.md}"
    local content=$(cat "$file_path")
    local current_issue=""
    local issue_count=0
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*(-{3,}|\*{3,})[[:space:]]*$ ]]; then
            # Save previous issue if exists
            if [ -n "$current_issue" ]; then
                issue_count=$((issue_count + 1))
                echo -e "$current_issue" > "$output_dir/${base_name}-issue-${issue_count}.md"
            fi
            
            # Start new issue
            current_issue=""
        else
            # Continue current issue
            current_issue="$current_issue$line"$'\n'
        fi
    done <<< "$content"
    
    # Save last issue
    if [ -n "$current_issue" ]; then
        issue_count=$((issue_count + 1))
        echo -e "$current_issue" > "$output_dir/${base_name}-issue-${issue_count}.md"
    fi
}

# Split by issue keywords (問題1, 課題2, etc.)
split_by_keywords() {
    local file_path="$1"
    local output_dir="$2"
    local base_filename="$3"
    
    local base_name="${base_filename%.md}"
    local content=$(cat "$file_path")
    local current_issue=""
    local issue_count=0
    
    while IFS= read -r line; do
        if echo "$line" | grep -qi "問題[[:space:]]*[0-9]\|課題[[:space:]]*[0-9]\|バグ[[:space:]]*[0-9]\|issue[[:space:]]*[0-9]"; then
            # Save previous issue if exists
            if [ -n "$current_issue" ]; then
                issue_count=$((issue_count + 1))
                echo -e "$current_issue" > "$output_dir/${base_name}-issue-${issue_count}.md"
            fi
            
            # Start new issue
            current_issue="$line"$'\n'
        else
            # Continue current issue
            current_issue="$current_issue$line"$'\n'
        fi
    done <<< "$content"
    
    # Save last issue
    if [ -n "$current_issue" ]; then
        issue_count=$((issue_count + 1))
        echo -e "$current_issue" > "$output_dir/${base_name}-issue-${issue_count}.md"
    fi
}

# Generate related issue links
generate_issue_links() {
    local output_dir="$1"
    local base_name="$2"
    local issue_urls="$3"
    
    # Add related issues section to each split file
    for split_file in "$output_dir"/${base_name}-issue-*.md; do
        if [ -f "$split_file" ]; then
            echo "" >> "$split_file"
            echo "---" >> "$split_file"
            echo "**関連Issue**: $issue_urls" >> "$split_file"
            echo "**分割元**: ${base_name}.md" >> "$split_file"
        fi
    done
}

# Create GitHub issues from split files
create_github_issues() {
    local repo_url="$1"
    local output_dir="$2"
    local base_name="$3"
    local dry_run="${4:-false}"
    
    local issue_urls=""
    local issue_count=0
    
    # Create issues for each split file
    for split_file in "$output_dir"/${base_name}-issue-*.md; do
        if [ -f "$split_file" ]; then
            issue_count=$((issue_count + 1))
            local issue_title=$(generate_issue_title "$split_file" $issue_count)
            local issue_body=$(cat "$split_file")
            
            if [ "$dry_run" = "true" ]; then
                log "🧪 DRY RUN - Would create issue: $issue_title"
                log "   Repository: $repo_url"
                local mock_url="https://github.com/$repo_url/issues/$((100 + issue_count))"
                issue_urls="$issue_urls #$((100 + issue_count))"
            else
                log "📤 Creating GitHub issue: $issue_title"
                local issue_url=$(gh issue create --repo "$repo_url" --title "$issue_title" --body "$issue_body")
                if [ $? -eq 0 ]; then
                    log "✅ Issue created: $issue_url"
                    local issue_number=$(echo "$issue_url" | grep -o '[0-9]*$')
                    issue_urls="$issue_urls #$issue_number"
                else
                    log "❌ Failed to create issue: $issue_title"
                fi
            fi
        fi
    done
    
    # Update all split files with related issue links
    if [ -n "$issue_urls" ]; then
        generate_issue_links "$output_dir" "$base_name" "$issue_urls"
    fi
    
    echo $issue_count
}

# Generate title from issue content
generate_issue_title() {
    local file_path="$1"
    local issue_number="$2"
    
    # Extract first meaningful line as title
    local title=""
    while IFS= read -r line; do
        # Skip empty lines and markdown headers
        if [ -n "$line" ] && [[ ! "$line" =~ ^[[:space:]]*$ ]] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
            title="$line"
            break
        elif [[ "$line" =~ ^[[:space:]]*#[[:space:]](.+)$ ]]; then
            title="${BASH_REMATCH[1]}"
            break
        fi
    done < "$file_path"
    
    # Clean up title
    title=$(echo "$title" | sed 's/^[[:space:]]*[0-9][0-9]*\.[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    # Limit length
    if [ ${#title} -gt 50 ]; then
        title="${title:0:47}..."
    fi
    
    # Add issue number if title is empty
    if [ -z "$title" ]; then
        title="Issue $issue_number"
    fi
    
    echo "$title"
}

# Main function
main() {
    local command="$1"
    shift
    
    case "$command" in
        "detect")
            if [ $# -lt 1 ]; then
                echo "Usage: $0 detect <file_path>"
                exit 1
            fi
            
            if detect_multiple_issues "$1"; then
                echo -e "${GREEN}✅ Multiple issues detected in: $(basename "$1")${NC}"
                exit 0
            else
                echo -e "${BLUE}ℹ️  Single issue detected in: $(basename "$1")${NC}"
                exit 1
            fi
            ;;
            
        "split")
            if [ $# -lt 3 ]; then
                echo "Usage: $0 split <file_path> <output_dir> <base_filename>"
                exit 1
            fi
            
            local count=$(split_issues "$1" "$2" "$3")
            echo -e "${GREEN}✅ Split into $count issues${NC}"
            ;;
            
        "create")
            if [ $# -lt 4 ]; then
                echo "Usage: $0 create <repo_url> <output_dir> <base_name> [dry_run]"
                exit 1
            fi
            
            local dry_run="${4:-false}"
            local count=$(create_github_issues "$1" "$2" "$3" "$dry_run")
            echo -e "${GREEN}✅ Created $count GitHub issues${NC}"
            ;;
            
        *)
            echo "Usage: $0 {detect|split|create} [arguments]"
            echo ""
            echo "Commands:"
            echo "  detect <file>                    - Detect if file contains multiple issues"
            echo "  split <file> <output_dir> <base> - Split file into multiple issue files"
            echo "  create <repo> <dir> <base> [dry] - Create GitHub issues from split files"
            exit 1
            ;;
    esac
}

# Execute main function if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi