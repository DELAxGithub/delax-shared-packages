import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#endif

public class DelaxBugReportManager: ObservableObject {
    public static let shared = DelaxBugReportManager()
    
    @Published public var isReportingBug = false
    
    private var userActions: [DelaxUserAction] = []
    private var logs: [DelaxLogEntry] = []
    private let maxActionsCount = 20
    private let maxLogsCount = 100
    
    // GitHub Configuration
    public var gitHubToken: String?
    public var gitHubOwner: String?
    public var gitHubRepo: String?
    
    private init() {}
    
    // MARK: - Configuration
    
    public func configure(gitHubToken: String?, gitHubOwner: String?, gitHubRepo: String?) {
        self.gitHubToken = gitHubToken
        self.gitHubOwner = gitHubOwner
        self.gitHubRepo = gitHubRepo
    }
    
    // MARK: - User Action Tracking
    
    public func trackUserAction(_ action: String, viewName: String, details: [String: String]? = nil) {
        let userAction = DelaxUserAction(action: action, viewName: viewName, details: details)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.userActions.append(userAction)
            
            // Keep only recent actions
            if self.userActions.count > self.maxActionsCount {
                self.userActions.removeFirst(self.userActions.count - self.maxActionsCount)
            }
        }
    }
    
    // MARK: - Logging
    
    public func log(_ level: DelaxLogLevel, _ message: String, source: String? = nil) {
        let entry = DelaxLogEntry(level: level, message: message, source: source)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.logs.append(entry)
            
            // Keep only recent logs
            if self.logs.count > self.maxLogsCount {
                self.logs.removeFirst(self.logs.count - self.maxLogsCount)
            }
        }
        
        #if DEBUG
        print("[\(level.rawValue)] \(source ?? "App"): \(message)")
        #endif
    }
    
    // MARK: - Bug Report Creation
    
    public func createBugReport(
        category: DelaxBugCategory,
        description: String? = nil,
        reproductionSteps: String? = nil,
        expectedBehavior: String? = nil,
        actualBehavior: String? = nil,
        currentView: String,
        screenshot: Data? = nil
    ) -> DelaxBugReport {
        // Screenshot information logging
        if let screenshot = screenshot {
            log(.info, "Screenshot captured: \(screenshot.count) bytes", source: "DelaxBugReportManager")
        } else {
            log(.warning, "No screenshot provided", source: "DelaxBugReportManager")
        }
        
        // Get recent actions and logs
        let recentActions = Array(userActions.suffix(10))
        let recentLogs = logs.filter { log in
            log.level == .warning || log.level == .error
        }.suffix(20)
        
        return DelaxBugReport(
            category: category,
            description: description,
            reproductionSteps: reproductionSteps,
            expectedBehavior: expectedBehavior,
            actualBehavior: actualBehavior,
            screenshot: screenshot,
            currentView: currentView,
            userActions: recentActions,
            logs: Array(recentLogs)
        )
    }
    
    public func captureBugReport(
        category: DelaxBugCategory,
        description: String? = nil,
        reproductionSteps: String? = nil,
        expectedBehavior: String? = nil,
        actualBehavior: String? = nil,
        currentView: String
    ) -> DelaxBugReport {
        // Capture screenshot
        let screenshot = captureScreenshot()
        
        return createBugReport(
            category: category,
            description: description,
            reproductionSteps: reproductionSteps,
            expectedBehavior: expectedBehavior,
            actualBehavior: actualBehavior,
            currentView: currentView,
            screenshot: screenshot
        )
    }
    
    // MARK: - Screenshot Capture
    
    private func captureScreenshot() -> Data? {
        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return nil }
        
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { context in
            window.layer.render(in: context.cgContext)
        }
        
        return image.jpegData(compressionQuality: 0.8)
        #else
        // macOS screenshot capture would go here
        return nil
        #endif
    }
    
    // MARK: - Bug Report Submission
    
    public func submitBugReport(_ report: DelaxBugReport) async throws {
        // Environment validation
        log(.info, "Environment check - GitHub Token: \(gitHubToken != nil ? "Set" : "Not set")")
        log(.info, "Environment check - GitHub Owner: \(gitHubOwner ?? "Not set")")
        log(.info, "Environment check - GitHub Repo: \(gitHubRepo ?? "Not set")")
        
        #if DEBUG
        // Debug build: save locally if no GitHub token
        if !hasValidTokens {
            log(.warning, "GitHub token not configured")
            log(.warning, "Saving bug report locally instead.")
            try await saveLocally(report)
            return
        }
        #endif
        
        // Create GitHub Issue
        log(.info, "Attempting to create GitHub Issue...")
        do {
            let issue = try await createGitHubIssue(from: report)
            log(.info, "GitHub Issue created successfully: #\(issue.number) - \(issue.htmlUrl)")
            
            // Success notification
            DispatchQueue.main.async {
                UserDefaults.standard.set(issue.htmlUrl, forKey: "lastCreatedIssueUrl")
            }
        } catch {
            log(.error, "Failed to create GitHub Issue: \(error)")
            log(.error, "Error details: \(error.localizedDescription)")
            
            // Fallback: save locally
            try await saveLocally(report)
            throw error
        }
    }
    
    private var hasValidTokens: Bool {
        return gitHubToken != nil && gitHubOwner != nil && gitHubRepo != nil
    }
    
    private func saveLocally(_ report: DelaxBugReport) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(report)
        
        // Save to documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsPath.appendingPathComponent("bug_report_\(report.id.uuidString).json")
        
        try data.write(to: filePath)
        
        log(.info, "Bug report saved locally to: \(filePath.path)")
    }
    
    // MARK: - GitHub API Integration
    
    private func createGitHubIssue(from report: DelaxBugReport) async throws -> DelaxGitHubIssue {
        guard let token = gitHubToken,
              let owner = gitHubOwner,
              let repo = gitHubRepo else {
            throw DelaxBugReportError.missingConfiguration
        }
        
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/issues")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        // Create issue body
        let issueBody = createIssueBody(from: report)
        let title = createIssueTitle(from: report)
        let labels = createIssueLabels(from: report)
        
        let issueRequest = DelaxGitHubCreateIssueRequest(
            title: title,
            body: issueBody,
            labels: labels
        )
        
        let jsonData = try JSONEncoder().encode(issueRequest)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DelaxBugReportError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 201:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let gitHubResponse = try decoder.decode(DelaxGitHubIssue.self, from: data)
            return gitHubResponse
        case 401:
            throw DelaxBugReportError.unauthorized
        case 404:
            throw DelaxBugReportError.repositoryNotFound
        case 422:
            throw DelaxBugReportError.validationFailed
        default:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw DelaxBugReportError.apiError(httpResponse.statusCode, errorMessage)
        }
    }
    
    private func createIssueTitle(from report: DelaxBugReport) -> String {
        let prefix = "[\(report.category.issueLabel)] "
        let description = report.description ?? "Bug in \(report.currentView)"
        let truncated = String(description.prefix(80))
        return prefix + truncated
    }
    
    private func createIssueBody(from report: DelaxBugReport) -> String {
        var body = """
        ## Bug Report
        
        **Category:** \(report.category.displayName)
        **View:** \(report.currentView)
        **Timestamp:** \(formatDate(report.timestamp))
        
        """
        
        if let description = report.description, !description.isEmpty {
            body += """
            ### Description
            \(description)
            
            """
        }
        
        if let reproductionSteps = report.reproductionSteps, !reproductionSteps.isEmpty {
            body += """
            ### Reproduction Steps
            \(reproductionSteps)
            
            """
        }
        
        if let expectedBehavior = report.expectedBehavior, !expectedBehavior.isEmpty {
            body += """
            ### Expected Behavior
            \(expectedBehavior)
            
            """
        }
        
        if let actualBehavior = report.actualBehavior, !actualBehavior.isEmpty {
            body += """
            ### Actual Behavior
            \(actualBehavior)
            
            """
        }
        
        // Device Information
        body += """
        ### Device Information
        - **Model:** \(report.deviceInfo.model)
        - **OS:** \(report.deviceInfo.systemName) \(report.deviceInfo.systemVersion)
        - **Screen Size:** \(report.deviceInfo.screenSize)
        - **App Version:** \(report.appVersion)
        
        """
        
        // Recent User Actions
        if !report.userActions.isEmpty {
            body += """
            ### Recent User Actions
            """
            for action in report.userActions.suffix(5) {
                body += "\n- \(formatDate(action.timestamp)): \(action.action) in \(action.viewName)"
                if let details = action.details, !details.isEmpty {
                    body += " - \(details.map { "\($0.key): \($0.value)" }.joined(separator: ", "))"
                }
            }
            body += "\n\n"
        }
        
        // Error Logs
        let errorLogs = report.logs.filter { $0.level == .error }
        if !errorLogs.isEmpty {
            body += """
            ### Error Logs
            ```
            """
            for log in errorLogs.suffix(5) {
                body += "\n[\(log.level.rawValue)] \(formatDate(log.timestamp)): \(log.message)"
                if let source = log.source {
                    body += " (Source: \(source))"
                }
            }
            body += "\n```\n\n"
        }
        
        body += """
        ---
        *This bug report was generated automatically by DelaxBugReportManager*
        """
        
        return body
    }
    
    private func createIssueLabels(from report: DelaxBugReport) -> [String] {
        var labels = [report.category.issueLabel, "bug"]
        
        // Add priority label based on category
        switch report.category {
        case .appFreeze:
            labels.append("high priority")
        case .dataNotSaved:
            labels.append("medium priority")
        default:
            labels.append("low priority")
        }
        
        // Add auto-fix candidate if simple issue
        if report.category == .buttonNotWorking || report.category == .displayIssue {
            labels.append("auto-fix candidate")
        }
        
        return labels
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - Shake Detection Support
    
    public func showBugReportView() {
        DispatchQueue.main.async {
            self.isReportingBug = true
        }
    }
}

