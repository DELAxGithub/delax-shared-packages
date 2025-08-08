#!/bin/bash

# Issue Routing System Setup Script
# This script helps set up the routing system in a new organization or repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
ROUTER_REPO=""
TARGET_REPOS=()
PROJECT_ORG=""
PROJECT_NUMBER=""
GITHUB_TOKEN=""
OPENAI_API_KEY=""

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate GitHub token
validate_github_token() {
    local token="$1"
    if curl -s -H "Authorization: token $token" https://api.github.com/user >/dev/null; then
        return 0
    else
        return 1
    fi
}

# Get user input
get_user_input() {
    print_status "Setting up Issue Routing System..."
    echo
    
    # Router repository
    read -p "Enter the router repository (e.g., 'your-org/router'): " ROUTER_REPO
    if [[ -z "$ROUTER_REPO" ]]; then
        print_error "Router repository is required"
        exit 1
    fi
    
    # Target repositories
    print_status "Enter target repositories (one per line, empty line to finish):"
    while true; do
        read -p "Repository: " repo
        if [[ -z "$repo" ]]; then
            break
        fi
        TARGET_REPOS+=("$repo")
    done
    
    if [[ ${#TARGET_REPOS[@]} -eq 0 ]]; then
        print_error "At least one target repository is required"
        exit 1
    fi
    
    # Project configuration (optional)
    read -p "Enter GitHub Projects organization (optional): " PROJECT_ORG
    if [[ -n "$PROJECT_ORG" ]]; then
        read -p "Enter GitHub Projects number: " PROJECT_NUMBER
    fi
    
    # GitHub token
    read -s -p "Enter GitHub token (with repo and project permissions): " GITHUB_TOKEN
    echo
    
    if [[ -z "$GITHUB_TOKEN" ]]; then
        print_error "GitHub token is required"
        exit 1
    fi
    
    # OpenAI API key (optional)
    read -s -p "Enter OpenAI API key (optional, for LLM classification): " OPENAI_API_KEY
    echo
    
    echo
    print_status "Configuration collected. Validating..."
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check required commands
    local required_commands=("curl" "jq" "node" "npm")
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            print_error "Required command not found: $cmd"
            exit 1
        fi
    done
    
    # Check Node.js version
    local node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [[ "$node_version" -lt 18 ]]; then
        print_error "Node.js 18 or higher is required (current: $(node --version))"
        exit 1
    fi
    
    # Validate GitHub token
    if ! validate_github_token "$GITHUB_TOKEN"; then
        print_error "Invalid GitHub token or insufficient permissions"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    if [[ -f "package.json" ]]; then
        npm ci
        npm run build
        print_success "Dependencies installed and project built"
    else
        print_error "package.json not found. Run this script from the routing-system directory."
        exit 1
    fi
}

# Generate configuration file
generate_config() {
    print_status "Generating configuration file..."
    
    local config_file="config/routing.yml"
    
    # Backup existing config
    if [[ -f "$config_file" ]]; then
        cp "$config_file" "$config_file.backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Existing config backed up"
    fi
    
    # Generate new config
    cat > "$config_file" << EOF
# Generated Issue Routing Configuration
# Generated on: $(date)

defaults:
  repo: "${TARGET_REPOS[0]}"
  labels:
    - "triage"
    - "auto-routed"
EOF

    if [[ -n "$PROJECT_ORG" && -n "$PROJECT_NUMBER" ]]; then
        cat >> "$config_file" << EOF
  project:
    org: "$PROJECT_ORG"
    number: $PROJECT_NUMBER
EOF
    fi

    cat >> "$config_file" << EOF

llm:
  model: "claude-3-sonnet"
  maxTokens: 4000
  temperature: 0.1

duplicateDetection:
  enabled: true
  method: "both"
  lookbackDays: 30

rules:
EOF

    # Generate basic rules for each target repository
    for repo in "${TARGET_REPOS[@]}"; do
        local repo_name=$(echo "$repo" | cut -d'/' -f2)
        cat >> "$config_file" << EOF
  - when:
      keywords:
        - "$repo_name"
    route:
      repo: "$repo"
      labels:
        - "$(echo "$repo_name" | tr '[:upper:]' '[:lower:]')"
      priority: "medium"

EOF
    done
    
    print_success "Configuration file generated: $config_file"
    print_warning "Please review and customize the generated configuration"
}

# Setup GitHub workflows
setup_workflows() {
    print_status "Setting up GitHub workflows..."
    
    local router_workflow_dir="../.github/workflows"
    
    # Create workflows directory if it doesn't exist
    mkdir -p "$router_workflow_dir"
    
    # Copy router workflow
    if [[ -f "workflows/router.yml" ]]; then
        cp "workflows/router.yml" "$router_workflow_dir/route-issues.yml"
        print_success "Router workflow copied to $router_workflow_dir/route-issues.yml"
    else
        print_error "Router workflow template not found"
    fi
    
    print_status "For target repositories, copy workflows/triage.yml to each repository's .github/workflows/ directory"
}

# Setup secrets
setup_secrets() {
    print_status "Setting up repository secrets..."
    
    print_warning "You need to manually add the following secrets to your repositories:"
    echo
    echo "Router Repository ($ROUTER_REPO):"
    echo "  ROUTING_TOKEN: $GITHUB_TOKEN (or create a dedicated token with broader permissions)"
    if [[ -n "$OPENAI_API_KEY" ]]; then
        echo "  OPENAI_API_KEY: [your OpenAI API key]"
    fi
    echo
    
    for repo in "${TARGET_REPOS[@]}"; do
        echo "Target Repository ($repo):"
        echo "  GITHUB_TOKEN: (default token should work)"
        echo "  PROJECTS_TOKEN: $GITHUB_TOKEN (if using cross-org projects)"
        echo
    done
    
    print_status "To add secrets, go to: https://github.com/OWNER/REPO/settings/secrets/actions"
}

# Validate configuration
validate_config() {
    print_status "Validating configuration..."
    
    if node -e "
        const { validateConfigFile } = require('./dist');
        const result = validateConfigFile('./config/routing.yml');
        if (!result.valid) {
            console.error('❌ Configuration validation failed:');
            result.errors.forEach(error => console.error('  -', error));
            process.exit(1);
        }
        console.log('✅ Configuration is valid');
    "; then
        print_success "Configuration validation passed"
    else
        print_error "Configuration validation failed"
        exit 1
    fi
}

# Test the setup
test_setup() {
    print_status "Testing the setup..."
    
    # Create a test issue data file
    cat > test-issue.json << EOF
{
  "title": "Test routing issue",
  "body": "This is a test issue to verify the routing system is working correctly.",
  "number": 1,
  "url": "https://github.com/$ROUTER_REPO/issues/1",
  "author": "test-user",
  "labels": ["test"],
  "assignees": [],
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "slackPermalink": null,
  "sourceMeta": {
    "repository": "test-router",
    "sender": "test-user",
    "action": "opened"
  }
}
EOF

    # Run a dry-run test
    if GITHUB_TOKEN="$GITHUB_TOKEN" OPENAI_API_KEY="$OPENAI_API_KEY" node -e "
        const { quickRoute } = require('./dist');
        const fs = require('fs');
        
        async function test() {
            try {
                const issueData = JSON.parse(fs.readFileSync('test-issue.json', 'utf8'));
                
                const result = await quickRoute(issueData, {
                    configPath: './config/routing.yml',
                    environment: 'development',
                    githubToken: process.env.GITHUB_TOKEN,
                    openaiApiKey: process.env.OPENAI_API_KEY,
                    routerRepo: '$ROUTER_REPO',
                    dryRun: true,
                    verbose: true
                });
                
                if (result.success || result.classification) {
                    console.log('✅ Dry run test passed');
                    console.log('Target repo:', result.classification.repo);
                    console.log('Confidence:', result.classification.confidence);
                    process.exit(0);
                } else {
                    console.error('❌ Dry run test failed:', result.error);
                    process.exit(1);
                }
            } catch (error) {
                console.error('❌ Test failed:', error.message);
                process.exit(1);
            }
        }
        
        test();
    "; then
        print_success "Dry run test passed"
    else
        print_error "Dry run test failed"
    fi
    
    # Clean up test file
    rm -f test-issue.json
}

# Main execution
main() {
    echo "=================================="
    echo "Issue Routing System Setup"
    echo "=================================="
    echo
    
    get_user_input
    check_prerequisites
    install_dependencies
    generate_config
    setup_workflows
    validate_config
    test_setup
    setup_secrets
    
    echo
    print_success "Setup completed successfully!"
    echo
    print_status "Next steps:"
    echo "1. Review and customize the generated configuration in config/routing.yml"
    echo "2. Add the required secrets to your repositories"
    echo "3. Copy workflows/triage.yml to your target repositories"
    echo "4. Create a test issue in the router repository to verify the setup"
    echo
    print_warning "Remember to customize the routing rules for your specific organization needs"
}

# Run main function
main "$@"