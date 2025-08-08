//
//  BugDetectionEngine.swift
//  iOS Auto Bug Discovery Framework
//
//  Created by DELAX Code Generator on 2025-08-06.
//

import Foundation
import SwiftUI
import SwiftData
import OSLog

/// Protocol for bug report submission
public protocol BugReportSubmission {
    func submitBugReport(_ bug: DetectedBug) async throws
}

// MARK: - Detection Events

/// Haptic feedback event for pattern detection
public struct HapticEvent: DetectionEvent {
    public let timestamp = Date()
    public let eventType = "HapticEvent"
    
    public enum HapticType {
        case taskCreated
        case taskCompleted
        case error
        case success
    }
    
    public let hapticType: HapticType
    
    public init(hapticType: HapticType) {
        self.hapticType = hapticType
    }
}

/// SwiftData save operation event
public struct SaveEvent: DetectionEvent {
    public let timestamp = Date()
    public let eventType = "SaveEvent"
    
    public let context: ModelContext?
    public let success: Bool
    public let error: Error?
    public let duration: TimeInterval
    public let entitiesCount: Int
    
    public var failed: Bool { !success }
    public var errorHandled: Bool = false
    
    public init(context: ModelContext?, success: Bool, error: Error? = nil, duration: TimeInterval = 0, entitiesCount: Int = 0) {
        self.context = context
        self.success = success
        self.error = error
        self.duration = duration
        self.entitiesCount = entitiesCount
    }
}

// MARK: - Core Bug Detection Engine

/// Main engine for coordinating bug detection activities
public class BugDetectionEngine: ObservableObject {
    public static let shared = BugDetectionEngine()
    
    @Published public private(set) var isMonitoring = false
    @Published public private(set) var detectedBugs: [DetectedBug] = []
    
    private var detectors: [any BugDetector] = []
    private let eventQueue = DispatchQueue(label: "bug-detection-events", qos: .utility)
    private var recentEvents: [any DetectionEvent] = []
    private let maxRecentEvents = 100
    private let logger = Logger(subsystem: "BugDetection", category: "Engine")
    
    /// Callback for when bugs are detected
    public var onBugDetected: ((DetectedBug) -> Void)?
    
    /// Optional bug report submission handler
    public var bugReportSubmission: BugReportSubmission?
    
    // MARK: - Configuration
    
    public struct Configuration {
        public var enabledDetectors: Set<String> = ["SwiftData", "UIResponsiveness"]
        public var performanceMode: PerformanceMode = .balanced
        public var reportingEnabled = true
        public var aiAnalysisEnabled = false
        
        public enum PerformanceMode {
            case minimal    // <2% CPU overhead
            case balanced   // <5% CPU overhead
            case comprehensive // <10% CPU overhead
        }
        
        public static var `default`: Configuration {
            var config = Configuration()
            config.enabledDetectors = ["SwiftData", "UIResponsiveness"]
            config.performanceMode = .balanced
            config.reportingEnabled = true
            return config
        }
        
        public init() {}
    }
    
    private var configuration: Configuration
    
    private init(configuration: Configuration = .default) {
        self.configuration = configuration
        setupDetectors()
    }
    
    private func setupDetectors() {
        if configuration.enabledDetectors.contains("SwiftData") {
            let swiftDataDetector = SwiftDataAnomalyDetector()
            swiftDataDetector.onBugDetected = { [weak self] bug in
                self?.handleBugDetection(bug)
            }
            detectors.append(swiftDataDetector)
        }
        
        if configuration.enabledDetectors.contains("UIResponsiveness") {
            let uiDetector = UIResponsivenessDetector()
            uiDetector.onBugDetected = { [weak self] bug in
                self?.handleBugDetection(bug)
            }
            detectors.append(uiDetector)
        }
    }
    
    // MARK: - Monitoring Control
    
    /// Start bug detection monitoring
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        logger.info("Starting bug detection monitoring")
        
        for detector in detectors {
            detector.startDetection()
        }
        
