import Foundation

// MARK: - Bug Report Models

public struct DelaxBugReport: Codable, Identifiable {
    public let id = UUID()
    public let category: DelaxBugCategory
    public let description: String?
    public let reproductionSteps: String?
    public let expectedBehavior: String?
    public let actualBehavior: String?
    public let screenshot: Data?
    public let currentView: String
    public let userActions: [DelaxUserAction]
    public let logs: [DelaxLogEntry]
    public let deviceInfo: DelaxDeviceInfo
    public let appVersion: String
    public let timestamp: Date
    
    public init(
        category: DelaxBugCategory,
        description: String? = nil,
        reproductionSteps: String? = nil,
        expectedBehavior: String? = nil,
        actualBehavior: String? = nil,
        screenshot: Data? = nil,
        currentView: String,
        userActions: [DelaxUserAction] = [],
        logs: [DelaxLogEntry] = []
    ) {
        self.category = category
        self.description = description
        self.reproductionSteps = reproductionSteps
        self.expectedBehavior = expectedBehavior
        self.actualBehavior = actualBehavior
        self.screenshot = screenshot
        self.currentView = currentView
        self.userActions = userActions
        self.logs = logs
        self.deviceInfo = DelaxDeviceInfo()
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        self.timestamp = Date()
    }
}

public enum DelaxBugCategory: String, CaseIterable, Codable {
    case buttonNotWorking = "button_not_working"
    case displayIssue = "display_issue"
    case appFreeze = "app_freeze"
    case dataNotSaved = "data_not_saved"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .buttonNotWorking:
            return "ボタンが動作しない"
        case .displayIssue:
            return "表示の問題"
        case .appFreeze:
            return "アプリが固まる"
        case .dataNotSaved:
            return "データが保存されない"
        case .other:
            return "その他"
        }
    }
    
    public var issueLabel: String {
        switch self {
        case .buttonNotWorking:
            return "UI Issue"
        case .displayIssue:
            return "Display Bug"
        case .appFreeze:
            return "Performance"
        case .dataNotSaved:
            return "Data Issue"
        case .other:
            return "Bug"
        }
    }
}

public struct DelaxUserAction: Codable {
    public let action: String
    public let viewName: String
    public let details: [String: String]?
    public let timestamp: Date
    
    public init(action: String, viewName: String, details: [String: String]? = nil) {
        self.action = action
        self.viewName = viewName
        self.details = details
        self.timestamp = Date()
    }
}

public enum DelaxLogLevel: String, Codable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

public struct DelaxLogEntry: Codable {
    public let level: DelaxLogLevel
    public let message: String
    public let source: String?
    public let timestamp: Date
    
    public init(level: DelaxLogLevel, message: String, source: String? = nil) {
        self.level = level
        self.message = message
        self.source = source
        self.timestamp = Date()
    }
}

public struct DelaxDeviceInfo: Codable {
    public let model: String
    public let systemName: String
    public let systemVersion: String
    public let screenSize: String
    public let appVersion: String
    
    public init() {
        #if os(iOS)
        import UIKit
        self.model = UIDevice.current.model
        self.systemName = UIDevice.current.systemName
        self.systemVersion = UIDevice.current.systemVersion
        let bounds = UIScreen.main.bounds
        self.screenSize = "\(Int(bounds.width))x\(Int(bounds.height))"
        #elseif os(macOS)
        import AppKit
        self.model = "Mac"
        self.systemName = "macOS"
        self.systemVersion = ProcessInfo.processInfo.operatingSystemVersionString
        if let screen = NSScreen.main {
            let size = screen.frame.size
            self.screenSize = "\(Int(size.width))x\(Int(size.height))"
        } else {
            self.screenSize = "Unknown"
        }
        #else
        self.model = "Unknown"
        self.systemName = "Unknown"
        self.systemVersion = "Unknown"
        self.screenSize = "Unknown"
        #endif
        
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
}

// MARK: - GitHub Integration Models

public struct DelaxGitHubIssue: Codable {
    public let number: Int
    public let htmlUrl: String
    public let title: String
    
    public init(number: Int, htmlUrl: String, title: String) {
        self.number = number
        self.htmlUrl = htmlUrl
        self.title = title
    }
}

public struct DelaxGitHubCreateIssueRequest: Codable {
    public let title: String
    public let body: String
    public let labels: [String]
    
    public init(title: String, body: String, labels: [String]) {
        self.title = title
        self.body = body
        self.labels = labels
    }
}