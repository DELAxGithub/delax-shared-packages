#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# DELAX Issue Router Setup Script
# Quick setup for the API-controlled issue routing system
# =============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$PROJECT_ROOT/.." && pwd)"

# --- Colors for output ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "   DELAX Issue Router Setup"
    echo "   API Usage Control & Duplicate Prevention"
    echo "=========================================="
    echo -e "${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v node &> /dev/null; then
        missing_tools+=("node")
    fi
    
    if ! command -v npm &> /dev/null; then
        missing_tools+=("npm")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install the missing tools and run setup again"
        return 1
    fi
    
    # Check Node.js version
    local node_version
    node_version=$(node --version | sed 's/v//')
    local major_version
    major_version=$(echo "$node_version" | cut -d. -f1)
    
    if [ "$major_version" -lt 18 ]; then
        log_error "Node.js version 18 or higher required (current: $node_version)"
        return 1
    fi
    
    log_success "All prerequisites satisfied"
    return 0
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    
    cd "$PROJECT_ROOT"
    
    if [ -f "package.json" ]; then
        npm install
        log_success "Dependencies installed"
    else
        log_error "package.json not found in $PROJECT_ROOT"
        return 1
    fi
}

# Build the project
build_project() {
    log_info "Building TypeScript project..."
    
    cd "$PROJECT_ROOT"
    
    if npm run build; then
        log_success "Project built successfully"
    else
        log_error "Build failed"
        return 1
    fi
}

# Setup data directories
setup_directories() {
    log_info "Setting up data directories..."
    
    local data_dirs=(
        "$PROJECT_ROOT/data"
        "$PROJECT_ROOT/temp"
        "$PROJECT_ROOT/logs"
    )
    
    for dir in "${data_dirs[@]}"; do
        mkdir -p "$dir"
        chmod 755 "$dir"
        log_info "Created directory: $dir"
    done
    
    log_success "Data directories created"
}

# Create default configuration
create_config() {
    log_info "Creating default configuration..."
    
    local config_file="$PROJECT_ROOT/config/delax-routing.yml"
    mkdir -p "$(dirname "$config_file")"
    
    cat > "$config_file" << 'EOF'
# DELAX Issue Router Configuration
# Enhanced version of routing.yml with API usage control

defaults:
  repo: "delax-org/delax-shared-packages"
  labels:
    - "triage"
    - "auto-routed"
  project:
    org: "delax-org"
    number: 1

# LLM Configuration with cost control
llm:
  model: "claude-4-sonnet-20250514"
  maxTokens: 4000
  temperature: 0.1

# Enhanced duplicate detection with API savings
duplicateDetection:
  enabled: true
  method: "enhanced" # content-hash + slack-permalink + edit-tracking
  lookbackDays: 60
  editThreshold: 0.1 # 10% change required to reprocess
  skipEditedWithinHours: 24

# API usage control
apiUsage:
  limits:
    dailyCallLimit: 100
    monthlyCallLimit: 2000
    dailyCostLimit: 50.0 # USD
    monthlyCostLimit: 1000.0 # USD
  monitoring:
    warningThresholds:
      daily: 0.8 # 80%
      monthly: 0.8 # 80%
    emergencyThresholds:
      daily: 0.95 # 95%
      monthly: 0.9 # 90%

# Priority processing
priorityProcessing:
  enabled: true
  emergencyKeywords:
    - "production down"
    - "critical"
    - "urgent"
    - "security"
    - "data loss"
  deferralThresholds:
    apiUsagePercentage: 0.8
    emergencyOnlyPercentage: 0.95
  batchProcessing:
    enabled: true
    maxBatchSize: 5
    batchWindowMinutes: 30

# DELAX Project Routes
routes:
  # MyProjects iOS App
  - when:
      keywords:
        - "MyProjects"
        - "task creation"
        - "SwiftData"
        - "CloudKit sync"
        - "iOS app"
        - "task management"
      titlePatterns:
        - ".*MyProjects.*"
        - ".*task.*creation.*"
        - ".*SwiftData.*"
    route:
      repo: "delax-org/myprojects-ios"
      labels:
        - "ios"
        - "swiftui"
        - "swiftdata"
      assignees:
        - "ios-team-lead"
      priority: "high"
      projectFields:
        Status: "Todo"
        Platform: "iOS"

  # 100 Days Workout
  - when:
      keywords:
        - "100 Days Workout"
        - "workout"
        - "fitness"
        - "HealthKit"
        - "health data"
      titlePatterns:
        - ".*100.*[Dd]ays.*"
        - ".*workout.*"
        - ".*fitness.*"
    route:
      repo: "delax-org/100-days-workout-ios"
      labels:
        - "ios"
        - "healthkit"
        - "fitness"
      assignees:
        - "ios-team-lead"
      priority: "medium"

  # DELAxPM Web
  - when:
      keywords:
        - "DELAxPM"
        - "project management"
        - "React"
        - "TypeScript"
        - "web app"
        - "collaboration"
      titlePatterns:
        - ".*DELAxPM.*"
        - ".*project.*management.*"
    route:
      repo: "delax-org/delaxpm-web"
      labels:
        - "web"
        - "react"
        - "typescript"
      assignees:
        - "frontend-lead"
      priority: "medium"

  # Shared Packages & Tools
  - when:
      keywords:
        - "shared packages"
        - "build"
        - "automation"
        - "CI/CD"
        - "development tools"
      titlePatterns:
        - ".*shared.*package.*"
        - ".*build.*"
        - ".*automation.*"
    route:
      repo: "delax-org/delax-shared-packages"
      labels:
        - "automation"
        - "build-tools"
        - "shared-package"
      assignees:
        - "dev-tools-lead"
      priority: "medium"

  # Security Issues (catch-all)
  - when:
      keywords:
        - "security"
        - "vulnerability"
        - "breach"
        - "exploit"
      labels:
        - "security"
    route:
      repo: "delax-org/security-issues"
      labels:
        - "security"
        - "critical"
      assignees:
        - "security-team"
      priority: "critical"
EOF
    
    log_success "Default configuration created: $config_file"
}

