#!/bin/bash

# DELAX GitHub Issue Creator
# 分類済みのローカルファイルをGitHub issueとして作成

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAIN_DUMP_DIR="$(dirname "$SCRIPT_DIR")"
PROJECTS_DIR="$BRAIN_DUMP_DIR/projects"
ARCHIVE_DIR="$BRAIN_DUMP_DIR/archive"
REPOS_CONFIG="$BRAIN_DUMP_DIR/repos-config.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Dynamic repository mapping function
get_repo() {
    local category="$1"
    
    # Check if repos config exists
    if [ ! -f "$REPOS_CONFIG" ]; then
        echo ""
        return
    fi
    
    # Get the first (most recently updated) repository from the category
    local repo=$(jq -r --arg cat "$category" \
        '.categories[$cat] // [] | 
         if length > 0 then .[0].repo_url else "" end' \
        "$REPOS_CONFIG" 2>/dev/null)
    
    echo "$repo"
}

# Get all repositories in a category
get_category_repos() {
    local category="$1"
    
    if [ ! -f "$REPOS_CONFIG" ]; then
        return
    fi
    
    jq -r --arg cat "$category" \
        '.categories[$cat] // [] | 
         map(.name + " (" + .language + ")") | 
         join(", ")' \
        "$REPOS_CONFIG" 2>/dev/null
}

usage() {
    echo "Usage: $0 [OPTIONS] <file_path|project_name>"
    echo ""
    echo "Options:"
    echo "  -a, --all          Push all classified issues to GitHub"
    echo "  -p, --project      Push all issues from specific project"
    echo "  -f, --file         Push specific file"
    echo "  -d, --dry-run      Show what would be done without actually creating issues"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -f myprojects/task-button-bug.md"
    echo "  $0 -p myprojects"
    echo "  $0 -a"
    echo "  $0 --dry-run -a"
}

create_github_issue() {
    local file_path="$1"
    local dry_run="$2"
    
    if [ ! -f "$file_path" ]; then
        echo -e "${RED}❌ File not found: $file_path${NC}"
        return 1
    fi
    
    # Extract project from file path
    local relative_path="${file_path#$PROJECTS_DIR/}"
    local project=$(echo "$relative_path" | cut -d'/' -f1)
    local filename=$(basename "$file_path")
    
    # Get repository
    local repo=$(get_repo "$project")
    if [ -z "$repo" ]; then
        echo -e "${RED}❌ Unknown project: $project${NC}"
        return 1
    fi
    
    # Read file content
    local content=$(cat "$file_path")
    
    # Extract title from filename (remove .md extension and replace hyphens with spaces)
    local title=$(basename "$filename" .md | tr '-' ' ' | sed 's/\b\w/\U&/g')
    
    # Create issue body with metadata
    local issue_body="$content

---
**Source**: DELAX Brain Dump System
**Original File**: \`$filename\`
**Classified**: $(date '+%Y-%m-%d %H:%M:%S')"
    
    if [ "$dry_run" = "true" ]; then
        echo -e "${YELLOW}🔍 DRY RUN - Would create issue:${NC}"
        echo -e "  ${BLUE}Repository${NC}: $repo"
        echo -e "  ${BLUE}Title${NC}: $title"
        echo -e "  ${BLUE}File${NC}: $relative_path"
        return 0
    fi
    
    echo -e "${BLUE}🚀 Creating GitHub issue...${NC}"
    echo -e "  ${BLUE}Repository${NC}: $repo"
    echo -e "  ${BLUE}Title${NC}: $title"
    
    # Create GitHub issue using gh CLI
    if gh issue create --repo "$repo" --title "$title" --body "$issue_body"; then
        echo -e "${GREEN}✅ Issue created successfully${NC}"
        
        # Move to archive
        mkdir -p "$ARCHIVE_DIR/$(dirname "$relative_path")"
        mv "$file_path" "$ARCHIVE_DIR/$relative_path"
        echo -e "${GREEN}📦 Moved to archive: $relative_path${NC}"
        
        return 0
    else
        echo -e "${RED}❌ Failed to create issue${NC}"
        return 1
    fi
}

# Check if gh CLI is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
    echo "Install with: brew install gh"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI is not authenticated${NC}"
    echo "Run: gh auth login"
    exit 1
fi

echo -e "${BLUE}🚀 DELAX GitHub Issue Creator (Dynamic)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check repository configuration
if [ ! -f "$REPOS_CONFIG" ]; then
    echo -e "${YELLOW}⚠️  Repository configuration not found. Running discovery...${NC}"
    "$SCRIPT_DIR/discover-repos.sh"
fi

# Show available categories
if [ -f "$REPOS_CONFIG" ]; then
    echo -e "${GREEN}📋 Available categories:${NC}"
    jq -r '.categories | to_entries[] | 
        "  \u001b[32m\(.key)\u001b[0m: \(.value | length) repositories" +
        if (.value | length > 0) then " (primary: \(.value[0].name))" else "" end' \
        "$REPOS_CONFIG" 2>/dev/null
    echo ""
fi

# Parse arguments
DRY_RUN=false
ACTION=""
TARGET=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            ACTION="all"
            shift
            ;;
        -p|--project)
            ACTION="project"
            TARGET="$2"
            shift 2
            ;;
        -f|--file)
            ACTION="file"
            TARGET="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [ -z "$ACTION" ]; then
                # Default to file if path provided
                if [[ "$1" == *"/"* ]] || [[ "$1" == *".md" ]]; then
                    ACTION="file"
                    TARGET="$1"
                else
                    ACTION="project"
                    TARGET="$1"
                fi
            fi
            shift
            ;;
    esac
done

# Execute based on action
case "$ACTION" in
    "all")
        echo -e "${GREEN}📁 Processing all classified issues${NC}"
        success_count=0
        total_count=0
        
        for project_dir in "$PROJECTS_DIR"/*/; do
            if [ -d "$project_dir" ]; then
                for file in "$project_dir"/*.md; do
                    [ -f "$file" ] || continue
                    total_count=$((total_count + 1))
                    
                    if create_github_issue "$file" "$DRY_RUN"; then
                        success_count=$((success_count + 1))
                    fi
                    echo ""
                done
            fi
        done
        
        echo -e "${GREEN}🎉 Completed: $success_count/$total_count issues processed${NC}"
        ;;
        
    "project")
        if [ -z "$TARGET" ]; then
            echo -e "${RED}❌ Project name required${NC}"
            usage
            exit 1
        fi
        
        project_path="$PROJECTS_DIR/$TARGET"
        if [ ! -d "$project_path" ]; then
            echo -e "${RED}❌ Project directory not found: $TARGET${NC}"
            echo -e "${BLUE}Available categories:${NC}"
            if [ -f "$REPOS_CONFIG" ]; then
                jq -r '.categories | keys[]' "$REPOS_CONFIG" 2>/dev/null | sed 's/^/  /'
            else
                ls -1 "$PROJECTS_DIR" 2>/dev/null | sed 's/^/  /'
            fi
            exit 1
        fi
        
        echo -e "${GREEN}📁 Processing project: $TARGET${NC}"
        success_count=0
        total_count=0
        
        for file in "$project_path"/*.md; do
            [ -f "$file" ] || continue
            total_count=$((total_count + 1))
            
            if create_github_issue "$file" "$DRY_RUN"; then
                success_count=$((success_count + 1))
            fi
            echo ""
        done
        
        echo -e "${GREEN}🎉 Completed: $success_count/$total_count issues processed for $TARGET${NC}"
        ;;
        
    "file")
        if [ -z "$TARGET" ]; then
            echo -e "${RED}❌ File path required${NC}"
            usage
            exit 1
        fi
        
        # Handle relative paths
        if [[ "$TARGET" != /* ]]; then
            TARGET="$PROJECTS_DIR/$TARGET"
        fi
        
        create_github_issue "$TARGET" "$DRY_RUN"
        ;;
        
    *)
        echo -e "${RED}❌ No action specified${NC}"
        usage
        exit 1
        ;;
esac