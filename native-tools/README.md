# Native Development Tools

**Platform-specific native development automation tools**

## 🛠️ Available Tools

### 🔧 iOS Auto-Fix
**Universal iOS build error auto-fix system powered by Claude 4 Sonnet**

- **Location**: `./ios-auto-fix/`
- **Purpose**: Automatically detects and fixes iOS build errors
- **Features**: Xcode error extraction, Claude-powered patch generation, safe automated fixes
- **Install**: `npm install -g @delax/ios-auto-fix`

📖 [Full Documentation](./ios-auto-fix/README.md)

---

### 🎨 SwiftUIQualityKit
**SwiftUI + CloudKit specialized quality management automation system**

- **Location**: `./SwiftUIQualityKit/`
- **Purpose**: Automated UI quality management for SwiftUI + CloudKit projects
- **Features**: Real-time monitoring, language unification, quality analysis, Xcode integration
- **Target**: iOS 15.0+, SwiftUI + CloudKit projects

#### Quick Usage
```bash
# Copy to your project
cp -r delax-shared-packages/native-tools/SwiftUIQualityKit ./

# 30-second setup
./SwiftUIQualityKit/quick_setup.sh

# Start monitoring
./SwiftUIQualityKit/watch_mode.sh
```

#### Key Features
- **🔍 Real-time Quality Monitoring**: File change detection with instant feedback
- **🎯 SwiftUI Specialized Analysis**: State management, performance, accessibility checks
- **☁️ CloudKit Integration Quality**: SwiftData sync patterns and schema design analysis
- **📝 Japanese Language Unification**: Automatic P/F/C → タンパク質/脂質/炭水化物 conversion
- **🏗️ Xcode Integration**: Build Phase and Pre-commit hook quality gates
- **🧩 Standard Components**: Unified TonTon UI component library

📖 [Full Documentation](./SwiftUIQualityKit/README.md) | [Quick Start](./SwiftUIQualityKit/QUICKSTART.md) | [Troubleshooting](./SwiftUIQualityKit/TROUBLESHOOTING.md)

---

## 🚀 Usage Patterns

### For New iOS Projects
```bash
# 1. Setup SwiftUIQualityKit for quality management
cp -r delax-shared-packages/native-tools/SwiftUIQualityKit ./
./SwiftUIQualityKit/quick_setup.sh

# 2. Setup iOS Auto-Fix for build error handling
npm install -g @delax/ios-auto-fix
ios-auto-fix setup
```

### For Existing iOS Projects
```bash
# Add quality management
cp -r delax-shared-packages/native-tools/SwiftUIQualityKit ./
./SwiftUIQualityKit/install.sh

# Add build error handling
ios-auto-fix setup
```

### Daily Development Workflow
```bash
# Start quality monitoring (terminal 1)
./SwiftUIQualityKit/watch_mode.sh

# Start build error auto-fix (terminal 2)
ios-watch-fix

# Develop with confidence - both systems running
```

## 🎯 Target Projects

### SwiftUIQualityKit
- ✅ SwiftUI + CloudKit iOS apps
- ✅ Japanese/English mixed projects
- ✅ iOS 15.0+ projects
- ✅ Team development environments

### iOS Auto-Fix
- ✅ Any iOS/macOS project
- ✅ Xcode build systems
- ✅ CI/CD environments
- ✅ Large codebases with frequent build issues

## 📊 Impact Metrics

### SwiftUIQualityKit (Verified on TonTon app)
- **Problem Detection**: 86 quality issues identified
- **Auto-Fix Rate**: 85% of language mixing issues resolved automatically
- **Processing Speed**: 45 files analyzed in <15 seconds
- **False Positive Rate**: <5% high-precision detection

### iOS Auto-Fix
- **Build Success Rate**: 95%+ automatic resolution
- **Time Savings**: 2-3 hours → 30 minutes for complex build issues
- **Error Coverage**: 200+ common build error patterns
- **Safety**: Automatic backups before all changes

## 🔄 Updates and Maintenance

Both tools are actively maintained in the delax-shared-packages repository:

- **SwiftUIQualityKit**: Latest version includes CloudKit specialized checks and enhanced automation
- **iOS Auto-Fix**: Continuously updated with new error patterns and fix strategies

## 🆘 Support

For issues, improvements, or feature requests:
1. Check individual tool documentation
2. Review troubleshooting guides
3. Submit issues to delax-shared-packages repository

---

**🤖 Both tools integrate seamlessly with Claude Code for maximum development efficiency**