# Setup GitHub Actions workflow
setup_github_workflow() {
    log_info "Setting up GitHub Actions workflow..."
    
    local workflow_dir="$REPO_ROOT/.github/workflows"
    local workflow_file="$workflow_dir/delax-issue-router.yml"
    
    mkdir -p "$workflow_dir"
    
    if [ -f "$PROJECT_ROOT/workflows/delax-issue-router.yml" ]; then
        cp "$PROJECT_ROOT/workflows/delax-issue-router.yml" "$workflow_file"
        log_success "GitHub Actions workflow installed: $workflow_file"
    else
        log_warning "Workflow template not found. Please manually copy workflows/delax-issue-router.yml to .github/workflows/"
    fi
}

# Setup environment variables template
create_env_template() {
    log_info "Creating environment variables template..."
    
    local env_template="$PROJECT_ROOT/.env.example"
    
    cat > "$env_template" << 'EOF'
# DELAX Issue Router Environment Variables
# Copy to .env and fill in your values

# Required: Claude API key
ANTHROPIC_API_KEY=your_claude_api_key_here

# Required: GitHub token with repo and projects permissions
GITHUB_TOKEN=your_github_token_here

# Optional: Override default model
CLAUDE_MODEL=claude-4-sonnet-20250514

# Optional: Override token limits
MAX_TOKENS=4000
TEMPERATURE=0.1

# Optional: Debug mode
DEBUG=false
VERBOSE=false
EOF
    
    log_success "Environment template created: $env_template"
    log_warning "Please copy .env.example to .env and configure your API keys"
}

# Validate installation
validate_installation() {
    log_info "Validating installation..."
    
    local validation_errors=()
    
    # Check if build directory exists
    if [ ! -d "$PROJECT_ROOT/dist" ]; then
        validation_errors+=("Build directory missing")
    fi
    
    # Check required files
    local required_files=(
        "$PROJECT_ROOT/dist/duplicate-detector.js"
        "$PROJECT_ROOT/dist/api-usage-monitor.js"
        "$PROJECT_ROOT/dist/priority-processor.js"
        "$PROJECT_ROOT/scripts/claude-issue-classifier.sh"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            validation_errors+=("Missing file: $(basename "$file")")
        fi
    done
    
    # Check script permissions
    if [ -f "$PROJECT_ROOT/scripts/claude-issue-classifier.sh" ]; then
        if [ ! -x "$PROJECT_ROOT/scripts/claude-issue-classifier.sh" ]; then
            validation_errors+=("Script not executable: claude-issue-classifier.sh")
        fi
    fi
    
    if [ ${#validation_errors[@]} -gt 0 ]; then
        log_error "Validation failed:"
        for error in "${validation_errors[@]}"; do
            log_error "  - $error"
        done
        return 1
    fi
    
    log_success "Installation validated successfully"
    return 0
}

# Print next steps
print_next_steps() {
    log_success "🎉 DELAX Issue Router setup complete!"
    echo
    log_info "Next steps:"
    echo "1. Copy .env.example to .env and configure your API keys"
    echo "2. Test the setup with: npm run test"
    echo "3. Deploy the GitHub Actions workflow to your repositories"
    echo "4. Create issues to test the routing system"
    echo
    log_info "Configuration files:"
    echo "  - Config: config/delax-routing.yml"
    echo "  - Environment: .env.example"
    echo "  - Workflow: workflows/delax-issue-router.yml"
    echo
    log_info "Data directories:"
    echo "  - Processing history: data/"
    echo "  - Temporary files: temp/"
    echo "  - Logs: logs/"
    echo
    log_info "Documentation:"
    echo "  - README: automation/routing-system/README.md"
    echo "  - API Reference: automation/routing-system/docs/"
}

# Main setup function
main() {
    print_header
    
    log_info "Setting up DELAX Issue Router in: $PROJECT_ROOT"
    echo
    
    # Run setup steps
    if ! check_prerequisites; then
        exit 1
    fi
    
    if ! install_dependencies; then
        log_error "Failed to install dependencies"
        exit 1
    fi
    
    if ! build_project; then
        log_error "Failed to build project"
        exit 1
    fi
    
    setup_directories
    create_config
    setup_github_workflow
    create_env_template
    
    if ! validate_installation; then
        log_error "Installation validation failed"
        exit 1
    fi
    
    print_next_steps
}

# Error handling
error_handler() {
    local line_number=$1
    log_error "Setup failed at line $line_number"
    exit 1
}

trap 'error_handler $LINENO' ERR

# Execute main function
main "$@"