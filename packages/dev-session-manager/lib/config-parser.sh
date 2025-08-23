#!/bin/bash

# 📄 Configuration Parser Library
# Provides functions to read and parse dev-session-config.json

CONFIG_FILE="dev-session-config.json"
DEFAULT_CONFIG_FILE=""

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if jq is available
check_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        echo -e "${RED}[ERROR]${NC} jq is required but not installed."
        echo "Install jq: https://stedolan.github.io/jq/download/"
        exit 1
    fi
}

# Find configuration file
find_config() {
    local search_path="${1:-.}"
    
    # Look for config file in current dir, then parent dirs
    local current_dir="$search_path"
    while [ "$current_dir" != "/" ]; do
        if [ -f "$current_dir/$CONFIG_FILE" ]; then
            echo "$current_dir/$CONFIG_FILE"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
    done
    
    echo ""
    return 1
}

# Load configuration or exit with error
load_config() {
    local config_path
    config_path=$(find_config)
    
    if [ -z "$config_path" ]; then
        echo -e "${RED}[ERROR]${NC} Configuration file not found: $CONFIG_FILE"
        echo "Run ./lib/project-detector.sh to generate configuration"
        exit 1
    fi
    
    DEFAULT_CONFIG_FILE="$config_path"
    check_jq
}

# Get configuration value by JSON path
get_config() {
    local json_path="$1"
    local default_value="${2:-null}"
    
    if [ -z "$DEFAULT_CONFIG_FILE" ]; then
        load_config
    fi
    
    local result
    result=$(jq -r "$json_path // \"$default_value\"" "$DEFAULT_CONFIG_FILE" 2>/dev/null)
    
    if [ "$result" = "null" ] || [ -z "$result" ]; then
        echo "$default_value"
    else
        echo "$result"
    fi
}

# Get array values from configuration
get_config_array() {
    local json_path="$1"
    
    if [ -z "$DEFAULT_CONFIG_FILE" ]; then
        load_config
    fi
    
    jq -r "$json_path[]?" "$DEFAULT_CONFIG_FILE" 2>/dev/null || echo ""
}

# Project configuration getters
get_project_name() {
    get_config ".project.name" "MyProject"
}

get_project_type() {
    get_config ".project.type" "unknown"
}

get_source_dirs() {
    get_config_array ".project.source_dirs"
}

get_build_command() {
    get_config ".project.build_command" "make build"
}

get_test_command() {
    get_config ".project.test_command" "make test"
}

# Tracking configuration getters
get_progress_file() {
    get_config ".tracking.progress_file" "PROGRESS_UNIFIED.md"
}

get_session_template() {
    get_config ".tracking.session_template" "SESSION_TEMPLATE.md"
}

get_backup_dir() {
    get_config ".tracking.backup_dir" ".progress_backup"
}

get_archive_dir() {
    get_config ".tracking.archive_dir" "docs/progress_archive"
}

# Stats configuration getters
get_file_extensions() {
    get_config_array ".stats.file_extensions"
}

get_exclude_dirs() {
    get_config_array ".stats.exclude_dirs"
}

get_metrics() {
    get_config_array ".stats.metrics"
}

get_todo_patterns() {
    get_config_array ".stats.todo_patterns"
}

# Validation functions
validate_config() {
    local config_path
    config_path=$(find_config)
    
    if [ -z "$config_path" ]; then
        echo -e "${RED}[ERROR]${NC} No configuration file found"
        return 1
    fi
    
    check_jq
    
    # Validate JSON syntax
    if ! jq empty "$config_path" 2>/dev/null; then
        echo -e "${RED}[ERROR]${NC} Invalid JSON in configuration file: $config_path"
        return 1
    fi
    
    # Validate required fields
    local project_name
    project_name=$(get_config ".project.name" "")
    if [ -z "$project_name" ]; then
        echo -e "${YELLOW}[WARNING]${NC} Missing project.name in configuration"
    fi
    
    local project_type
    project_type=$(get_config ".project.type" "")
    if [ -z "$project_type" ]; then
        echo -e "${YELLOW}[WARNING]${NC} Missing project.type in configuration"
    fi
    
    echo "Configuration validated successfully"
    return 0
}

# Print current configuration summary
print_config_summary() {
    echo "📋 Configuration Summary"
    echo "======================="
    echo "Project Name: $(get_project_name)"
    echo "Project Type: $(get_project_type)"
    echo "Progress File: $(get_progress_file)"
    echo "Build Command: $(get_build_command)"
    echo "Test Command: $(get_test_command)"
    echo ""
    echo "Source Directories:"
    get_source_dirs | while IFS= read -r dir; do
        [ -n "$dir" ] && echo "  - $dir"
    done
    echo ""
    echo "File Extensions:"
    get_file_extensions | while IFS= read -r ext; do
        [ -n "$ext" ] && echo "  - $ext"
    done
}

# Export functions for use in other scripts
export -f check_jq find_config load_config get_config get_config_array
export -f get_project_name get_project_type get_source_dirs get_build_command get_test_command
export -f get_progress_file get_session_template get_backup_dir get_archive_dir
export -f get_file_extensions get_exclude_dirs get_metrics get_todo_patterns
export -f validate_config print_config_summary