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
/// ### UI Components (New from MyProjects)
/// - **TaskRow**: Task display with hierarchy and priority indicators
/// - **ProgressRing**: Animated progress ring component
/// - **ProjectCard**: Project card display component
/// - **ProgressIndicator**: General purpose progress indicator
/// - **TaskHierarchyView**: Hierarchical task display
///
/// ### Data Models (SwiftData Compatible)
/// - **Project**: Project management data model
/// - **Task**: Task data model with relationships
/// - **AIContext**: AI learning context model
/// - **TaskTemplate**: Reusable task templates
/// - **UserFeedback**: User feedback collection
///
/// ### Services
/// - **DataManager**: SwiftData operations wrapper
/// - **JSONImportService**: JSON import functionality
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

@available(iOS 17.0, macOS 14.0, *)
public struct DelaxSwiftUIComponents {
    
    /// Current version of the DelaxSwiftUIComponents library
    public static let version = "2.0.0"
    
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

@available(iOS 17.0, macOS 14.0, *)
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

// Re-export SwiftUI and SwiftData for convenience
@_exported import SwiftUI
@_exported import SwiftData
@_exported import Foundation