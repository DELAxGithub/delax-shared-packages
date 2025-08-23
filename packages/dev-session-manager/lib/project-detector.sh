#!/bin/bash

# 🔍 Project Technology Stack Auto-Detector
# Automatically detects project type and generates appropriate configuration

PROJECT_ROOT="${1:-.}"
CONFIG_FILE="dev-session-config.json"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Detect iOS/Swift projects
detect_ios() {
    if [ -f "$PROJECT_ROOT"/*.xcodeproj/project.pbxproj ] || 
       [ -f "$PROJECT_ROOT"/Package.swift ] || 
       [ -f "$PROJECT_ROOT"/*.xcworkspace/contents.xcworkspacedata ]; then
        return 0
    fi
    return 1
}

# Detect Web projects (Node.js/TypeScript/React)
detect_web() {
    if [ -f "$PROJECT_ROOT/package.json" ]; then
        return 0
    fi
    return 1
}

# Detect Python projects
detect_python() {
    if [ -f "$PROJECT_ROOT/pyproject.toml" ] ||
       [ -f "$PROJECT_ROOT/requirements.txt" ] ||
       [ -f "$PROJECT_ROOT/setup.py" ]; then
        return 0
    fi
    return 1
}

# Detect Go projects
detect_go() {
    if [ -f "$PROJECT_ROOT/go.mod" ]; then
        return 0
    fi
    return 1
}

# Detect Rust projects
detect_rust() {
    if [ -f "$PROJECT_ROOT/Cargo.toml" ]; then
        return 0
    fi
    return 1
}

# Generate iOS configuration
generate_ios_config() {
    local project_name=$(basename "$PROJECT_ROOT")
    
    # Try to find project name from .xcodeproj
    if [ -f "$PROJECT_ROOT"/*.xcodeproj/project.pbxproj ]; then
        project_name=$(basename "$PROJECT_ROOT"/*.xcodeproj .xcodeproj)
    fi
    
    cat > "$PROJECT_ROOT/$CONFIG_FILE" << EOF
{
  "project": {
    "name": "$project_name",
    "type": "ios",
    "source_dirs": ["$project_name/", "Sources/", "App/"],
    "build_command": "xcodebuild -project $project_name.xcodeproj -scheme $project_name build",
    "test_command": "xcodebuild -project $project_name.xcodeproj -scheme $project_name test"
  },
  "tracking": {
    "progress_file": "PROGRESS_UNIFIED.md",
    "session_template": "SESSION_TEMPLATE.md",
    "backup_dir": ".progress_backup"
  },
  "stats": {
    "file_extensions": [".swift", ".h", ".m"],
    "exclude_dirs": ["build", "DerivedData", ".git", "Pods"],
    "metrics": ["files", "lines", "todos", "models", "views"],
    "todo_patterns": ["TODO", "FIXME", "MARK", "NOTE"]
  }
}
EOF
}

# Generate Web configuration
generate_web_config() {
    local project_name=$(basename "$PROJECT_ROOT")
    
    # Try to extract name from package.json
    if [ -f "$PROJECT_ROOT/package.json" ] && command -v jq >/dev/null 2>&1; then
        project_name=$(jq -r '.name // "web-project"' "$PROJECT_ROOT/package.json")
    fi
    
    cat > "$PROJECT_ROOT/$CONFIG_FILE" << EOF
{
  "project": {
    "name": "$project_name",
    "type": "web",
    "source_dirs": ["src/", "lib/", "components/", "pages/"],
    "build_command": "npm run build",
    "test_command": "npm test"
  },
  "tracking": {
    "progress_file": "PROGRESS_UNIFIED.md",
    "session_template": "SESSION_TEMPLATE.md",
    "backup_dir": ".progress_backup"
  },
  "stats": {
    "file_extensions": [".js", ".ts", ".jsx", ".tsx", ".vue"],
    "exclude_dirs": ["node_modules", "build", "dist", ".next", ".git"],
    "metrics": ["files", "lines", "todos", "components"],
    "todo_patterns": ["TODO", "FIXME", "HACK", "BUG"]
  }
}
EOF
}

# Generate Python configuration
generate_python_config() {
    local project_name=$(basename "$PROJECT_ROOT")
    
    cat > "$PROJECT_ROOT/$CONFIG_FILE" << EOF
{
  "project": {
    "name": "$project_name",
    "type": "python",
    "source_dirs": ["src/", "lib/", "app/", "$project_name/"],
    "build_command": "python -m build",
    "test_command": "python -m pytest"
  },
  "tracking": {
    "progress_file": "PROGRESS_UNIFIED.md",
    "session_template": "SESSION_TEMPLATE.md",
    "backup_dir": ".progress_backup"
  },
  "stats": {
    "file_extensions": [".py"],
    "exclude_dirs": ["__pycache__", "build", "dist", ".venv", ".git"],
    "metrics": ["files", "lines", "todos", "classes", "functions"],
    "todo_patterns": ["TODO", "FIXME", "HACK", "NOTE"]
  }
}
EOF
}

# Generate Go configuration
generate_go_config() {
    local project_name=$(basename "$PROJECT_ROOT")
    
    cat > "$PROJECT_ROOT/$CONFIG_FILE" << EOF
{
  "project": {
    "name": "$project_name",
    "type": "go",
    "source_dirs": ["cmd/", "internal/", "pkg/", "src/"],
    "build_command": "go build ./...",
    "test_command": "go test ./..."
  },
  "tracking": {
    "progress_file": "PROGRESS_UNIFIED.md",
    "session_template": "SESSION_TEMPLATE.md",
    "backup_dir": ".progress_backup"
  },
  "stats": {
    "file_extensions": [".go"],
    "exclude_dirs": ["vendor", "bin", ".git"],
    "metrics": ["files", "lines", "todos", "packages"],
    "todo_patterns": ["TODO", "FIXME", "HACK", "BUG"]
  }
}
EOF
}

# Main detection logic
main() {
    log_info "🔍 Detecting project technology stack in: $PROJECT_ROOT"
    
    if [ -f "$PROJECT_ROOT/$CONFIG_FILE" ]; then
        log_warning "Configuration file already exists: $CONFIG_FILE"
        read -p "Overwrite existing configuration? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Configuration generation cancelled"
            exit 0
        fi
    fi
    
    # Detection priority (most specific first)
    if detect_ios; then
        log_success "📱 iOS/Swift project detected"
        generate_ios_config
        log_success "Generated iOS configuration: $CONFIG_FILE"
        
    elif detect_go; then
        log_success "🐹 Go project detected"
        generate_go_config
        log_success "Generated Go configuration: $CONFIG_FILE"
        
    elif detect_rust; then
        log_success "🦀 Rust project detected"
        log_warning "Rust configuration not yet implemented, using generic config"
        
    elif detect_python; then
        log_success "🐍 Python project detected"
        generate_python_config
        log_success "Generated Python configuration: $CONFIG_FILE"
        
    elif detect_web; then
        log_success "🌐 Web/Node.js project detected"
        generate_web_config
        log_success "Generated Web configuration: $CONFIG_FILE"
        
    else
        log_warning "❓ Could not auto-detect project type"
        log_info "Please manually create $CONFIG_FILE or specify project type:"
        echo "  ./project-detector.sh --type [ios|web|python|go]"
        exit 1
    fi
    
    log_info "🎯 Next steps:"
    echo "  1. Review generated configuration: $CONFIG_FILE"
    echo "  2. Run: ./install.sh to set up dev session management"
    echo "  3. Start your first session: ./scripts/progress-tracker.sh session-start"
}

# Handle command line arguments
case "${1:-auto}" in
    "--type")
        case "$2" in
            "ios") generate_ios_config && log_success "Generated iOS configuration" ;;
            "web") generate_web_config && log_success "Generated Web configuration" ;;
            "python") generate_python_config && log_success "Generated Python configuration" ;;
            "go") generate_go_config && log_success "Generated Go configuration" ;;
            *) log_error "Unsupported project type: $2" && exit 1 ;;
        esac
        ;;
    "--help"|"-h")
        echo "Usage: $0 [PROJECT_ROOT]"
        echo "       $0 --type [ios|web|python|go]"
        echo ""
        echo "Auto-detect project technology stack and generate configuration."
        exit 0
        ;;
    *)
        main
        ;;
esac