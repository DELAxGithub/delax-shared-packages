# delax-shared-packages

Central repository for technical heritage and shared packages across all DELAX projects.

## 🎯 Purpose

This monorepo serves as the technical heritage management center, providing:
- **95% development time reduction** (2-3 days → 30 minutes)
- **Reusable packages** for Swift, TypeScript, and workflow automation
- **Project generation tools** for rapid project setup
- **Claude-integrated development workflows**

## 📦 Packages

### Core Packages
- `workflow-scripts` - Development workflow automation (quick-pull, notifications, etc.)
- `swift-ui-components` - Reusable SwiftUI components
- `react-components` - **NEW** React components & utilities (PMliberary heritage)
- `ai-integration` - Claude/AI API integration patterns
- `project-generator` - CLI tool for new project creation

### Platform-Specific Packages
- `ios-swift-template` - iOS Swift project templates
- `pm-web-template` - Project Management web application templates
- `supabase-integration` - Supabase backend integration utilities

## 🚀 Quick Start

```bash
# Install globally
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
- **PMliberary** (Web) - **NEW** React components source
- **MyProjects** (iOS) - First major beneficiary
- **Future projects** - Immediate 95% setup time reduction

---

🤖 **Powered by Claude Code integration for maximum development efficiency**