        isMonitoring = true
        logger.info("Bug detection monitoring started with \(self.detectors.count) detectors")
    }
    
    /// Stop bug detection monitoring
    public func stopMonitoring() {
        guard isMonitoring else { return }
        
        logger.info("Stopping bug detection monitoring")
        
        for detector in detectors {
            detector.stopDetection()
        }
        
        isMonitoring = false
    }
    
    // MARK: - Event Processing
    
    /// Record a detection event for analysis
    public func recordEvent<T: DetectionEvent>(_ event: T) {
        eventQueue.async { [weak self] in
            self?.processEvent(event)
        }
    }
    
    private func processEvent<T: DetectionEvent>(_ event: T) {
        // Store recent events for pattern detection
        recentEvents.append(event)
        
        // Limit recent events to prevent memory growth
        if recentEvents.count > maxRecentEvents {
            recentEvents.removeFirst(recentEvents.count - maxRecentEvents)
        }
        
        // Process event with all detectors
        for detector in detectors {
            let _ = detector.processEvent(event)
        }
        
        // Check for composite patterns
        checkCompositePatterns()
    }
    
    private func checkCompositePatterns() {
        // Task Creation Failure Pattern: Haptic feedback without successful save
        checkTaskCreationFailurePattern()
    }
    
    private func checkTaskCreationFailurePattern() {
        let recentTime = Date().addingTimeInterval(-5) // Last 5 seconds
        let recentEventsList = recentEvents.filter { $0.timestamp > recentTime }
        
        let hasHapticFeedback = recentEventsList.contains { event in
            guard let hapticEvent = event as? HapticEvent else { return false }
            return hapticEvent.hapticType == .taskCreated
        }
        
        let hasSaveFailure = recentEventsList.contains { event in
            guard let saveEvent = event as? SaveEvent else { return false }
            return saveEvent.failed && !saveEvent.errorHandled
        }
        
        if hasHapticFeedback && hasSaveFailure {
            let bug = DetectedBug(
                type: .taskCreationFailure,
                severity: .high,
                title: "Task creation appears to succeed but actually fails",
                description: "User receives haptic feedback indicating task creation succeeded, but the save operation actually failed. This creates a false sense of success.",
                confidence: 0.9
            )
            
            handleBugDetection(bug)
        }
    }
    
    private func handleBugDetection(_ bug: DetectedBug) {
        Task { @MainActor in
            self.detectedBugs.append(bug)
            self.logger.warning("Bug detected: \(bug.title)")
            self.onBugDetected?(bug)
            
            // Submit bug report if enabled
            if self.configuration.reportingEnabled {
                await self.submitBugReport(bug)
            }
        }
    }
    
    private func submitBugReport(_ bug: DetectedBug) async {
        guard let bugReportSubmission = bugReportSubmission else {
            logger.info("No bug report submission handler configured")
            return
        }
        
        do {
            try await bugReportSubmission.submitBugReport(bug)
            logger.info("Successfully submitted bug report")
        } catch {
            logger.error("Failed to submit bug report: \(error)")
        }
    }
}

// MARK: - Convenience Methods

extension BugDetectionEngine {
    /// Record a haptic feedback event
    public func recordHapticFeedback(_ type: HapticEvent.HapticType) {
        recordEvent(HapticEvent(hapticType: type))
    }
    
    /// Record a SwiftData save operation
    public func recordSaveOperation(context: ModelContext?, success: Bool, error: Error? = nil, duration: TimeInterval = 0, entitiesCount: Int = 0) {
        recordEvent(SaveEvent(context: context, success: success, error: error, duration: duration, entitiesCount: entitiesCount))
    }
    
    // MARK: - Testing and Simulation
    
    /// Test the bug detection framework with simulated events
    public func simulateTaskCreationFailureBug() {
        print("🧪 BugDetectionEngine: Starting task creation failure simulation...")
        
        // Simulate haptic feedback
        recordHapticFeedback(.taskCreated)
        print("✅ BugDetectionEngine: Simulated haptic feedback recorded")
        
        // Wait a brief moment to simulate realistic timing
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
            // Simulate save failure
            let mockError = NSError(domain: "SwiftDataError", code: 1001, userInfo: [
                NSLocalizedDescriptionKey: "Mock save failure for testing"
            ])
            
            self?.recordSaveOperation(
                context: nil,
                success: false,
                error: mockError,
                duration: 0.05,
                entitiesCount: 1
            )
            
            print("✅ BugDetectionEngine: Simulated save failure recorded")
            print("🧪 BugDetectionEngine: Simulation complete - pattern detection should trigger...")
        }
    }
}