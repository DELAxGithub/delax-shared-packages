#!/bin/bash

# DELAX Issue Classification Script
# Claude CLIを使用してinboxのファイルを適切なプロジェクトに分類

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAIN_DUMP_DIR="$(dirname "$SCRIPT_DIR")"
INBOX_DIR="$BRAIN_DUMP_DIR/inbox"
PROJECTS_DIR="$BRAIN_DUMP_DIR/projects"
REPOS_CONFIG="$BRAIN_DUMP_DIR/repos-config.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧠 DELAX Issue Classifier (Dynamic)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if repository configuration exists
if [ ! -f "$REPOS_CONFIG" ]; then
    echo -e "${YELLOW}⚠️  Repository configuration not found. Running discovery...${NC}"
    "$SCRIPT_DIR/discover-repos.sh"
fi

# Load available categories
if [ -f "$REPOS_CONFIG" ]; then
    categories=$(jq -r '.categories | keys[]' "$REPOS_CONFIG" 2>/dev/null | tr '\n' ' ')
    echo -e "${GREEN}📋 Available categories: $categories${NC}"
else
    echo -e "${RED}❌ Could not load repository configuration${NC}"
    exit 1
fi

# Check if inbox has files
if [ ! -d "$INBOX_DIR" ] || [ -z "$(ls -A "$INBOX_DIR" 2>/dev/null)" ]; then
    echo -e "${YELLOW}⚠️  Inbox is empty. Nothing to classify.${NC}"
    exit 0
fi

# Count files to process
FILE_COUNT=$(find "$INBOX_DIR" -name "*.md" -type f | wc -l | tr -d ' ')
echo -e "${GREEN}📁 Found $FILE_COUNT files to classify${NC}"

# Process each markdown file in inbox
for file in "$INBOX_DIR"/*.md; do
    [ -f "$file" ] || continue
    
    filename=$(basename "$file")
    echo -e "\n${BLUE}🔍 Analyzing: $filename${NC}"
    
    # Read file content
    content=$(cat "$file")
    
    # Get classification from Claude CLI using dynamic categories
    echo -e "${YELLOW}🤖 Asking Claude for classification...${NC}"
    
    # Build dynamic classification prompt
    dynamic_rules=$(jq -r '.classification_rules | to_entries | 
        map("- \(.key): \(.value.keywords | join(", "))") | 
        join("\n")' "$REPOS_CONFIG" 2>/dev/null)
    
    available_categories=$(jq -r '.categories | keys | join(", ")' "$REPOS_CONFIG" 2>/dev/null)
    
    # Use Claude CLI with dynamic prompt
    classification=$(printf "Classify this DELAX project issue into one of the available categories.\n\nAvailable categories: %s\n\nClassification Rules:\n%s\n\nIssue content:\n%s\n\nRespond with ONLY the category name (no explanation):" "$available_categories" "$dynamic_rules" "$content" | claude 2>/dev/null | tail -n 1 | tr -d '\n' | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    
    # Validate classification result against available categories
    valid_categories=$(jq -r '.categories | keys[]' "$REPOS_CONFIG" 2>/dev/null)
    is_valid=false
    
    for category in $valid_categories; do
        if [ "$classification" = "$category" ]; then
            is_valid=true
            break
        fi
    done
    
    if [ "$is_valid" = true ]; then
        echo -e "${GREEN}✅ Classified as: $classification${NC}"
    else
        echo -e "${RED}❌ Invalid classification result: '$classification'${NC}"
        # Find default fallback category (prefer shared, then first available)
        fallback=$(echo "$valid_categories" | grep -E "shared|app" | head -n 1)
        if [ -z "$fallback" ]; then
            fallback=$(echo "$valid_categories" | head -n 1)
        fi
        echo -e "${YELLOW}📦 Defaulting to: $fallback${NC}"
        classification="$fallback"
    fi
    
    # Move file to appropriate project directory
    target_dir="$PROJECTS_DIR/$classification"
    mkdir -p "$target_dir"
    
    # Add timestamp and classification header to file
    temp_file=$(mktemp)
    echo "# Issue: $filename" > "$temp_file"
    echo "**Project**: $classification" >> "$temp_file"
    echo "**Classified**: $(date '+%Y-%m-%d %H:%M:%S')" >> "$temp_file"
    echo "" >> "$temp_file"
    cat "$file" >> "$temp_file"
    
    mv "$temp_file" "$target_dir/$filename"
    rm "$file"
    
    echo -e "${GREEN}📝 Moved to: projects/$classification/$filename${NC}"
done

echo -e "\n${GREEN}🎉 Classification complete!${NC}"
echo -e "${BLUE}📊 Summary:${NC}"
for project_dir in "$PROJECTS_DIR"/*/; do
    if [ -d "$project_dir" ]; then
        project=$(basename "$project_dir")
        count=$(find "$project_dir" -name "*.md" -type f | wc -l | tr -d ' ')
        if [ "$count" -gt 0 ]; then
            echo -e "  ${GREEN}$project${NC}: $count issues"
        fi
    fi
done