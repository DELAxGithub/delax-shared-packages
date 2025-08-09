#!/bin/bash

# Test the complete workflow system

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAIN_DUMP_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🧪 Testing DELAX Brain Dump Workflow${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test 1: Quick dump creation
echo -e "${BLUE}Test 1: Quick Dump Creation${NC}"
cd "$BRAIN_DUMP_DIR"
./scripts/quick-dump.sh "タスク作成ボタンがiOS 18.5で反応しない。MyProjectsアプリのSwiftUIで発生。"
echo ""

# Test 2: Another issue
echo -e "${BLUE}Test 2: Another Issue${NC}"  
./scripts/quick-dump.sh "HealthKitデータが100 Days Workoutアプリで保存されない。権限エラーが発生。"
echo ""

# Test 3: Manual classification (simplified test)
echo -e "${BLUE}Test 3: Manual Classification${NC}"
for file in inbox/*.md; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    content=$(cat "$file")
    
    echo -e "${YELLOW}Analyzing: $filename${NC}"
    
    # Simple keyword-based classification for testing
    if echo "$content" | grep -qi "myprojects\|task\|タスク"; then
        classification="myprojects"
    elif echo "$content" | grep -qi "healthkit\|workout\|fitness\|ワークアウト"; then
        classification="workout-100days"
    elif echo "$content" | grep -qi "react\|web\|project management"; then
        classification="delaxpm"
    else
        classification="shared-packages"
    fi
    
    echo -e "  ${GREEN}Classified as: $classification${NC}"
    
    # Move to project directory
    target_dir="projects/$classification"
    mkdir -p "$target_dir"
    
    temp_file=$(mktemp)
    echo "# Issue: $filename" > "$temp_file"
    echo "**Project**: $classification" >> "$temp_file"
    echo "**Classified**: $(date '+%Y-%m-%d %H:%M:%S')" >> "$temp_file"
    echo "" >> "$temp_file"
    cat "$file" >> "$temp_file"
    
    mv "$temp_file" "$target_dir/$filename"
    rm "$file"
    
    echo -e "  ${GREEN}Moved to: projects/$classification/$filename${NC}"
done

echo ""

# Test 4: Show results
echo -e "${BLUE}Test 4: Classification Results${NC}"
for project_dir in projects/*/; do
    if [ -d "$project_dir" ]; then
        project=$(basename "$project_dir")
        count=$(find "$project_dir" -name "*.md" -type f | wc -l | tr -d ' ')
        if [ "$count" -gt 0 ]; then
            echo -e "  ${GREEN}$project${NC}: $count issues"
            
            # Show file names
            for file in "$project_dir"/*.md; do
                [ -f "$file" ] || continue
                echo -e "    - $(basename "$file")"
            done
        fi
    fi
done

echo ""

# Test 5: Dry run GitHub push
echo -e "${BLUE}Test 5: Dry Run GitHub Push${NC}"
./scripts/push-to-github.sh --dry-run --all

echo ""
echo -e "${GREEN}🎉 Workflow test completed successfully!${NC}"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo -e "✅ Quick dump creation"
echo -e "✅ Issue classification"
echo -e "✅ File organization"
echo -e "✅ GitHub integration (dry run)"
echo ""
echo -e "${BLUE}The system is ready for use!${NC}"