# Example: Setting up iOS Auto-Fix for MyProject

This example shows how to set up iOS Auto-Fix for a typical SwiftUI project.

## Project Structure
```
MyProject/
├── MyProject.xcodeproj
├── MyProject/
│   ├── Sources/
│   │   ├── Views/
│   │   ├── Models/
│   │   └── Services/
│   └── Resources/
├── auto-fix-config.yml          # Configuration file
├── scripts/                     # Auto-fix scripts
└── .github/workflows/           # GitHub Actions
```

## Setup Steps

### 1. Install iOS Auto-Fix
```bash
npm install -g @delax/ios-auto-fix
```

### 2. Initialize Configuration
```bash
cd MyProject
ios-auto-fix setup
```

### 3. Customize Configuration
Edit `auto-fix-config.yml`:

```yaml
# MyProject iOS Auto-Fix Configuration
project:
  name: "MyProject"
  xcode_project: "MyProject.xcodeproj"
  scheme: "MyProject"
  configuration: "Debug"
  target_platform: "iOS Simulator"
  target_device: "iPhone 16"
  ios_version: "latest"

build:
  max_attempts: 3
  timeout_seconds: 300
  clean_before_build: true

claude:
  model: "claude-4-sonnet-20250514"
  context:
    include_project_structure: true
    include_related_files: true
    max_context_files: 8

watch:
  directories:
    - "MyProject/Sources"
    - "MyProject/Views" 
    - "MyProject/Models"
    - "MyProject/Services"
  
  debounce_seconds: 2
  max_events_per_minute: 8

project_rules:
  swiftui:
    fix_binding_issues: true
    handle_state_management: true
    fix_navigation_issues: true
```

### 4. Copy Scripts (if not using npm global install)
```bash
# Copy from installed package
cp -r $(npm root -g)/@delax/ios-auto-fix/Scripts ./scripts
chmod +x scripts/*.sh
```

### 5. Set Up Environment
```bash
# Install Claude CLI
pip install claude-cli

# Set API key
export ANTHROPIC_API_KEY="your-api-key-here"
```

## Usage Examples

### One-time Fix
```bash
# Fix current build errors
./scripts/auto-build-fix.sh
```

### Watch Mode
```bash
# Continuously monitor and fix
./scripts/watch-and-fix.sh
```

### Custom Configuration
```bash
# Use specific config file
./scripts/auto-build-fix.sh --config custom-config.yml
```

## GitHub Actions Setup

Create `.github/workflows/ios-auto-fix.yml`:

```yaml
name: iOS Auto Build & Fix

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'MyProject/**/*.swift'
      - 'MyProject/**/*.plist'
  pull_request:
    branches: [ main ]

env:
  XCODE_VERSION: '16.2'
  IOS_SIMULATOR_DEVICE: 'iPhone 16'
  IOS_SIMULATOR_VERSION: '18.5'
  PROJECT_NAME: 'MyProject'
  XCODE_PROJECT: 'MyProject.xcodeproj'
  SCHEME: 'MyProject'

jobs:
  auto-build-fix:
    runs-on: macos-15
    timeout-minutes: 30
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
      with:
        fetch-depth: 0
        token: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: ${{ env.XCODE_VERSION }}
    
    - name: Install iOS Auto-Fix
      run: |
        npm install -g @delax/ios-auto-fix
        pip3 install claude-cli
    
    - name: Setup iOS Simulator
      run: |
        xcrun simctl boot "${{ env.IOS_SIMULATOR_DEVICE }}" || echo "Already booted"
        sleep 10
    
    - name: Run Auto Build & Fix
      run: |
        ios-auto-fix
      env:
        ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
    
    - name: Commit fixes if successful
      run: |
        if git diff --quiet; then
          echo "No changes to commit"
          exit 0
        fi
        
        git config --local user.email "action@github.com"
        git config --local user.name "iOS Auto-Fix Bot"
        git add .
        git commit -m "🤖 Auto-fix build errors with Claude 4 Sonnet"
        git push origin ${{ github.ref_name }}
```

## Common Scenarios

### Scenario 1: SwiftUI Binding Error
**Error:**
```
ContentView.swift:25:18: error: Cannot convert value of type 'Binding<String>' to expected argument type 'String'
```

**Auto-Fix Result:**
```diff
- Text(title)
+ Text($title.wrappedValue)
```

### Scenario 2: Missing Import
**Error:**
```
ViewModel.swift:5:8: error: No such module 'Combine'
```

**Auto-Fix Result:**
```diff
+ import Combine
  import SwiftUI
```

### Scenario 3: State Management Issue
**Error:**
```
HomeView.swift:15:9: error: @State can only be applied to var declarations
```

**Auto-Fix Result:**
```diff
- @State let isLoading: Bool = false
+ @State var isLoading: Bool = false
```

## Tips & Best Practices

### 1. Project Context Enhancement
Add project-specific context to improve fix quality:

```yaml
claude:
  prompts:
    system_context: |
      You are working on MyProject - a fitness tracking iOS app.
      
      Architecture: SwiftUI + Core Data + MVVM
      Key Features: Workout tracking, health data sync
      
      Maintain patterns:
      - Use @StateObject for view models
      - Core Data entities have @NSManaged properties
      - Follow Apple HIG for UI components
```

### 2. Selective Error Handling
Focus on specific error types:

```yaml
error_detection:
  enabled_types:
    - swift_compiler    # Focus on Swift errors
    - swiftui_specific  # SwiftUI-specific issues
  ignore_patterns:
    - "warning:.*deprecated"  # Ignore deprecation warnings
```

### 3. Watch Mode Optimization
Optimize for your development workflow:

```yaml
watch:
  directories:
    - "MyProject/Sources/Views"     # UI code
    - "MyProject/Sources/ViewModels" # Business logic
  exclude_patterns:
    - "*.xcuserstate"  # Ignore Xcode state files
    - "*/Build/*"      # Ignore build artifacts
  debounce_seconds: 3  # Prevent excessive builds
```

## Troubleshooting

### Common Issues

1. **Claude CLI not found**
   ```bash
   pip install claude-cli
   export PATH=$PATH:~/.local/bin
   ```

2. **Permission denied**
   ```bash
   chmod +x scripts/*.sh
   ```

3. **Config file not found**
   ```bash
   # Ensure config is in project root
   ls -la auto-fix-config.yml
   ```

4. **API rate limits**
   ```yaml
   # Reduce parallel requests
   performance:
     max_concurrent_fixes: 1
   ```

### Debug Mode
```bash
# Enable verbose logging
VERBOSE=1 ./scripts/auto-build-fix.sh

# Dry run mode
./scripts/watch-and-fix.sh --dry-run
```

## Success Metrics

After setup, you should see:
- ✅ Faster development cycles
- ✅ Fewer manual error fixes
- ✅ Consistent code quality
- ✅ Reduced build failures in CI

## Next Steps

1. **Monitor Performance**: Check `build-fix-stats.json` for insights
2. **Customize Prompts**: Tailor Claude prompts for your project
3. **Team Training**: Share configuration and best practices
4. **CI Integration**: Enable auto-commit for successful fixes

---

**Ready to accelerate your iOS development with AI?** 🚀

> This example is part of the [iOS Auto-Fix System](https://github.com/DELAxGithub/delax-shared-packages/tree/main/native-tools/ios-auto-fix)