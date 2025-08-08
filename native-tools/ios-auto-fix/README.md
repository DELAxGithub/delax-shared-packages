# 🔧 iOS Auto Build & Fix System

Universal iOS project build error auto-fix system powered by **Claude 4 Sonnet**. Transform your iOS development workflow from manual error fixing to intelligent automation.

![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue)
![Xcode](https://img.shields.io/badge/Xcode-15.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![Claude](https://img.shields.io/badge/Claude-4%20Sonnet-purple)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

- 🤖 **AI-Powered Fixes**: Claude 4 Sonnet analyzes and fixes build errors automatically
- 🔄 **Watch Mode**: Continuous monitoring with file change detection
- 🛡️ **Safe Patching**: Git-based backup and rollback system
- 🎯 **Multi-Error Support**: Swift, SwiftUI, Build System, Import, Code Signing errors
- 📊 **GitHub Actions**: CI/CD integration with auto-commit and issue creation
- ⚙️ **Configurable**: YAML-based configuration for any iOS project

## 🚀 Quick Start

### Installation

```bash
# Via npm (recommended)
npm install -g @delax/ios-auto-fix

# Or clone directly
git clone https://github.com/DELAxGithub/delax-shared-packages.git
cd delax-shared-packages/native-tools/ios-auto-fix
```

### Setup

1. **Copy configuration template:**
   ```bash
   npm run setup
   # or manually:
   cp Templates/auto-fix-config.yml ./auto-fix-config.yml
   ```

2. **Customize for your project:**
   ```yaml
   project:
     name: "YourProject"
     xcode_project: "YourProject.xcodeproj" 
     scheme: "YourScheme"
   ```

3. **Install Claude CLI:**
   ```bash
   pip install claude-cli
   # Set your API key
   export ANTHROPIC_API_KEY="your-api-key"
   ```

### Usage

```bash
# One-time fix
ios-auto-fix

# Continuous watch mode
ios-watch-fix

# With custom config
ios-auto-fix --config path/to/config.yml
```

## 📖 Complete Documentation

- **[Setup Guide](Documentation/README-AutoBuildFix.md)** - Detailed installation and configuration
- **[Configuration Reference](Templates/auto-fix-config.yml)** - All configuration options
- **[GitHub Actions Integration](Workflows/auto-build-fix.yml)** - CI/CD setup
- **[Examples](Examples/)** - Real-world usage examples

## 🛠️ System Components

### Core Scripts
- **`auto-build-fix.sh`** - Main automation engine
- **`extract-xcode-errors.sh`** - Error analysis and categorization
- **`claude-patch-generator.sh`** - AI-powered patch generation
- **`safe-patch-apply.sh`** - Safe patching with rollback
- **`watch-and-fix.sh`** - File monitoring and continuous fixes

### Supported Error Types
- ✅ Swift Compiler Errors
- ✅ SwiftUI Specific Issues  
- ✅ Build System Problems
- ✅ Import/Module Errors
- ✅ Code Signing Issues
- ✅ Critical Warnings

## ⚙️ Configuration

Customize behavior via `auto-fix-config.yml`:

```yaml
project:
  name: "MyAwesomeApp"
  xcode_project: "MyAwesomeApp.xcodeproj"
  scheme: "MyAwesomeApp"
  
build:
  max_attempts: 5
  timeout_seconds: 300
  
claude:
  model: "claude-4-sonnet-20250514"
  
watch:
  directories:
    - "MyAwesomeApp/Sources"
    - "MyAwesomeApp/Views"
```

## 🤖 GitHub Actions Integration

Add to `.github/workflows/auto-build-fix.yml`:

```yaml
name: iOS Auto Build & Fix
on:
  push:
    paths: [ 'YourProject/**/*.swift' ]

jobs:
  auto-build-fix:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - name: Run iOS Auto-Fix
        run: |
          npm install -g @delax/ios-auto-fix
          ios-auto-fix
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

## 📊 Performance & Safety

### Built-in Safety Features
- 🔄 **Git Backup**: Automatic stashing before patches
- 🎯 **Dry Run**: Test patches before application
- 🚫 **Rollback**: Automatic revert on failures
- 🔍 **Validation**: Syntax checking and verification

### Performance Optimizations
- ⚡ **Debounced Watching**: Prevents excessive builds
- 🎭 **Smart Filtering**: Ignores temporary/cache files
- 🧠 **Context-Aware**: Claude 4 Sonnet with project context
- 📊 **Statistics**: Performance metrics collection

## 🔧 Advanced Usage

### Custom Error Patterns
```yaml
error_detection:
  ignore_patterns:
    - "warning:.*deprecated"
  critical_patterns:
    - "error:.*Segmentation fault"
```

### Watch Mode Configuration
```yaml
watch:
  debounce_seconds: 3
  include_patterns: ["*.swift", "*.plist"]
  exclude_patterns: ["*.xcuserstate"]
```

### Claude AI Customization
```yaml
claude:
  model: "claude-4-sonnet-20250514"
  context:
    include_project_structure: true
    max_context_files: 10
```

## 🤝 Contributing

We welcome contributions! This system was extracted from the [MyProjects](https://github.com/DELAxGithub/myprojects) iOS app and generalized for universal use.

### Development Setup
```bash
git clone https://github.com/DELAxGithub/delax-shared-packages.git
cd delax-shared-packages/native-tools/ios-auto-fix
./Scripts/auto-build-fix.sh --help
```

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- **Claude 4 Sonnet** by Anthropic for intelligent error analysis
- **MyProjects Team** for the original implementation
- **iOS Developer Community** for feedback and testing

---

**Ready to automate your iOS builds?** Start with `npm install -g @delax/ios-auto-fix` 🚀

> Part of the [DELAX Shared Packages](https://github.com/DELAxGithub/delax-shared-packages) ecosystem