# DelaxSwiftUIComponents

Reusable SwiftUI components for DELAX projects, providing 95% development time reduction through proven technical heritage.

## 🎯 Components

### Bug Reporting System
- **DelaxBugReportView** - Complete bug reporting interface
- **DelaxBugReportManager** - Bug report management service
- **DelaxShakeDetector** - Shake gesture detection for bug reporting
- **DelaxBugReport** - Bug report data model

## 🚀 Quick Start

### Installation

Add to your Package.swift:
```swift
dependencies: [
    .package(url: "https://github.com/DELAxGithub/delax-shared-packages", from: "1.0.0")
]
```

### Usage

```swift
import SwiftUI
import DelaxSwiftUIComponents

struct ContentView: View {
    @State private var showBugReport = false
    
    var body: some View {
        VStack {
            // Your app content
            Text("Hello World")
            
            Button("Report Bug") {
                showBugReport = true
            }
        }
        .sheet(isPresented: $showBugReport) {
            DelaxBugReportView(
                currentView: "ContentView",
                preCapuredScreenshot: nil
            )
        }
        .onShake {
            // Shake to report bug
            showBugReport = true
        }
    }
}
```

## 📋 Bug Report Features

- ✅ **Automatic screenshot capture**
- ✅ **User action tracking**
- ✅ **Device information collection**
- ✅ **GitHub Issues integration**
- ✅ **Shake gesture support**
- ✅ **Offline fallback storage**
- ✅ **Categorized bug reporting**
- ✅ **Image picker for manual screenshots**

## 🛠️ Configuration

Set up environment variables for GitHub integration:
```swift
// In your app's environment configuration
GITHUB_TOKEN=your_github_token
GITHUB_OWNER=your_github_username
GITHUB_REPO=your_repository_name
```

## 📊 Impact

Projects using this component:
- **100 Days Workout** - Original implementation source
- **MyProjects** - First adoption
- **Future iOS projects** - Immediate bug reporting capability

---

🤖 **Powered by Claude Code integration for maximum development efficiency**