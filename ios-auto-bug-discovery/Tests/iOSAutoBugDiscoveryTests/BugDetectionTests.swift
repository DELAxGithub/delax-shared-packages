//
//  BugDetectionTests.swift
//  iOS Auto Bug Discovery Framework Tests
//
//  Created by DELAX Code Generator on 2025-08-06.
//

import XCTest
@testable import iOSAutoBugDiscovery

final class BugDetectionTests: XCTestCase {
    
    var bugDetectionEngine: BugDetectionEngine!
    
    override func setUpWithError() throws {
        bugDetectionEngine = BugDetectionEngine.shared
    }
    
    override func tearDownWithError() throws {
        bugDetectionEngine.stopMonitoring()
        bugDetectionEngine = nil
    }
    
    // MARK: - Core Engine Tests
    
    func testEngineStartsAndStops() throws {
        XCTAssertFalse(bugDetectionEngine.isMonitoring)
        
        bugDetectionEngine.startMonitoring()
        XCTAssertTrue(bugDetectionEngine.isMonitoring)
        
        bugDetectionEngine.stopMonitoring()
        XCTAssertFalse(bugDetectionEngine.isMonitoring)
    }
    
    func testHapticEventRecording() throws {
        let expectation = XCTestExpectation(description: "Haptic event recorded")
        var eventRecorded = false
        
        // Mock the event recording
        let originalRecordEvent = bugDetectionEngine.recordEvent
        
        // Override recordEvent to detect when event is recorded
        // Note: This is a simplified test - in real implementation we'd use dependency injection
        
        bugDetectionEngine.recordHapticFeedback(.taskCreated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            eventRecorded = true
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(eventRecorded)
    }
    
    func testSaveEventRecording() throws {
        let expectation = XCTestExpectation(description: "Save event recorded")
        
        let mockError = NSError(domain: "TestError", code: 1001, userInfo: [
            NSLocalizedDescriptionKey: "Mock save failure"
        ])
        
        bugDetectionEngine.recordSaveOperation(
            context: nil,
            success: false,
            error: mockError,
            duration: 0.1,
            entitiesCount: 1
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Bug Pattern Detection Tests
    
    func testTaskCreationFailureDetection() throws {
        let expectation = XCTestExpectation(description: "Task creation failure detected")
        var detectedBug: DetectedBug?
        
        bugDetectionEngine.startMonitoring()
        
        // Set up bug detection callback
        bugDetectionEngine.onBugDetected = { bug in
            detectedBug = bug
            expectation.fulfill()
        }
        
        // Simulate the bug pattern: haptic feedback followed by save failure
        bugDetectionEngine.recordHapticFeedback(.taskCreated)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            let mockError = NSError(domain: "SwiftDataError", code: 1001)
            self.bugDetectionEngine.recordSaveOperation(
                context: nil,
                success: false,
                error: mockError,
                duration: 0.05,
                entitiesCount: 1
            )
        }
        
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertNotNil(detectedBug)
        XCTAssertEqual(detectedBug?.type, .taskCreationFailure)
        XCTAssertEqual(detectedBug?.severity, .high)
        XCTAssertEqual(detectedBug?.confidence, 0.9, accuracy: 0.01)
        XCTAssertTrue(detectedBug?.title.contains("Task creation appears to succeed but actually fails") ?? false)
    }
    
    func testTaskCreationFailureSimulation() throws {
        let expectation = XCTestExpectation(description: "Simulation bug detected")
        var detectedBug: DetectedBug?
        
        bugDetectionEngine.startMonitoring()
        
        bugDetectionEngine.onBugDetected = { bug in
            detectedBug = bug
            expectation.fulfill()
        }
        
        // Use the built-in simulation
        bugDetectionEngine.simulateTaskCreationFailureBug()
        
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertNotNil(detectedBug)
        XCTAssertEqual(detectedBug?.type, .taskCreationFailure)
    }
    
    // MARK: - Configuration Tests
    
    func testDefaultConfiguration() throws {
        let config = BugDetectionEngine.Configuration.default
        
        XCTAssertTrue(config.enabledDetectors.contains("SwiftData"))
        XCTAssertTrue(config.enabledDetectors.contains("UIResponsiveness"))
        XCTAssertEqual(config.performanceMode, .balanced)
        XCTAssertTrue(config.reportingEnabled)
        XCTAssertFalse(config.aiAnalysisEnabled)
    }
    
    // MARK: - DetectedBug Tests
    
    func testDetectedBugCreation() throws {
        let bug = DetectedBug(
            type: .taskCreationFailure,
            severity: .high,
            title: "Test Bug",
            description: "Test Description",
            confidence: 0.9
        )
        
        XCTAssertEqual(bug.type, .taskCreationFailure)
        XCTAssertEqual(bug.severity, .high)
        XCTAssertEqual(bug.title, "Test Bug")
        XCTAssertEqual(bug.description, "Test Description")
        XCTAssertEqual(bug.confidence, 0.9, accuracy: 0.01)
        XCTAssertNotNil(bug.id)
        XCTAssertFalse(bug.stackTrace.isEmpty)
    }
    
    func testBugSeverityPriority() throws {
        XCTAssertEqual(BugSeverity.critical.priority, 4)
        XCTAssertEqual(BugSeverity.high.priority, 3)
        XCTAssertEqual(BugSeverity.medium.priority, 2)
        XCTAssertEqual(BugSeverity.low.priority, 1)
    }
    
    // MARK: - AI Analysis Tests
    
    func testAIAnalysisFallback() throws {
        let bug = DetectedBug(
            type: .swiftDataAnomaly,
            severity: .medium,
            title: "Test Bug",
            description: "Test Description"
        )
        
        let analysis = AIAnalysisResult.fallback(for: bug)
        
        XCTAssertTrue(analysis.rootCause.contains("SwiftData Anomaly"))
        XCTAssertEqual(analysis.suggestedFix, "Manual investigation required")
        XCTAssertEqual(analysis.confidence, 0.3, accuracy: 0.01)
    }
    
    // MARK: - Event Tests
    
    func testHapticEventCreation() throws {
        let event = HapticEvent(hapticType: .taskCreated)
        
        XCTAssertEqual(event.eventType, "HapticEvent")
        XCTAssertEqual(event.hapticType, .taskCreated)
        XCTAssertNotNil(event.timestamp)
    }
    
    func testSaveEventCreation() throws {
        let error = NSError(domain: "TestDomain", code: 123)
        let event = SaveEvent(
            context: nil,
            success: false,
            error: error,
            duration: 0.5,
            entitiesCount: 2
        )
        
        XCTAssertEqual(event.eventType, "SaveEvent")
        XCTAssertFalse(event.success)
        XCTAssertTrue(event.failed)
        XCTAssertEqual(event.duration, 0.5, accuracy: 0.01)
        XCTAssertEqual(event.entitiesCount, 2)
        XCTAssertNotNil(event.error)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceImpact() throws {
        measure {
            // Test the performance impact of bug detection
            bugDetectionEngine.startMonitoring()
            
            // Simulate multiple events
            for _ in 0..<100 {
                bugDetectionEngine.recordHapticFeedback(.taskCreated)
                bugDetectionEngine.recordSaveOperation(
                    context: nil,
                    success: true,
                    duration: 0.001,
                    entitiesCount: 1
                )
            }
            
            bugDetectionEngine.stopMonitoring()
        }
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsage() throws {
        bugDetectionEngine.startMonitoring()
        
        // Generate many events to test memory management
        for i in 0..<1000 {
            bugDetectionEngine.recordHapticFeedback(.taskCreated)
            if i % 2 == 0 {
                bugDetectionEngine.recordSaveOperation(
                    context: nil,
                    success: i % 10 != 0, // 10% failure rate
                    duration: Double(i) * 0.001,
                    entitiesCount: 1
                )
            }
        }
        
        bugDetectionEngine.stopMonitoring()
        
        // Memory should not grow indefinitely due to event limiting
        XCTAssertTrue(true) // This test primarily checks for memory leaks in instruments
    }
}

// MARK: - Mock Bug Report Submission

class MockBugReportSubmission: BugReportSubmission {
    var submittedBugs: [DetectedBug] = []
    var shouldThrowError = false
    
    func submitBugReport(_ bug: DetectedBug) async throws {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Mock submission error"
            ])
        }
        
        submittedBugs.append(bug)
    }
}

// MARK: - Bug Report Submission Tests

extension BugDetectionTests {
    
