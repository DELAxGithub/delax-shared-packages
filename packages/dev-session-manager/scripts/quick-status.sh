#!/bin/bash

# 🚀 Universal Quick Status - プロジェクト現状を3分で把握するスクリプト
# Usage: ./scripts/quick-status.sh [--full]
# Part of DELAx Dev Session Manager

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Load configuration parser
if [ -f "$LIB_DIR/config-parser.sh" ]; then
    source "$LIB_DIR/config-parser.sh"
else
    echo "❌ Configuration parser not found. Please run install script."
    exit 1
fi

# Load configuration
load_config

# Get configuration values
PROJECT_NAME=$(get_project_name)
PROJECT_TYPE=$(get_project_type)
PROGRESS_FILE=$(get_progress_file)
BUILD_COMMAND=$(get_build_command)
TEST_COMMAND=$(get_test_command)

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "📊 $PROJECT_NAME - Project Status Dashboard"
echo "=================================================="
echo "Type: $PROJECT_TYPE"
echo ""

# Git status
echo "🔧 Git Status:"
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Current Branch: $(git branch --show-current)"
    echo "Last Commit: $(git log -1 --pretty=format:'%h - %s (%cr)' 2>/dev/null || echo 'No commits')"
else
    echo -e "${YELLOW}Not a git repository${NC}"
fi
echo ""

# Changed files check
CHANGED_FILES=$(git status --porcelain 2>/dev/null | wc -l | xargs)
if [ "$CHANGED_FILES" -gt 0 ] 2>/dev/null; then
    echo "📝 Changed Files: $CHANGED_FILES files"
    git status --short | head -5
    if [ "$CHANGED_FILES" -gt 5 ]; then
        echo "... and $((CHANGED_FILES - 5)) more"
    fi
else
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo "✅ Working Directory: Clean"
    fi
fi
echo ""

# Build status check
echo "🏗️ Build Status:"

# Check for common build artifacts/logs
build_status_found=false

