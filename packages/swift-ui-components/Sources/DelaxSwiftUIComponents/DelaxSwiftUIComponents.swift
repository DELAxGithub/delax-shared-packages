import SwiftUI

// MARK: - Main Library Export

/// DelaxSwiftUIComponents - Reusable SwiftUI components for DELAX projects
///
/// This library provides production-ready components that have been battle-tested
/// in real applications, offering 95% development time reduction.
///
/// ## Available Components
///
/// ### Bug Reporting System
/// - **DelaxBugReportView**: Complete bug reporting interface
/// - **DelaxBugReportManager**: Bug report management and GitHub integration
/// - **DelaxShakeDetector**: Shake gesture detection for bug reporting
/// - **DelaxBugReport**: Comprehensive bug report data models
///
/// ## Quick Start
///
/// ```swift
/// import DelaxSwiftUIComponents
///
/// struct ContentView: View {
///     @State private var showBugReport = false
///
///     var body: some View {
///         VStack {
///             Text("Hello World")
///
///             Button("Report Bug") {
///                 showBugReport = true
///             }
///         }
///         .sheet(isPresented: $showBugReport) {
///             DelaxBugReportView(currentView: "ContentView")
///         }
///         .onShake() // Enables shake-to-report
///     }
/// }
/// ```
///
/// ## Configuration
///
/// Configure the bug report manager in your app initialization:
///
/// ```swift
/// DelaxBugReportManager.shared.configure(
///     gitHubToken: "your_token",
///     gitHubOwner: "your_username",
///     gitHubRepo: "your_repo"
/// )
/// ```

@available(iOS 16.0, macOS 13.0, *)
public struct DelaxSwiftUIComponents {
    
    /// Current version of the DelaxSwiftUIComponents library
    public static let version = "1.0.0"
    
    /// Library information
    public static let info = LibraryInfo(
        name: "DelaxSwiftUIComponents",
        version: version,
        description: "Reusable SwiftUI components for DELAX projects",
        author: "DELAX",
        repository: "https://github.com/DELAxGithub/delax-shared-packages"
    )
}

// MARK: - Library Information

@available(iOS 16.0, macOS 13.0, *)
public struct LibraryInfo {
    public let name: String
    public let version: String
    public let description: String
    public let author: String
    public let repository: String
    
    public init(name: String, version: String, description: String, author: String, repository: String) {
        self.name = name
        self.version = version
        self.description = description
        self.author = author
        self.repository = repository
    }
}

// MARK: - Public API Exports

// Bug Report System
@_exported import struct DelaxBugReport
@_exported import class DelaxBugReportManager  
@_exported import struct DelaxBugReportView
@_exported import class DelaxShakeDetector

// Utility Types
@_exported import enum DelaxBugCategory
@_exported import enum DelaxLogLevel
@_exported import struct DelaxUserAction
@_exported import struct DelaxLogEntry
@_exported import struct DelaxDeviceInfo

// GitHub Integration
@_exported import struct DelaxGitHubIssue
@_exported import enum DelaxBugReportError