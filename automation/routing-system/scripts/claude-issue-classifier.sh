#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Claude Issue Classifier
# Based on ios-auto-fix claude-patch-generator.sh patterns
# Analyzes GitHub issues and generates classification with routing information
# =============================================================================

ISSUE_FILE="${1:-issue-data.json}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_FILE="${PROJECT_DIR}/classification-result.json"
TEMP_DIR="${PROJECT_DIR}/temp"
PROMPT_FILE="${TEMP_DIR}/classification-prompt.md"

# --- Colors for output ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

# Check prerequisites
check_prerequisites() {
    if [[ ! -f "$ISSUE_FILE" ]]; then
        log_error "Issue file not found: $ISSUE_FILE"
        return 1
    fi
    
    if ! command -v claude &> /dev/null; then
        log_error "Claude CLI not found. Please install it first."
        log_info "Install with: pip install claude-cli"
        return 1
    fi
    
    if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
        log_error "ANTHROPIC_API_KEY environment variable not set"
        return 1
    fi
    
    return 0
}

# Create temp directory
create_temp_dir() {
    mkdir -p "$TEMP_DIR"
}

# Load DELAX project information
load_delax_projects_info() {
    cat << 'EOF'
## DELAX Organization Projects

### MyProjects (iOS App)
- **Repository**: delax-org/myprojects-ios  
- **Tech Stack**: SwiftUI, SwiftData, CloudKit, UIKit
- **Domain**: Task management, productivity app
- **Common Issues**: Task creation bugs, SwiftData persistence, CloudKit sync, UI responsiveness
- **Team**: @ios-team-lead
- **Priority Keywords**: "task creation", "data loss", "sync issues", "crash"

### 100 Days Workout (iOS App)  
- **Repository**: delax-org/100-days-workout-ios
- **Tech Stack**: SwiftUI, CloudKit, HealthKit, Core Data
- **Domain**: Fitness tracking, health data
- **Common Issues**: HealthKit integration, CloudKit sharing, workout data sync
- **Team**: @ios-team-lead, @health-data-specialist
- **Priority Keywords**: "health data", "workout tracking", "sharing", "sync"

### DELAxPM (Web App)
- **Repository**: delax-org/delaxpm-web
- **Tech Stack**: React, TypeScript, Supabase, PostgreSQL
- **Domain**: Project management system
- **Common Issues**: Real-time collaboration, database performance, UI state management
- **Team**: @frontend-lead, @backend-lead
- **Priority Keywords**: "collaboration", "performance", "database", "real-time"

### DELAX Shared Packages (Development Tools)
- **Repository**: delax-org/delax-shared-packages
- **Tech Stack**: Swift, TypeScript, Python, Bash scripts
- **Domain**: Development automation, shared libraries
- **Common Issues**: Package integration, build system, automation failures
- **Team**: @dev-tools-lead, @automation-specialist  
- **Priority Keywords**: "build", "automation", "integration", "CI/CD"

### iOS Auto-Fix System
- **Repository**: delax-org/ios-auto-fix-tools
- **Tech Stack**: Bash, Claude API, Xcode toolchain
- **Domain**: Build error resolution, development automation
- **Common Issues**: Xcode build errors, API rate limiting, patch application
- **Team**: @automation-specialist
- **Priority Keywords**: "build error", "xcode", "patch", "compilation"
EOF
}