// MARK: - Convenience Methods

public extension DelaxBugReportManager {
    func trackButtonTap(_ buttonName: String, in viewName: String) {
        trackUserAction("Button Tap", viewName: viewName, details: ["button": buttonName])
    }
    
    func trackNavigation(to viewName: String, from previousView: String? = nil) {
        var details: [String: String] = [:]
        if let previousView = previousView {
            details["from"] = previousView
        }
        trackUserAction("Navigation", viewName: viewName, details: details)
    }
    
    func trackError(_ error: Error, in viewName: String) {
        log(.error, error.localizedDescription, source: viewName)
        trackUserAction("Error Occurred", viewName: viewName, details: ["error": error.localizedDescription])
    }
}

// MARK: - Error Types

public enum DelaxBugReportError: LocalizedError {
    case missingConfiguration
    case invalidResponse
    case unauthorized
    case repositoryNotFound
    case validationFailed
    case apiError(Int, String)
    
    public var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "GitHub configuration is missing"
        case .invalidResponse:
            return "Invalid response from GitHub API"
        case .unauthorized:
            return "GitHub token is invalid"
        case .repositoryNotFound:
            return "Repository not found"
        case .validationFailed:
            return "GitHub API validation failed"
        case .apiError(let code, let message):
            return "GitHub API error \(code): \(message)"
        }
    }
}