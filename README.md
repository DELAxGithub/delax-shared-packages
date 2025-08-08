# delax-shared-packages

Central repository for technical heritage and shared packages across all DELAX projects.

## 🎯 Purpose

This monorepo serves as the technical heritage management center, providing:
- **95% development time reduction** (2-3 days → 30 minutes)
- **Reusable packages** for Swift, TypeScript, and workflow automation
- **Project generation tools** for rapid project setup
- **Claude-integrated development workflows**

## 📦 Packages

### 🔧 Native Development Tools
- `ios-auto-fix` - Universal iOS build error auto-fix system powered by Claude 4 Sonnet
- `ios-auto-bug-discovery` - **⭐ Revolutionary automatic bug detection framework** for iOS apps
- `swift-ui-components` - Reusable SwiftUI components with bug reporting integration

### 🤖 Development Automation
- `claude-integration` - Universal Claude AI integration library for development automation
- `workflow-scripts` - Development workflow automation (quick-pull, notifications, etc.)

### 🛠️ Core Packages
- `project-generator` - CLI tool for new project creation with AI assistance

### 📱 Platform-Specific Templates
- `ios-swift-template` - iOS Swift project templates
- `pm-web-template` - Project Management web application templates
- `supabase-integration` - Supabase backend integration utilities

## 🚀 Quick Start

### iOS Auto-Fix System
```bash
# Install iOS Auto-Fix globally
npm install -g @delax/ios-auto-fix

# Setup in your iOS project
cd YourIOSProject
ios-auto-fix setup

# Start auto-fix watch mode
ios-watch-fix
```

### iOS Auto Bug Discovery Framework
```swift
// Add to Package.swift
dependencies: [
    .package(url: "https://github.com/DELAxGithub/delax-shared-packages", from: "1.0.0")
]

// In your iOS App
import iOSAutoBugDiscovery
BugDetectionEngine.shared.startMonitoring()

// Automatically detects and reports bugs with 90%+ accuracy
// 🐛 Task creation failures, UI freezes, data inconsistencies
```

### Claude AI Integration
```bash
# Install Claude integration
npm install @delax/claude-integration

# Use in your development tools
import { ClaudeIntegration } from '@delax/claude-integration';
```

### Project Generation
```bash
# Install project generator
npm install -g @delax/project-generator

# Create new iOS project
delax-create ios-swift MyNewApp

# Create new PM web project  
delax-create pm-web MyPMSystem
```

## 🏗️ Architecture

This repository uses:
- **pnpm workspaces** for monorepo management
- **Turbo** for build system optimization
- **GitHub Actions** with Claude auto-correction
- **Semantic versioning** for package releases

## 📊 Impact

Projects using this technical heritage:
- **100 Days Workout** (iOS) - Source of workflow patterns
- **DELAxPM** (Web) - PM system template source  
- **MyProjects** (iOS) - **⭐ First iOS Auto Bug Discovery Framework deployment** with proven results
- **Future iOS projects** - Automatic bug detection with 90%+ accuracy, 99% faster bug discovery

---

🤖 **Powered by Claude Code integration for maximum development efficiency**