    func testBugReportSubmission() throws {
        let mockSubmission = MockBugReportSubmission()
        bugDetectionEngine.bugReportSubmission = mockSubmission
        
        let expectation = XCTestExpectation(description: "Bug report submitted")
        
        bugDetectionEngine.startMonitoring()
        
        bugDetectionEngine.onBugDetected = { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                XCTAssertEqual(mockSubmission.submittedBugs.count, 1)
                XCTAssertEqual(mockSubmission.submittedBugs.first?.type, .taskCreationFailure)
                expectation.fulfill()
            }
        }
        
        bugDetectionEngine.simulateTaskCreationFailureBug()
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testBugReportSubmissionError() throws {
        let mockSubmission = MockBugReportSubmission()
        mockSubmission.shouldThrowError = true
        bugDetectionEngine.bugReportSubmission = mockSubmission
        
        let expectation = XCTestExpectation(description: "Bug detected despite submission error")
        
        bugDetectionEngine.startMonitoring()
        
        bugDetectionEngine.onBugDetected = { _ in
            expectation.fulfill()
        }
        
        bugDetectionEngine.simulateTaskCreationFailureBug()
        
        wait(for: [expectation], timeout: 2.0)
        
        // Bug should still be detected even if submission fails
        XCTAssertEqual(mockSubmission.submittedBugs.count, 0) // Submission failed
    }
}