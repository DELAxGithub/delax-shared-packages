#!/bin/bash

# Quick Brain Dump Script
# 思いついたらすぐに書き殴りファイルを作成

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAIN_DUMP_DIR="$(dirname "$SCRIPT_DIR")"
INBOX_DIR="$BRAIN_DUMP_DIR/inbox"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 [OPTIONS] \"issue description\""
    echo ""
    echo "Options:"
    echo "  -t, --title <title>    Set custom filename/title"
    echo "  -i, --interactive      Interactive mode for multi-line input"
    echo "  -o, --open             Open file in editor after creation"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 \"タスク作成ボタンが反応しない\""
    echo "  $0 -t \"button-bug\" \"タスク作成ボタンが反応しない。タップしても何も起きない。\""
    echo "  $0 -i"
    echo "  $0 -o \"ワークアウト記録がHealthKitに保存されない\""
}

# Generate filename from content
generate_filename() {
    local content="$1"
    local custom_title="$2"
    
    if [ -n "$custom_title" ]; then
        echo "${custom_title}.md"
        return
    fi
    
    # Extract first meaningful words and create filename
    local filename=$(echo "$content" | head -n1 | \
        sed 's/[^ぁ-んァ-ンー一-龠a-zA-Z0-9 ]//g' | \
        tr ' ' '-' | \
        tr '[:upper:]' '[:lower:]' | \
        cut -c1-50 | \
        sed 's/-*$//g')
    
    # Add timestamp if filename is too short or empty
    if [ ${#filename} -lt 5 ]; then
        filename="issue-$(date '+%H%M')"
    fi
    
    echo "${filename}.md"
}

# Ensure inbox directory exists
mkdir -p "$INBOX_DIR"

echo -e "${BLUE}📝 Quick Brain Dump${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Parse arguments
CUSTOM_TITLE=""
INTERACTIVE=false
OPEN_EDITOR=false
CONTENT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--title)
            CUSTOM_TITLE="$2"
            shift 2
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        -o|--open)
            OPEN_EDITOR=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            CONTENT="$1"
            shift
            ;;
    esac
done

# Interactive mode
if [ "$INTERACTIVE" = true ]; then
    echo -e "${YELLOW}💭 Interactive mode - Enter your issue description:${NC}"
    echo -e "${BLUE}(Press Ctrl+D when finished, or type 'END' on a new line)${NC}"
    echo ""
    
    CONTENT=""
    while IFS= read -r line; do
        if [ "$line" = "END" ]; then
            break
        fi
        if [ -n "$CONTENT" ]; then
            CONTENT="$CONTENT"$'\n'"$line"
        else
            CONTENT="$line"
        fi
    done
fi

# Check if content is provided
if [ -z "$CONTENT" ]; then
    echo -e "${RED}❌ No content provided${NC}"
    usage
    exit 1
fi

# Generate filename
filename=$(generate_filename "$CONTENT" "$CUSTOM_TITLE")
filepath="$INBOX_DIR/$filename"

# Check if file already exists
if [ -f "$filepath" ]; then
    timestamp=$(date '+%H%M%S')
    filename="${filename%.*}-${timestamp}.md"
    filepath="$INBOX_DIR/$filename"
fi

# Create the file
echo "$CONTENT" > "$filepath"

echo -e "${GREEN}✅ Brain dump saved!${NC}"
echo -e "${BLUE}📁 File${NC}: inbox/$filename"
echo -e "${BLUE}📍 Path${NC}: $filepath"

# Show file stats
word_count=$(echo "$CONTENT" | wc -w | tr -d ' ')
line_count=$(echo "$CONTENT" | wc -l | tr -d ' ')
echo -e "${BLUE}📊 Stats${NC}: $word_count words, $line_count lines"

# Open in editor if requested
if [ "$OPEN_EDITOR" = true ]; then
    if command -v code &> /dev/null; then
        code "$filepath"
        echo -e "${GREEN}🔗 Opened in VS Code${NC}"
    elif command -v nano &> /dev/null; then
        nano "$filepath"
    else
        echo -e "${YELLOW}⚠️  No suitable editor found${NC}"
    fi
fi

echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo -e "  1. Run ${BLUE}./scripts/classify-issues.sh${NC} to classify this issue"
echo -e "  2. Review classified issues in ${BLUE}projects/*/${NC}"
echo -e "  3. Use ${BLUE}./scripts/push-to-github.sh${NC} to create GitHub issues"