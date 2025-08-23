#!/bin/bash

# 🚀 DELAx Dev Session Manager - One-Click Installer
# Installs and configures the universal development session management system

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
PACKAGE_NAME="DELAx Dev Session Manager"
VERSION="1.0.0"
TARGET_DIR="${1:-.}"
FORCE_INSTALL=false

log_header() {
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo "=================================================="
}

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

log_step() {
    echo -e "${BOLD}Step $1:${NC} $2"
}

show_banner() {
    echo ""
    echo -e "${BOLD}${BLUE}🚀 $PACKAGE_NAME${NC}"
    echo -e "${BLUE}   Universal Development Session Management${NC}"
    echo -e "${BLUE}   Version: $VERSION${NC}"
    echo ""
}

check_prerequisites() {
    log_step "1" "Checking prerequisites..."
    
    local missing_deps=()
    
    # Check for required commands
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Please install the missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                "git")
                    echo "  • Git: https://git-scm.com/downloads"
                    ;;
                "jq")
                    echo "  • jq: https://stedolan.github.io/jq/download/"
                    echo "    macOS: brew install jq"
                    echo "    Ubuntu: apt install jq"
                    ;;
            esac
        done
        exit 1
    fi
    
    log_success "All prerequisites satisfied"
}

get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

copy_package_files() {
    log_step "2" "Installing package files..."
    
    local script_dir
    script_dir=$(get_script_dir)
    
    # Create directory structure
    mkdir -p "$TARGET_DIR/scripts"
    mkdir -p "$TARGET_DIR/templates"
    mkdir -p "$TARGET_DIR/lib"
    mkdir -p "$TARGET_DIR/docs"
    
    # Copy scripts
    if [ -d "$script_dir/scripts" ]; then
        cp -r "$script_dir/scripts/"* "$TARGET_DIR/scripts/"
        chmod +x "$TARGET_DIR/scripts/"*.sh
        log_info "Scripts installed to: $TARGET_DIR/scripts/"
    fi
    
    # Copy templates
    if [ -d "$script_dir/templates" ]; then
        cp -r "$script_dir/templates/"* "$TARGET_DIR/templates/"
        log_info "Templates installed to: $TARGET_DIR/templates/"
    fi
    
    # Copy libraries
    if [ -d "$script_dir/lib" ]; then
        cp -r "$script_dir/lib/"* "$TARGET_DIR/lib/"
        chmod +x "$TARGET_DIR/lib/"*.sh
        log_info "Libraries installed to: $TARGET_DIR/lib/"
    fi
    
    # Copy documentation
    if [ -d "$script_dir/docs" ]; then
        cp -r "$script_dir/docs/"* "$TARGET_DIR/docs/" 2>/dev/null || true
    fi
    
    log_success "Package files installed successfully"
}

detect_and_configure() {
    log_step "3" "Detecting project and creating configuration..."
    
    cd "$TARGET_DIR"
    
    # Run project detector
    if [ -f "lib/project-detector.sh" ]; then
        if [ -f "dev-session-config.json" ] && [ "$FORCE_INSTALL" != true ]; then
            log_warning "Configuration already exists"
            read -p "Overwrite existing configuration? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                ./lib/project-detector.sh
            fi
        else
            ./lib/project-detector.sh
        fi
        
        if [ -f "dev-session-config.json" ]; then
            log_success "Configuration created: dev-session-config.json"
        else
            log_warning "Could not auto-detect project type"
            log_info "You may need to manually create dev-session-config.json"
        fi
    else
        log_error "Project detector not found"
        return 1
    fi
}

setup_progress_files() {
    log_step "4" "Setting up progress tracking files..."
    
    cd "$TARGET_DIR"
    
    # Get project info from config
    local project_name="MyProject"
    local project_type="unknown"
    local current_date=$(date '+%Y-%m-%d')
    
    if [ -f "dev-session-config.json" ] && command -v jq >/dev/null 2>&1; then
        project_name=$(jq -r '.project.name // "MyProject"' dev-session-config.json)
        project_type=$(jq -r '.project.type // "unknown"' dev-session-config.json)
    fi
    
    # Create PROGRESS_UNIFIED.md if it doesn't exist
    if [ ! -f "PROGRESS_UNIFIED.md" ] || [ "$FORCE_INSTALL" = true ]; then
        if [ -f "templates/PROGRESS_UNIFIED.template.md" ]; then
            sed -e "s/{{PROJECT_NAME}}/$project_name/g" \
                -e "s/{{PROJECT_TYPE}}/$project_type/g" \
                -e "s/{{CURRENT_DATE}}/$current_date/g" \
                templates/PROGRESS_UNIFIED.template.md > PROGRESS_UNIFIED.md
            log_success "Created: PROGRESS_UNIFIED.md"
        fi
    else
        log_info "PROGRESS_UNIFIED.md already exists (skipped)"
    fi
    
    # Create SESSION_TEMPLATE.md if it doesn't exist
    if [ ! -f "SESSION_TEMPLATE.md" ] || [ "$FORCE_INSTALL" = true ]; then
        if [ -f "templates/SESSION_TEMPLATE.md" ]; then
            sed -e "s/{{PROJECT_NAME}}/$project_name/g" \
                -e "s/{{PROJECT_TYPE}}/$project_type/g" \
                -e "s/{{CURRENT_DATE}}/$current_date/g" \
                templates/SESSION_TEMPLATE.md > SESSION_TEMPLATE.md
            log_success "Created: SESSION_TEMPLATE.md"
        fi
    else
        log_info "SESSION_TEMPLATE.md already exists (skipped)"
    fi
}