# Generate classification prompt based on ios-auto-fix patterns
generate_classification_prompt() {
    local issue_content
    issue_content=$(cat "$ISSUE_FILE")
    
    cat > "$PROMPT_FILE" << EOF
# GitHub Issue Classification for DELAX Organization

You are an expert at categorizing GitHub issues for the DELAX development organization. Your task is to analyze the issue content and route it to the appropriate repository with proper classification.

## Issue to Analyze
\`\`\`json
$issue_content
\`\`\`

$(load_delax_projects_info)

## Classification Instructions

Analyze the issue content and provide a JSON response with the following structure:

\`\`\`json
{
  "targetRepo": "delax-org/repository-name",
  "title": "Enhanced or refined issue title",
  "body": "Cleaned and structured issue body with proper formatting",
  "labels": ["label1", "label2", "label3"],
  "assignees": ["username1"],
  "priority": "low|medium|high|critical",
  "confidence": 0.85,
  "reasoning": "Detailed explanation of classification logic",
  "techStack": ["technology1", "technology2"],
  "category": "bug|feature|documentation|performance|security",
  "urgency": "immediate|high|normal|low",
  "estimatedTokens": {
    "input": 1200,
    "output": 300
  },
  "projectFields": {
    "Status": "Todo",
    "Priority": "High",
    "Size": "Medium"
  }
}
\`\`\`

## Classification Guidelines

### 1. Repository Selection
- **MyProjects iOS**: Task management, SwiftUI/SwiftData issues, iOS productivity features
- **100 Days Workout**: Fitness tracking, HealthKit, workout data, health-related features
- **DELAxPM Web**: Project management, React/TypeScript, web collaboration features
- **Shared Packages**: Development tools, build systems, shared libraries, automation
- **iOS Auto-Fix**: Build errors, Xcode issues, development automation problems

### 2. Priority Assessment
- **Critical**: App crashes, data loss, security vulnerabilities, production down
- **High**: Major features broken, significant user impact, blocked development
- **Medium**: Standard bugs, feature requests, non-blocking issues
- **Low**: UI polish, documentation, minor improvements

### 3. Urgency vs Priority
- **Urgency**: How quickly the issue needs attention
- **Priority**: How important the issue is to the business/users

### 4. Label Strategy
- **Type**: bug, feature, enhancement, documentation, question
- **Domain**: ios, web, mobile, backend, frontend, automation
- **Technology**: swiftui, swiftdata, cloudkit, react, typescript, supabase
- **Priority**: critical, high-priority, low-priority
- **Status**: needs-triage, in-progress, blocked, ready-for-review

### 5. Content Enhancement
- Fix typos and improve clarity
- Add missing technical context if obvious from the description
- Structure the content with proper markdown formatting
- Preserve the original meaning and user's voice
- Add relevant technical details if mentioned implicitly

### 6. Natural Language Processing
Handle casual language, Japanese/English mixed content, and "brain dump" style reports:
- Extract technical context from informal descriptions
- Identify implied technology stack from symptoms
- Translate user pain points to technical issues
- Maintain empathy while adding technical precision

### 7. Pattern Recognition
Look for common issue patterns:
- **"Button doesn't work but haptic feedback occurs"** → UI responsiveness + data persistence issue
- **"Data disappears after restart"** → Persistence/CloudKit sync issue
- **"Build fails after update"** → Xcode/dependency issue
- **"Slow performance on large datasets"** → Database/query optimization
- **"Users can't collaborate"** → Real-time sync/permission issue

### 8. API Usage Optimization
Estimate token usage for the classification to help with cost control:
- Input tokens: Approximate tokens used in this classification
- Output tokens: Approximate tokens in the response

## Response Format
Respond with valid JSON only, no additional text or markdown formatting.
EOF
}

# Call Claude API for classification
call_claude_api() {
    log_info "Calling Claude API for issue classification..."
    
    local max_retries=3
    local retry_count=0
    local claude_response=""
    
    while [[ $retry_count -lt $max_retries ]]; do
        if claude_response=$(claude chat --model "${CLAUDE_MODEL:-claude-4-sonnet-20250514}" \
                                        --max-tokens "${MAX_TOKENS:-4000}" \
                                        --temperature "${TEMPERATURE:-0.1}" \
                                        --file "$PROMPT_FILE" 2>&1); then
            break
        else
            retry_count=$((retry_count + 1))
            log_warning "Claude API call failed (attempt $retry_count/$max_retries): $claude_response"
            
            if [[ $retry_count -lt $max_retries ]]; then
                log_info "Retrying in 5 seconds..."
                sleep 5
            else
                log_error "Max retries reached. Classification failed."
                return 1
            fi
        fi
    done
    
    echo "$claude_response"
}

# Parse and validate Claude response
parse_claude_response() {
    local claude_output="$1"
    
    # Extract JSON from the response (Claude sometimes wraps it in markdown)
    local json_content=""
    if json_content=$(echo "$claude_output" | grep -A 1000 '{' | grep -B 1000 '}' | head -1); then
        log_info "Extracted JSON content from Claude response"
    else
        log_error "Could not extract JSON from Claude response"
        log_error "Claude output: $claude_output"
        return 1
    fi
    
    # Validate JSON structure
    if ! echo "$json_content" | jq . > /dev/null 2>&1; then
        log_error "Invalid JSON in Claude response"
        log_error "JSON content: $json_content"
        return 1
    fi
    
    # Validate required fields
    local required_fields=("targetRepo" "title" "body" "labels" "priority" "confidence" "reasoning")
    for field in "${required_fields[@]}"; do
        if ! echo "$json_content" | jq -e ".$field" > /dev/null 2>&1; then
            log_error "Missing required field: $field"
            return 1
        fi
    done
    
    # Save the validated result
    echo "$json_content" | jq . > "$OUTPUT_FILE"
    log_success "Classification result saved to $OUTPUT_FILE"
    
    return 0
}

# Generate classification report
generate_report() {
    if [[ ! -f "$OUTPUT_FILE" ]]; then
        log_error "Classification result file not found"
        return 1
    fi
    
    local repo target_repo priority confidence reasoning
    repo=$(jq -r '.targetRepo' "$OUTPUT_FILE")
    priority=$(jq -r '.priority' "$OUTPUT_FILE")
    confidence=$(jq -r '.confidence' "$OUTPUT_FILE")
    reasoning=$(jq -r '.reasoning' "$OUTPUT_FILE")
    
    log_success "🎯 Classification Complete"
    log_info "Repository: $repo"
    log_info "Priority: $priority"
    log_info "Confidence: $(echo "$confidence * 100" | bc -l | cut -d. -f1)%"
    log_info "Reasoning: $reasoning"
    
    # Display token usage if available
    if jq -e '.estimatedTokens' "$OUTPUT_FILE" > /dev/null 2>&1; then
        local input_tokens output_tokens
        input_tokens=$(jq -r '.estimatedTokens.input' "$OUTPUT_FILE")
        output_tokens=$(jq -r '.estimatedTokens.output' "$OUTPUT_FILE")
        log_info "Token Usage: ~$input_tokens input + ~$output_tokens output tokens"
    fi
}

# Cleanup temporary files
cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Main execution
main() {
    log_info "🤖 Starting Claude Issue Classification"
    log_info "Issue file: $ISSUE_FILE"
    log_info "Model: ${CLAUDE_MODEL:-claude-4-sonnet-20250514}"
    
    # Setup
    if ! check_prerequisites; then
        exit 1
    fi
    
    create_temp_dir
    trap cleanup EXIT
    
    # Generate classification prompt
    log_info "Generating classification prompt..."
    generate_classification_prompt
    
    # Call Claude API
    local claude_response
    if claude_response=$(call_claude_api); then
        log_success "Claude API call successful"
    else
        log_error "Claude API call failed"
        exit 1
    fi
    
    # Parse and validate response
    if parse_claude_response "$claude_response"; then
        generate_report
        log_success "✅ Issue classification completed successfully"
    else
        log_error "Failed to parse Claude response"
        exit 1
    fi
}

# Error handling
set -o errtrace
error_handler() {
    local line_number=$1
    log_error "Script failed at line $line_number"
    cleanup
    exit 1
}
trap 'error_handler $LINENO' ERR

# Execute main function
main "$@"