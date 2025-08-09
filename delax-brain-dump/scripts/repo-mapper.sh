#!/bin/bash

# DELAX Repository Mapper
# ファイル名からリポジトリ名を抽出し、実際のリポジトリURLにマッピング

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAIN_DUMP_DIR="$(dirname "$SCRIPT_DIR")"
REPOS_CONFIG="$BRAIN_DUMP_DIR/repos-config.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Extract repository name from filename
extract_repo_from_filename() {
    local filename="$1"
    
    # Remove .md extension
    local basename="${filename%.md}"
    
    # Extract everything before the first hyphen
    local repo_hint="${basename%%-*}"
    
    echo "$repo_hint"
}

# Find repository URL by name hint
find_repository_url() {
    local repo_hint="$1"
    
    if [ ! -f "$REPOS_CONFIG" ]; then
        echo ""
        return 1
    fi
    
    # Try exact name match first
    local exact_match=$(jq -r --arg hint "$repo_hint" '
        .categories[] | 
        .[] | 
        select(.name == $hint) | 
        .repo_url' "$REPOS_CONFIG" 2>/dev/null | head -n 1)
    
    if [ -n "$exact_match" ] && [ "$exact_match" != "null" ]; then
        echo "$exact_match"
        return 0
    fi
    
    # Try case-insensitive exact match
    local case_insensitive_match=$(jq -r --arg hint "$repo_hint" '
        .categories[] | 
        .[] | 
        select(.name | ascii_downcase == ($hint | ascii_downcase)) | 
        .repo_url' "$REPOS_CONFIG" 2>/dev/null | head -n 1)
    
    if [ -n "$case_insensitive_match" ] && [ "$case_insensitive_match" != "null" ]; then
        echo "$case_insensitive_match"
        return 0
    fi
    
    # Try partial match (hint contained in name)
    local partial_match=$(jq -r --arg hint "$repo_hint" '
        .categories[] | 
        .[] | 
        select(.name | ascii_downcase | contains($hint | ascii_downcase)) | 
        .repo_url' "$REPOS_CONFIG" 2>/dev/null | head -n 1)
    
    if [ -n "$partial_match" ] && [ "$partial_match" != "null" ]; then
        echo "$partial_match"
        return 0
    fi
    
    # Try reverse partial match (name contained in hint)
    local reverse_partial_match=$(jq -r --arg hint "$repo_hint" '
        .categories[] | 
        .[] | 
        select(($hint | ascii_downcase) | contains(.name | ascii_downcase)) | 
        .repo_url' "$REPOS_CONFIG" 2>/dev/null | head -n 1)
    
    if [ -n "$reverse_partial_match" ] && [ "$reverse_partial_match" != "null" ]; then
        echo "$reverse_partial_match"
        return 0
    fi
    
    # No match found
    echo ""
    return 1
}

# Get repository name from URL
get_repo_name_from_url() {
    local repo_url="$1"
    echo "${repo_url##*/}"
}

# Find suggestions for typos
suggest_repositories() {
    local repo_hint="$1"
    local limit="${2:-5}"
    
    if [ ! -f "$REPOS_CONFIG" ]; then
        return 1
    fi
    
    # Get all repository names with similarity scoring
    jq -r --arg hint "$repo_hint" '
        .categories[] | 
        .[] | 
        .name' "$REPOS_CONFIG" 2>/dev/null | \
    while IFS= read -r repo_name; do
        if [ -n "$repo_name" ]; then
            # Simple similarity: check common characters
            local score=0
            local hint_lower=$(echo "$repo_hint" | tr '[:upper:]' '[:lower:]')
            local name_lower=$(echo "$repo_name" | tr '[:upper:]' '[:lower:]')
            
            # Check if hint is substring of name or vice versa
            if echo "$name_lower" | grep -q "$hint_lower"; then
                score=90
            elif echo "$hint_lower" | grep -q "$name_lower"; then
                score=80
            elif [ ${#hint_lower} -gt 2 ]; then
                # Check first few characters match
                local hint_prefix=${hint_lower:0:3}
                local name_prefix=${name_lower:0:3}
                if [ "$hint_prefix" = "$name_prefix" ]; then
                    score=70
                fi
            fi
            
            if [ $score -gt 0 ]; then
                echo "$score:$repo_name"
            fi
        fi
    done | sort -rn | head -n "$limit" | cut -d':' -f2-
}

# List all available repositories
list_all_repositories() {
    if [ ! -f "$REPOS_CONFIG" ]; then
        echo "No repository configuration found."
        return 1
    fi
    
    echo -e "${BLUE}📋 Available repositories:${NC}"
    echo ""
    
    jq -r '.categories | to_entries[] | 
        "\u001b[33m\(.key)\u001b[0m:" as $category |
        .value[] | 
        "  \u001b[32m\(.name)\u001b[0m (\(.language)) - \(.description)"' \
        "$REPOS_CONFIG" 2>/dev/null | head -20
    
    local total_count=$(jq -r '[.categories[] | .[]] | length' "$REPOS_CONFIG" 2>/dev/null)
    if [ "$total_count" -gt 20 ]; then
        echo "  ... and $((total_count - 20)) more repositories"
    fi
}

# Validate filename format
validate_filename() {
    local filename="$1"
    
    # Check if filename contains hyphen (required for repo extraction)
    if [[ ! "$filename" =~ - ]]; then
        return 1
    fi
    
    # Check if filename ends with .md
    if [[ ! "$filename" =~ \.md$ ]]; then
        return 1
    fi
    
    return 0
}

# Main function
map_filename_to_repo() {
    local filename="$1"
    local verbose="${2:-false}"
    
    if [ -z "$filename" ]; then
        echo "Usage: map_filename_to_repo <filename> [verbose]"
        return 1
    fi
    
    # Validate filename format
    if ! validate_filename "$filename"; then
        if [ "$verbose" = "true" ]; then
            echo -e "${RED}❌ Invalid filename format: $filename${NC}" >&2
            echo -e "${YELLOW}💡 Expected format: {repo-name}-{description}.md${NC}" >&2
        fi
        return 1
    fi
    
    # Extract repository hint
    local repo_hint=$(extract_repo_from_filename "$filename")
    
    if [ "$verbose" = "true" ]; then
        echo -e "${BLUE}🔍 Extracted repository hint: $repo_hint${NC}" >&2
    fi
    
    # Find matching repository
    local repo_url=$(find_repository_url "$repo_hint")
    
    if [ -n "$repo_url" ]; then
        if [ "$verbose" = "true" ]; then
            local repo_name=$(get_repo_name_from_url "$repo_url")
            echo -e "${GREEN}✅ Matched repository: $repo_name${NC}" >&2
            echo -e "${BLUE}🔗 Repository URL: $repo_url${NC}" >&2
        fi
        echo "$repo_url"
        return 0
    else
        if [ "$verbose" = "true" ]; then
            echo -e "${RED}❌ No matching repository found for: $repo_hint${NC}" >&2
            echo -e "${YELLOW}💡 Suggestions:${NC}" >&2
            
            local suggestions=$(suggest_repositories "$repo_hint" 3)
            if [ -n "$suggestions" ]; then
                echo "$suggestions" | while IFS= read -r suggestion; do
                    echo -e "  - ${GREEN}$suggestion${NC}" >&2
                done
            else
                echo -e "  ${GRAY}No similar repositories found${NC}" >&2
            fi
        fi
        return 1
    fi
}

# Command line interface
usage() {
    echo "Usage: $0 <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  map <filename>              - Map filename to repository URL"
    echo "  suggest <hint>              - Suggest repositories for given hint"
    echo "  list                        - List all available repositories"
    echo "  validate <filename>         - Validate filename format"
    echo ""
    echo "Examples:"
    echo "  $0 map myprojects-button-bug.md"
    echo "  $0 suggest myproj"
    echo "  $0 list"
    echo "  $0 validate myprojects-issue.md"
}

# Main command handling
case "${1:-help}" in
    "map")
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Filename required${NC}"
            usage
            exit 1
        fi
        map_filename_to_repo "$2" true
        ;;
    "suggest")
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Repository hint required${NC}"
            usage
            exit 1
        fi
        echo -e "${BLUE}💡 Suggestions for '$2':${NC}"
        suggestions=$(suggest_repositories "$2")
        if [ -n "$suggestions" ]; then
            echo "$suggestions" | while IFS= read -r suggestion; do
                echo -e "  - ${GREEN}$suggestion${NC}"
            done
        else
            echo -e "  ${GRAY}No suggestions found${NC}"
        fi
        ;;
    "list")
        list_all_repositories
        ;;
    "validate")
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Filename required${NC}"
            usage
            exit 1
        fi
        if validate_filename "$2"; then
            repo_hint=$(extract_repo_from_filename "$2")
            echo -e "${GREEN}✅ Valid filename format${NC}"
            echo -e "${BLUE}🔍 Repository hint: $repo_hint${NC}"
        else
            echo -e "${RED}❌ Invalid filename format${NC}"
            echo -e "${YELLOW}💡 Expected format: {repo-name}-{description}.md${NC}"
            exit 1
        fi
        ;;
    "help"|*)
        usage
        ;;
esac