create_quick_access() {
    log_step "5" "Creating quick access commands..."
    
    cd "$TARGET_DIR"
    
    # Create convenient wrapper scripts
    cat > dev-session << 'EOF'
#!/bin/bash
# Quick access to dev session manager
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-help}" in
    "start")
        "$SCRIPT_DIR/scripts/progress-tracker.sh" session-start
        ;;
    "end")
        "$SCRIPT_DIR/scripts/progress-tracker.sh" session-end
        ;;
    "status")
        "$SCRIPT_DIR/scripts/quick-status.sh" "${2:-}"
        ;;
    "config")
        "$SCRIPT_DIR/scripts/progress-tracker.sh" config
        ;;
    "help"|*)
        echo "DELAx Dev Session Manager - Quick Commands"
        echo "Usage: ./dev-session [command]"
        echo ""
        echo "Commands:"
        echo "  start    - Start development session"
        echo "  end      - End development session"
        echo "  status   - Show project status (add --full for details)"
        echo "  config   - Show current configuration"
        echo "  help     - Show this help"
        ;;
esac
EOF
    
    chmod +x dev-session
    log_success "Created quick access command: ./dev-session"
}

run_verification() {
    log_step "6" "Running installation verification..."
    
    cd "$TARGET_DIR"
    
    local errors=0
    
    # Check required files
    local required_files=(
        "dev-session-config.json"
        "scripts/progress-tracker.sh"
        "scripts/quick-status.sh"
        "lib/config-parser.sh"
        "lib/project-detector.sh"
        "PROGRESS_UNIFIED.md"
        "dev-session"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "Missing required file: $file"
            errors=$((errors + 1))
        fi
    done
    
    # Test configuration loading
    if [ -f "lib/config-parser.sh" ]; then
        source lib/config-parser.sh
        if validate_config >/dev/null 2>&1; then
            log_success "Configuration validation passed"
        else
            log_warning "Configuration validation issues detected"
            errors=$((errors + 1))
        fi
    fi
    
    # Test quick access command
    if ./dev-session config >/dev/null 2>&1; then
        log_success "Quick access command working"
    else
        log_warning "Quick access command may have issues"
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "Installation verification passed"
        return 0
    else
        log_warning "Installation completed with $errors warnings"
        return 1
    fi
}

show_next_steps() {
    log_header "🎯 Installation Complete!"
    
    echo "Your development session management system is ready!"
    echo ""
    echo "📋 Quick Start:"
    echo "  ./dev-session start     # Start your first session"
    echo "  ./dev-session status    # Check project status"
    echo "  ./dev-session end       # End current session"
    echo ""
    echo "📁 Files Created:"
    echo "  • dev-session-config.json  # Project configuration"
    echo "  • PROGRESS_UNIFIED.md      # Main progress tracking"
    echo "  • SESSION_TEMPLATE.md      # Session template"
    echo "  • dev-session              # Quick access command"
    echo ""
    echo "📚 Advanced Usage:"
    echo "  ./scripts/quick-status.sh --full    # Detailed project analysis"
    echo "  ./scripts/progress-tracker.sh       # Manual session management"
    echo ""
    echo "🔧 Configuration:"
    echo "  Edit dev-session-config.json to customize settings"
    echo "  Review PROGRESS_UNIFIED.md and add your project details"
    echo ""
    echo "💡 Next Steps:"
    echo "  1. Review and customize your configuration"
    echo "  2. Add your first session goals to PROGRESS_UNIFIED.md"
    echo "  3. Start your first tracked development session!"
    echo ""
    echo -e "${BOLD}Happy coding! 🚀${NC}"
}

show_help() {
    echo "DELAx Dev Session Manager Installer"
    echo ""
    echo "Usage: $0 [TARGET_DIR] [OPTIONS]"
    echo ""
    echo "Arguments:"
    echo "  TARGET_DIR    Target installation directory (default: current directory)"
    echo ""
    echo "Options:"
    echo "  --force       Force installation, overwrite existing files"
    echo "  --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Install in current directory"
    echo "  $0 /path/to/project   # Install in specific directory"
    echo "  $0 . --force          # Force reinstall in current directory"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_INSTALL=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [ -z "$TARGET_DIR" ]; then
                TARGET_DIR="$1"
            fi
            shift
            ;;
    esac
done

# Main installation process
main() {
    show_banner
    
    # Convert to absolute path
    TARGET_DIR=$(cd "$TARGET_DIR" && pwd)
    log_info "Installing to: $TARGET_DIR"
    
    check_prerequisites
    copy_package_files
    detect_and_configure
    setup_progress_files
    create_quick_access
    
    if run_verification; then
        show_next_steps
        exit 0
    else
        log_error "Installation completed with warnings"
        echo "Please review the warnings above and fix any issues."
        exit 1
    fi
}

main