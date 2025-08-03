#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Claude Code Patch Generator
# ビルドエラーからClaude Code CLIを使ってパッチを生成
# =============================================================================

ERROR_FILE="${1:-builderror/errors.txt}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
    if [[ ! -f "$ERROR_FILE" ]]; then
        log_error "Error file not found: $ERROR_FILE"
        return 1
    fi
    
    if ! command -v claude &> /dev/null; then
        log_error "Claude CLI not found. Please install it first."
        log_info "Install with: pip install claude-cli"
        return 1
    fi
    
    return 0
}

# Generate project context for Claude
generate_project_context() {
    cat << EOF
# MyProjects iOS App - Claude 4 Sonnet Context

You are Claude 4 Sonnet analyzing a sophisticated iOS app built with modern Swift technologies.

## 🏗️ Architecture Overview
- **Platform**: iOS 17.0+ with Swift 5.9+
- **UI Framework**: SwiftUI with strict MVVM architecture
- **Data Layer**: SwiftData + CloudKit (local-first with cloud sync)
- **AI Integration**: OpenAI API for task breakdown + Apple Intelligence (future)
- **Apple Integration**: EventKit for bidirectional Apple Reminders sync

## 📁 Project Structure
\`\`\`
Myprojects/Myprojects/
├── Features/           # Feature-based modules
│   ├── Home/          # Project list, quick add
│   ├── ProjectDetail/ # Project management
│   ├── TaskDetail/    # Task editing
│   └── BugReport/     # Debug & feedback
├── Models/Core/       # SwiftData entities
│   ├── Project.swift  # @Model with CloudKit
│   ├── Task.swift     # Hierarchical tasks
│   └── AIContext.swift # AI learning data
├── Services/          # Business logic layer
│   ├── Data/          # DataManager
│   └── Import/        # JSON import service
└── Shared/           # Reusable components
    ├── Components/   # UI components
    └── Extensions/   # View extensions
\`\`\`

## 🎯 Key SwiftData Models
\`\`\`swift
@Model class Project {
    var id: UUID
    var title: String
    var tasks: [Task]
    var aiContext: AIContext?
    // CloudKit: @Attribute(.externalStorage)
}

@Model class Task {  
    var id: UUID
    var title: String
    var isCompleted: Bool
    var project: Project?
    var subtasks: [Task]
    var parentTask: Task?
    // Hierarchical relationships
}
\`\`\`

## 🔧 Common Patterns & Best Practices
- **@Model**: All data entities use SwiftData
- **@StateObject**: ViewModels in SwiftUI views
- **@Query**: SwiftData queries in views
- **MVVM**: Strict separation (View → ViewModel → Service)
- **CloudKit**: Optimistic UI with background sync
- **Error Handling**: Result types with proper error propagation

## ⚠️ Build Errors Analysis Required:
EOF
}

# Generate Claude prompt for error fixing
generate_claude_prompt() {
    local error_content
    error_content=$(cat "$ERROR_FILE")
    
    cat << EOF
$(generate_project_context)

$error_content

## 🎯 Your Mission (Claude 4 Sonnet)

Analyze these build errors with your advanced reasoning capabilities and generate precise Swift fixes.

### 🔍 Analysis Framework
1. **Root Cause Identification**: What's the underlying issue?
2. **SwiftUI/SwiftData Patterns**: Property wrappers, data flow, relationships
3. **Architecture Compliance**: Maintain MVVM, respect layer boundaries  
4. **Impact Assessment**: Consider side effects and dependencies

### 🛠️ Fix Requirements
- **Format**: Unified diff patches for \`git apply\`
- **Scope**: Minimal changes, surgical precision
- **Compatibility**: iOS 17.0+, Swift 5.9+, SwiftUI patterns
- **Quality**: Production-ready, follows Apple HIG

### 🧠 Advanced Considerations
- **SwiftData Relationships**: Preserve @Relationship integrity
- **CloudKit Sync**: Maintain CKRecord compatibility  
- **State Management**: Proper @State/@StateObject usage
- **Performance**: Avoid unnecessary view updates
- **Testing**: Ensure changes don't break existing functionality

### 📋 Error Categories to Address
- **Compiler Errors**: Type mismatches, missing declarations
- **SwiftUI Issues**: Binding problems, view lifecycle, navigation
- **SwiftData Issues**: Model relationships, query syntax, migrations
- **Import/Dependency**: Missing modules, package resolution
- **Build System**: Linking, resources, code signing

Generate clean, production-ready patches that respect the existing codebase architecture.
EOF
}

# Generate patch using Claude CLI
generate_patch() {
    log_info "Generating patch with Claude Code CLI..."
    
    local prompt_file="/tmp/claude_prompt.txt"
    local response_file="/tmp/claude_response.txt"
    
    # Create prompt
    generate_claude_prompt > "$prompt_file"
    
    # Call Claude CLI with Claude 4 Sonnet (Claude Max)
    if claude --model claude-4-sonnet-20250514 --input "$prompt_file" --output "$response_file" 2>/dev/null; then
        # Extract patch from response
        if grep -q "diff --git\|@@\|+++\|---" "$response_file"; then
            # Response contains a patch
            cat "$response_file"
            log_success "Patch generated successfully" >&2
        else
            # Response is explanation/code, convert to patch format
            log_warning "Response doesn't contain patch format, processing..." >&2
            process_code_response "$response_file"
        fi
    else
        log_error "Failed to call Claude CLI"
        return 1
    fi
    
    # Cleanup
    rm -f "$prompt_file" "$response_file"
}

# Process code response and convert to patch
process_code_response() {
    local response_file="$1"
    
    log_info "Processing code response to generate patch..."
    
    # Try to extract Swift code blocks
    if grep -q "```swift" "$response_file"; then
        log_info "Found Swift code blocks, attempting to create patch..."
        
        # This is a simplified approach - in practice, you might want to
        # parse the response more carefully and match against existing files
        awk '
        /```swift/ {in_code=1; next}
        /```/ {in_code=0; next}
        in_code {print}
        ' "$response_file" > /tmp/suggested_code.swift
        
        if [[ -s /tmp/suggested_code.swift ]]; then
            log_info "Generated suggested code, manual review required"
            cat /tmp/suggested_code.swift
        else
            log_warning "No Swift code extracted from response"
            cat "$response_file"
        fi
    else
        log_warning "No code blocks found, showing raw response"
        cat "$response_file"
    fi
}

# Enhanced error context gathering
gather_error_context() {
    log_info "Gathering additional error context..."
    
    # Read error file and extract file paths for context
    local files_with_errors=()
    while IFS='|' read -r error_type location message; do
        if [[ "$location" =~ ^([^:]+): ]]; then
            local filename="${BASH_REMATCH[1]}"
            files_with_errors+=("$filename")
        fi
    done < "$ERROR_FILE"
    
    # Remove duplicates
    local unique_files=($(printf "%s\n" "${files_with_errors[@]}" | sort -u))
    
    # Add file context to prompt
    for file in "${unique_files[@]}"; do
        if [[ -f "$PROJECT_DIR/Myprojects/Myprojects/$file" ]]; then
            echo "" >&2
            echo "Context for $file:" >&2
            head -50 "$PROJECT_DIR/Myprojects/Myprojects/$file" >&2
        fi
    done
}

# Main execution
main() {
    log_info "Starting Claude patch generation..."
    log_info "Error file: $ERROR_FILE"
    
    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi
    
    # Gather additional context
    gather_error_context
    
    # Generate and output patch
    if ! generate_patch; then
        log_error "Failed to generate patch"
        exit 1
    fi
    
    log_success "Patch generation completed"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi