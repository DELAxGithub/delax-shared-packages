import XCTest
@testable import DelaxSwiftUIComponents

final class DelaxBugReportTests: XCTestCase {
    
    var bugReportManager: DelaxBugReportManager!
    
    override func setUp() {
        super.setUp()
        bugReportManager = DelaxBugReportManager.shared
        
        // Configure with test values
        bugReportManager.configure(
            gitHubToken: "test_token",
            gitHubOwner: "test_owner",
            gitHubRepo: "test_repo"
        )
    }
    
    override func tearDown() {
        bugReportManager = nil
        super.tearDown()
    }
    
    // MARK: - Bug Report Creation Tests
    
    func testBugReportCreation() {
        let report = bugReportManager.createBugReport(
            category: .buttonNotWorking,
            description: "Test button does not work",
            currentView: "TestView"
        )
        
        XCTAssertEqual(report.category, .buttonNotWorking)
        XCTAssertEqual(report.description, "Test button does not work")
        XCTAssertEqual(report.currentView, "TestView")
        XCTAssertNotNil(report.deviceInfo)
        XCTAssertNotNil(report.timestamp)
    }
    
    func testBugReportWithScreenshot() {
        let testScreenshotData = "test_image_data".data(using: .utf8)!
        
        let report = bugReportManager.createBugReport(
            category: .displayIssue,
            description: "Display problem",
            currentView: "TestView",
            screenshot: testScreenshotData
        )
        
        XCTAssertEqual(report.screenshot, testScreenshotData)
    }
    
    // MARK: - User Action Tracking Tests
    
    func testUserActionTracking() {
        bugReportManager.trackUserAction("Test Action", viewName: "TestView")
        
        let report = bugReportManager.createBugReport(
            category: .other,
            description: "Test",
            currentView: "TestView"
        )
        
        XCTAssertFalse(report.userActions.isEmpty)
        XCTAssertEqual(report.userActions.last?.action, "Test Action")
        XCTAssertEqual(report.userActions.last?.viewName, "TestView")
    }
    
    func testButtonTapTracking() {
        bugReportManager.trackButtonTap("Submit Button", in: "FormView")
        
        let report = bugReportManager.createBugReport(
            category: .buttonNotWorking,
            description: "Button issue",
            currentView: "FormView"
        )
        
        XCTAssertFalse(report.userActions.isEmpty)
        let lastAction = report.userActions.last
        XCTAssertEqual(lastAction?.action, "Button Tap")
        XCTAssertEqual(lastAction?.viewName, "FormView")
        XCTAssertEqual(lastAction?.details?["button"], "Submit Button")
    }
    
    // MARK: - Logging Tests
    
    func testLogging() {
        bugReportManager.log(.error, "Test error message", source: "TestClass")
        
        let report = bugReportManager.createBugReport(
            category: .other,
            description: "Test",
            currentView: "TestView"
        )
        
        let errorLogs = report.logs.filter { $0.level == .error }
        XCTAssertFalse(errorLogs.isEmpty)
        XCTAssertEqual(errorLogs.last?.message, "Test error message")
        XCTAssertEqual(errorLogs.last?.source, "TestClass")
    }
    
    func testErrorTracking() {
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        bugReportManager.trackError(testError, in: "ErrorView")
        
        let report = bugReportManager.createBugReport(
            category: .other,
            description: "Error occurred",
            currentView: "ErrorView"
        )
        
        // Check if error was logged
        let errorLogs = report.logs.filter { $0.level == .error }
        XCTAssertFalse(errorLogs.isEmpty)
        
        // Check if error action was tracked
        let errorActions = report.userActions.filter { $0.action == "Error Occurred" }
        XCTAssertFalse(errorActions.isEmpty)
    }
    
    // MARK: - Bug Category Tests
    
    func testBugCategoryDisplayNames() {
        XCTAssertEqual(DelaxBugCategory.buttonNotWorking.displayName, "ボタンが動作しない")
        XCTAssertEqual(DelaxBugCategory.displayIssue.displayName, "表示の問題")
        XCTAssertEqual(DelaxBugCategory.appFreeze.displayName, "アプリが固まる")
        XCTAssertEqual(DelaxBugCategory.dataNotSaved.displayName, "データが保存されない")
        XCTAssertEqual(DelaxBugCategory.other.displayName, "その他")
    }
    
    func testBugCategoryIssueLabels() {
        XCTAssertEqual(DelaxBugCategory.buttonNotWorking.issueLabel, "UI Issue")
        XCTAssertEqual(DelaxBugCategory.displayIssue.issueLabel, "Display Bug")
        XCTAssertEqual(DelaxBugCategory.appFreeze.issueLabel, "Performance")
        XCTAssertEqual(DelaxBugCategory.dataNotSaved.issueLabel, "Data Issue")
        XCTAssertEqual(DelaxBugCategory.other.issueLabel, "Bug")
    }
    
    // MARK: - Device Info Tests
    
    func testDeviceInfoCreation() {
        let deviceInfo = DelaxDeviceInfo()
        
        XCTAssertFalse(deviceInfo.model.isEmpty)
        XCTAssertFalse(deviceInfo.systemName.isEmpty)
        XCTAssertFalse(deviceInfo.systemVersion.isEmpty)
        XCTAssertFalse(deviceInfo.appVersion.isEmpty)
    }
    
    // MARK: - Navigation Tracking Tests
    
    func testNavigationTracking() {
        bugReportManager.trackNavigation(to: "DestinationView", from: "SourceView")
        
        let report = bugReportManager.createBugReport(
            category: .other,
            description: "Navigation test",
            currentView: "DestinationView"
        )
        
        XCTAssertFalse(report.userActions.isEmpty)
        let lastAction = report.userActions.last
        XCTAssertEqual(lastAction?.action, "Navigation")
        XCTAssertEqual(lastAction?.viewName, "DestinationView")
        XCTAssertEqual(lastAction?.details?["from"], "SourceView")
    }
    
    // MARK: - Performance Tests
    
    func testActionTrackingLimit() {
        // Add more actions than the limit
        for i in 1...30 {
            bugReportManager.trackUserAction("Action \(i)", viewName: "TestView")
        }
        
        let report = bugReportManager.createBugReport(
            category: .other,
            description: "Performance test",
            currentView: "TestView"
        )
        
        // Should only keep the most recent 10 actions in the report
        XCTAssertLessThanOrEqual(report.userActions.count, 10)
        
        // Should contain the most recent actions
        if !report.userActions.isEmpty {
            XCTAssert(report.userActions.last?.action.contains("Action") == true)
        }
    }
}

// MARK: - Mock Tests

final class DelaxShakeDetectorTests: XCTestCase {
    
    var shakeDetector: DelaxShakeDetector!
    
    override func setUp() {
        super.setUp()
        shakeDetector = DelaxShakeDetector()
    }
    
    override func tearDown() {
        shakeDetector = nil
        super.tearDown()
    }
    
    func testShakeDetection() {
        XCTAssertFalse(shakeDetector.isShakeDetected)
        
        // Manually trigger shake
        shakeDetector.triggerShake()
        
        XCTAssertTrue(shakeDetector.isShakeDetected)
    }
}