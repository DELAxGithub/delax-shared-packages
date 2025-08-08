#!/bin/bash

# Test script for the Issue Routing System
# This script tests various routing scenarios to verify the system works correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Run a single test
run_test() {
    local test_name="$1"
    local test_file="$2"
    local expected_repo="$3"
    
    print_status "Running test: $test_name"
    
    if GITHUB_TOKEN="${GITHUB_TOKEN:-dummy-token}" node -e "
        const { quickRoute } = require('./dist');
        const fs = require('fs');
        
        async function test() {
            try {
                const issueData = JSON.parse(fs.readFileSync('$test_file', 'utf8'));
                
                const result = await quickRoute(issueData, {
                    configPath: './config/routing.yml',
                    githubToken: process.env.GITHUB_TOKEN,
                    routerRepo: 'test-org/router',
                    dryRun: true,
                    verbose: false
                });
                
                if (!result.classification) {
                    throw new Error('No classification result');
                }
                
                console.log('Target repo:', result.classification.repo);
                console.log('Confidence:', result.classification.confidence);
                console.log('Labels:', result.classification.labels.join(', '));
                console.log('Priority:', result.classification.priority);
                
                if ('$expected_repo' && result.classification.repo !== '$expected_repo') {
                    throw new Error(\`Expected repo '$expected_repo', got '\${result.classification.repo}'\`);
                }
                
                process.exit(0);
            } catch (error) {
                console.error('Test failed:', error.message);
                process.exit(1);
            }
        }
        
        test();
    " > /dev/null 2>&1; then
        print_success "$test_name"
        ((TESTS_PASSED++))
    else
        print_error "$test_name"
        ((TESTS_FAILED++))
    fi
}

# Create test issue data
create_test_data() {
    print_status "Creating test data..."
    
    # iOS issue
    cat > test-ios-issue.json << EOF
{
  "title": "SwiftUI CloudKit sync issue",
  "body": "I'm having trouble with CloudKit synchronization in my SwiftUI app. The Core Data entities are not syncing properly between devices.",
  "number": 1,
  "url": "https://github.com/test-org/router/issues/1",
  "author": "ios-developer",
  "labels": ["bug"],
  "assignees": [],
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "slackPermalink": null,
  "sourceMeta": {
    "channel": "#ios-dev",
    "repository": "router"
  }
}
EOF

    # Backend API issue
    cat > test-backend-issue.json << EOF
{
  "title": "PostgreSQL connection timeout",
  "body": "The API is experiencing frequent PostgreSQL connection timeouts. We need to investigate the connection pool configuration in our Supabase setup.",
  "number": 2,
  "url": "https://github.com/test-org/router/issues/2",
  "author": "backend-developer",
  "labels": ["bug", "api"],
  "assignees": [],
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "slackPermalink": "https://delax.slack.com/archives/C1234567/p1234567890",
  "sourceMeta": {
    "channel": "#backend",
    "repository": "router"
  }
}
EOF

    # Frontend component issue
    cat > test-frontend-issue.json << EOF
{
  "title": "React component not responsive on mobile",
  "body": "The header component is not displaying correctly on mobile devices. The responsive CSS needs to be fixed.",
  "number": 3,
  "url": "https://github.com/test-org/router/issues/3",
  "author": "frontend-developer",
  "labels": ["bug", "ui"],
  "assignees": [],
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "slackPermalink": null,
  "sourceMeta": {
    "channel": "#frontend",
    "repository": "router"
  }
}
EOF

    # Security issue
    cat > test-security-issue.json << EOF
{
  "title": "Vulnerability in authentication system",
  "body": "Found a potential security vulnerability in our authentication system. This needs immediate attention.",
  "number": 4,
  "url": "https://github.com/test-org/router/issues/4",
  "author": "security-researcher",
  "labels": ["security", "critical"],
  "assignees": [],
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "slackPermalink": null,
  "sourceMeta": {
    "repository": "router"
  }
}
EOF

    # Documentation request
    cat > test-docs-issue.json << EOF
{
  "title": "Update API documentation",
  "body": "The API documentation is outdated and needs to be updated with the latest endpoints and examples.",
  "number": 5,
  "url": "https://github.com/test-org/router/issues/5",
  "author": "tech-writer",
  "labels": ["documentation"],
  "assignees": [],
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "slackPermalink": null,
  "sourceMeta": {
    "channel": "#docs",
    "repository": "router"
  }
}
EOF

    # Generic feature request
    cat > test-feature-issue.json << EOF
{
  "title": "Add user analytics dashboard",
  "body": "We need to implement a user analytics dashboard to track user engagement and usage patterns.",
  "number": 6,
  "url": "https://github.com/test-org/router/issues/6",
  "author": "product-manager",
  "labels": ["feature", "enhancement"],
  "assignees": [],
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "slackPermalink": null,
  "sourceMeta": {
    "repository": "router"
  }
}
EOF
}

# Create test configuration
create_test_config() {
    print_status "Creating test configuration..."
    
    cat > config/test-routing.yml << EOF
defaults:
  repo: "test-org/inbox"
  labels:
    - "triage"
    - "auto-routed"

llm:
  model: "claude-3-sonnet"
  maxTokens: 2000
  temperature: 0.1

duplicateDetection:
  enabled: true
  method: "both"
  lookbackDays: 30

rules:
  - when:
      channels: ["#ios-dev", "#ios", "#mobile-dev"]
      keywords: ["SwiftUI", "CloudKit", "iOS", "Xcode", "Swift", "UIKit", "Core Data"]
    route:
      repo: "test-org/ios-app"
      labels: ["ios", "mobile"]
      assignees: ["ios-team-lead"]
      priority: "high"
      projectFields:
        Status: "Todo"
        Platform: "iOS"

  - when:
      channels: ["#backend", "#api", "#server"]
      keywords: ["API", "Supabase", "PostgreSQL", "Node.js", "TypeScript", "backend"]
    route:
      repo: "test-org/backend-services"
      labels: ["backend", "api"]
      assignees: ["backend-team-lead"]
      priority: "medium"

  - when:
      channels: ["#frontend", "#web", "#ui-ux"]
      keywords: ["React", "Vue", "Angular", "CSS", "HTML", "responsive", "component"]
    route:
      repo: "test-org/web-frontend"
      labels: ["frontend", "ui"]
      assignees: ["frontend-team-lead"]
      priority: "medium"

  - when:
      keywords: ["security", "vulnerability", "authentication", "authorization"]
      labels: ["security"]
    route:
      repo: "test-org/security"
      labels: ["security", "critical"]
      assignees: ["security-team-lead"]
      priority: "critical"

  - when:
      channels: ["#docs", "#documentation"]
      keywords: ["documentation", "README", "guide", "tutorial", "wiki"]
      labels: ["documentation"]
    route:
      repo: "test-org/documentation"
      labels: ["documentation", "content"]
      assignees: ["tech-writer"]
      priority: "low"

  - when:
      keywords: ["feature", "enhancement", "improvement"]
      labels: ["feature", "enhancement"]
    route:
      repo: "test-org/feature-requests"
      labels: ["feature", "enhancement"]
      priority: "medium"
EOF
}

# Validate configuration
validate_configuration() {
    print_status "Validating test configuration..."
    
    if node -e "
        const { validateConfigFile } = require('./dist');
        const result = validateConfigFile('./config/test-routing.yml');
        if (!result.valid) {
            console.error('Configuration validation failed:', result.errors.join(', '));
            process.exit(1);
        }
        console.log('Configuration is valid');
    "; then
        print_success "Configuration validation passed"
    else
        print_error "Configuration validation failed"
        exit 1
    fi
}

# Run all tests
run_all_tests() {
    print_status "Running routing tests..."
    
    # Use test configuration
    cp config/routing.yml config/routing.yml.backup 2>/dev/null || true
    cp config/test-routing.yml config/routing.yml
    
    # Run tests
    run_test "iOS Issue Routing" "test-ios-issue.json" "test-org/ios-app"
    run_test "Backend Issue Routing" "test-backend-issue.json" "test-org/backend-services"
    run_test "Frontend Issue Routing" "test-frontend-issue.json" "test-org/web-frontend"
    run_test "Security Issue Routing" "test-security-issue.json" "test-org/security"
    run_test "Documentation Issue Routing" "test-docs-issue.json" "test-org/documentation"
    run_test "Feature Request Routing" "test-feature-issue.json" "test-org/feature-requests"
    
    # Restore original configuration
    if [[ -f config/routing.yml.backup ]]; then
        mv config/routing.yml.backup config/routing.yml
    else
        rm -f config/routing.yml
    fi
}

# Clean up test files
cleanup() {
    print_status "Cleaning up test files..."
    
    rm -f test-*-issue.json
    rm -f config/test-routing.yml
    
    print_success "Cleanup completed"
}

# Print test results
print_results() {
    echo
    echo "=================================="
    echo "Test Results"
    echo "=================================="
    echo
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo "Total tests: $((TESTS_PASSED + TESTS_FAILED))"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        print_success "All tests passed! 🎉"
        exit 0
    else
        print_error "Some tests failed. Please check the configuration and try again."
        exit 1
    fi
}

# Main execution
main() {
    echo "=================================="
    echo "Issue Routing System - Test Suite"
    echo "=================================="
    echo
    
    # Check if built
    if [[ ! -d "dist" ]]; then
        print_error "Project not built. Run 'npm run build' first."
        exit 1
    fi
    
    create_test_data
    create_test_config
    validate_configuration
    run_all_tests
    cleanup
    print_results
}

# Handle script interruption
trap cleanup EXIT

# Run main function
main "$@"