case "$PROJECT_TYPE" in
    "ios")
        if [ -f "build.log" ] || [ -f "xcodebuild.log" ]; then
            last_build=$(tail -1 build.log xcodebuild.log 2>/dev/null | grep -E "(BUILD SUCCEEDED|BUILD FAILED)" | tail -1 || echo "Unknown")
            echo "Last Build: $last_build"
            build_status_found=true
        fi
        
        # Check for Xcode build errors
        if [ -d "workoutbuilderror" ] && [ -n "$(ls -A workoutbuilderror 2>/dev/null)" ]; then
            latest_error=$(ls -t workoutbuilderror/*.txt 2>/dev/null | head -1)
            if [ -n "$latest_error" ]; then
                error_time=$(basename "$latest_error" | sed 's/Build.*_\(.*\)\.txt/\1/' | sed 's/T/ /')
                echo -e "${RED}⚠️ Latest Build Error: $error_time${NC}"
            fi
        fi
        ;;
    "web")
        if [ -f "npm-debug.log" ] || [ -f ".next/build-manifest.json" ] || [ -f "dist/index.js" ]; then
            echo "Build Command: $BUILD_COMMAND"
            if [ -f "package.json" ]; then
                echo "Last Package Update: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M" package.json 2>/dev/null || echo "Unknown")"
            fi
            build_status_found=true
        fi
        ;;
    "python")
        if [ -f "build.log" ] || [ -d "dist/" ] || [ -d "build/" ]; then
            echo "Build Command: $BUILD_COMMAND"
            build_status_found=true
        fi
        ;;
    *)
        if [ -f "build.log" ]; then
            last_build=$(tail -1 build.log 2>/dev/null || echo "Unknown")
            echo "Last Build: $last_build"
            build_status_found=true
        fi
        ;;
esac

if [ "$build_status_found" = false ]; then
    echo "Build Command: $BUILD_COMMAND"
    echo -e "${YELLOW}No build artifacts found${NC}"
fi
echo ""

# Project statistics
echo "📊 Project Stats:"

# Get configuration arrays (bash 3 compatible)
source_dirs=()
while IFS= read -r line; do
    [ -n "$line" ] && source_dirs+=("$line")
done < <(get_source_dirs)

file_extensions=()
while IFS= read -r line; do
    [ -n "$line" ] && file_extensions+=("$line")
done < <(get_file_extensions)

exclude_dirs=()
while IFS= read -r line; do
    [ -n "$line" ] && exclude_dirs+=("$line")
done < <(get_exclude_dirs)

todo_patterns=()
while IFS= read -r line; do
    [ -n "$line" ] && todo_patterns+=("$line")
done < <(get_todo_patterns)

# Default fallbacks
if [ ${#source_dirs[@]} -eq 0 ]; then
    case "$PROJECT_TYPE" in
        "ios") source_dirs=("$PROJECT_NAME/" "Sources/" "App/") ;;
        "web") source_dirs=("src/" "lib/" "components/") ;;
        "python") source_dirs=("src/" "lib/" "app/") ;;
        *) source_dirs=("src/" "lib/") ;;
    esac
fi

if [ ${#file_extensions[@]} -eq 0 ]; then
    case "$PROJECT_TYPE" in
        "ios") file_extensions=(".swift" ".h" ".m") ;;
        "web") file_extensions=(".js" ".ts" ".jsx" ".tsx" ".vue") ;;
        "python") file_extensions=(".py") ;;
        *) file_extensions=(".js" ".ts" ".py") ;;
    esac
fi

if [ ${#todo_patterns[@]} -eq 0 ]; then
    todo_patterns=("TODO" "FIXME" "HACK" "NOTE")
fi

# Count files and lines (with performance optimization)
total_files=0
total_lines=0

# Build find pattern for all extensions
ext_pattern=""
for ext in "${file_extensions[@]}"; do
    if [ -z "$ext_pattern" ]; then
        ext_pattern="-name \"*$ext\""
    else
        ext_pattern="$ext_pattern -o -name \"*$ext\""
    fi
done

for dir in "${source_dirs[@]}"; do
    if [ -d "$dir" ]; then
        # Count files efficiently
        files=$(eval "find \"$dir\" \\( $ext_pattern \\) 2>/dev/null" | wc -l | xargs)
        total_files=$((total_files + files))
        
        # Count lines with timeout for large projects
        lines=$(eval "find \"$dir\" \\( $ext_pattern \\) -exec wc -l {} + 2>/dev/null" | awk '{sum += $1} END {print sum+0}')
        total_lines=$((total_lines + lines))
    fi
done

echo "Project Files: $total_files"
echo "Total Lines of Code: $total_lines"

# Count special files based on project type
case "$PROJECT_TYPE" in
    "ios")
        models=$(find . -name "*.swift" -exec grep -l "struct.*:" {} \; -o -exec grep -l "class.*:" {} \; 2>/dev/null | wc -l | xargs)
        echo "Swift Models/Classes: $models"
        ;;
    "web")
        if [ -f "package.json" ]; then
            deps=$(jq -r '.dependencies // {} | keys | length' package.json 2>/dev/null || echo "0")
            echo "Dependencies: $deps"
        fi
        ;;
    "python")
        if [ -f "requirements.txt" ]; then
            deps=$(wc -l < requirements.txt 2>/dev/null | xargs)
            echo "Requirements: $deps"
        elif [ -f "pyproject.toml" ]; then
            echo "Package Management: Poetry/PyProject"
        fi
        ;;
esac

# TODO/FIXME count (optimized)
todo_count=0
for pattern in "${todo_patterns[@]}"; do
    for dir in "${source_dirs[@]}"; do
        if [ -d "$dir" ]; then
            count=$(eval "find \"$dir\" \\( $ext_pattern \\) -exec grep -c \"$pattern\" {} + 2>/dev/null" | awk '{sum += $1} END {print sum+0}')
            todo_count=$((todo_count + count))
        fi
    done
done

echo "TODO/FIXME items: $todo_count"
echo ""

# Progress files check
echo "📋 Progress Files:"
if [ -f "$PROGRESS_FILE" ]; then
    last_updated=$(grep "Last Updated:" "$PROGRESS_FILE" | tail -1 | sed 's/.*Last Updated: //' || echo "Unknown")
    echo "✅ $PROGRESS_FILE (Updated: $last_updated)"
else
    echo -e "${RED}❌ $PROGRESS_FILE not found${NC}"
    echo "💡 Create from template: cp templates/PROGRESS_UNIFIED.template.md $PROGRESS_FILE"
fi

session_template=$(get_session_template)
if [ -f "$session_template" ]; then
    echo "📄 $session_template (Template available)"
fi
echo ""

# --full option detailed analysis
if [ "$1" = "--full" ]; then
    echo "🔍 Detailed Analysis (--full mode):"
    echo "================================="
    
    # Recent commit history
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo ""
        echo "📝 Recent Commits (last 5):"
        git log --oneline -5 2>/dev/null || echo "No commit history"
    fi
    
    # Largest files
    echo ""
    echo "📏 Largest Files (top 5):"
    for ext in "${file_extensions[@]}"; do
        find . -name "*$ext" -exec wc -l {} \; 2>/dev/null | sort -rn | head -5 | while read lines file; do
            filename=$(basename "$file")
            echo "  $lines lines - $filename"
        done | head -5
    done
    
    # Project structure based on type
    echo ""
    case "$PROJECT_TYPE" in
        "ios")
            echo "🧩 iOS Project Structure:"
            for dir in "$PROJECT_NAME" "Sources" "Tests" "Resources"; do
                if [ -d "$dir" ]; then
                    count=$(find "$dir" -name "*.swift" 2>/dev/null | wc -l | xargs)
                    echo "  $dir/: $count Swift files"
                fi
            done
            ;;
        "web")
            echo "🌐 Web Project Structure:"
            for dir in "src" "lib" "components" "pages" "public"; do
                if [ -d "$dir" ]; then
                    count=$(find "$dir" -type f 2>/dev/null | wc -l | xargs)
                    echo "  $dir/: $count files"
                fi
            done
            ;;
        "python")
            echo "🐍 Python Project Structure:"
            for dir in "src" "lib" "app" "tests"; do
                if [ -d "$dir" ]; then
                    count=$(find "$dir" -name "*.py" 2>/dev/null | wc -l | xargs)
                    echo "  $dir/: $count Python files"
                fi
            done
            ;;
    esac
    
    # Configuration summary
    echo ""
    echo "⚙️ Configuration:"
    echo "  Build: $BUILD_COMMAND"
    echo "  Test: $TEST_COMMAND"
    echo "  Progress File: $PROGRESS_FILE"
fi

echo ""
echo "🎯 Next Steps:"
echo "1. Check $PROGRESS_FILE for current session focus"
echo "2. Review any TODO items or build errors"
echo "3. Use '--full' flag for detailed analysis"
echo ""
echo "💡 Quick Commands:"
echo "  $BUILD_COMMAND"
echo "  $TEST_COMMAND"
echo "  ./scripts/progress-tracker.sh session-start"
echo "  ./scripts/quick-status.sh --full"
echo "=================================================="