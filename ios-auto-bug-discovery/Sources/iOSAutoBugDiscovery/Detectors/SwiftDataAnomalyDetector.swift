//
//  SwiftDataAnomalyDetector.swift
//  iOS Auto Bug Discovery Framework
//
//  Created by DELAX Code Generator on 2025-08-06.
//

import Foundation
import SwiftData
import OSLog

// MARK: - SwiftData Detection Results

/// Types of SwiftData anomalies that can be detected
public enum SwiftDataAnomaly: Equatable {
    case silentSaveFailure(context: String, error: Error, stackTrace: [String])
    case entityNotPersisted(entityType: String, timeElapsed: TimeInterval)
    case batchOperationPartialFailure(successCount: Int, failureCount: Int)
    case relationshipIntegrityViolation(entityType: String, relationshipName: String)
    case taskCreationFailure(title: String, error: Error?, userExpectedSuccess: Bool)
    
    public static func == (lhs: SwiftDataAnomaly, rhs: SwiftDataAnomaly) -> Bool {
        switch (lhs, rhs) {
        case (.silentSaveFailure(let lContext, _, _), .silentSaveFailure(let rContext, _, _)):
            return lContext == rContext
        case (.entityNotPersisted(let lType, _), .entityNotPersisted(let rType, _)):
            return lType == rType
        case (.taskCreationFailure(let lTitle, _, _), .taskCreationFailure(let rTitle, _, _)):
            return lTitle == rTitle
        default:
            return false
        }
    }
}

// MARK: - Context Snapshot

/// Snapshot of ModelContext state for comparison
public struct ContextSnapshot {
    public let insertedCount: Int
    public let deletedCount: Int
    public let modifiedCount: Int
    public let timestamp: Date
    public let contextId: ObjectIdentifier?
    
    public init(context: ModelContext?) {
        if let context = context {
            self.insertedCount = context.insertedModelsArray.count
            self.deletedCount = context.deletedModelsArray.count  
            self.modifiedCount = context.changedModelsArray.count
            self.contextId = ObjectIdentifier(context)
        } else {
            self.insertedCount = 0
            self.deletedCount = 0
            self.modifiedCount = 0
            self.contextId = nil
        }
        self.timestamp = Date()
    }
}

// MARK: - SwiftData Anomaly Detector

/// Detector for SwiftData-related anomalies and issues
public class SwiftDataAnomalyDetector: BugDetector {
    public typealias DetectionResult = SwiftDataAnomaly
    
    public var isEnabled: Bool = true
    public var onBugDetected: ((DetectedBug) -> Void)?
    
    private var isMonitoring = false
    private var operationHistory: [SaveOperationRecord] = []
    private let maxHistorySize = 50
    private let logger = Logger(subsystem: "BugDetection", category: "SwiftDataDetector")
    
    public init() {
        logger.info("SwiftDataAnomalyDetector initialized")
    }
    
    public func startDetection() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        logger.info("SwiftData anomaly detection started")
    }
    
    public func stopDetection() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        logger.info("SwiftData anomaly detection stopped")
    }
    
    // MARK: - Event Processing
    
    public func processEvent<T>(_ event: T) -> [SwiftDataAnomaly] {
        guard isEnabled, let saveEvent = event as? SaveEvent else { return [] }
        
        var anomalies: [SwiftDataAnomaly] = []
        
        // Record operation
        let operation = SaveOperationRecord(
            timestamp: saveEvent.timestamp,
            success: saveEvent.success,
            error: saveEvent.error,
            duration: saveEvent.duration,
            entitiesCount: saveEvent.entitiesCount,
            contextSnapshot: ContextSnapshot(context: saveEvent.context)
        )
        
        recordOperation(operation)
        
        // Detect anomalies
        anomalies.append(contentsOf: detectSilentFailures(operation))
        anomalies.append(contentsOf: detectTaskCreationFailures(operation))
        anomalies.append(contentsOf: detectEntityPersistenceIssues(operation))
        
        // Report detected anomalies
        for anomaly in anomalies {
            reportAnomaly(anomaly)
        }
        
        return anomalies
    }
    
    // MARK: - Operation Recording
    
    private func recordOperation(_ operation: SaveOperationRecord) {
        operationHistory.append(operation)
        
        // Limit history size to prevent memory growth
        if operationHistory.count > maxHistorySize {
            operationHistory.removeFirst(operationHistory.count - maxHistorySize)
        }
    }
    
    // MARK: - Anomaly Detection Methods
    
    private func detectSilentFailures(_ operation: SaveOperationRecord) -> [SwiftDataAnomaly] {
        var anomalies: [SwiftDataAnomaly] = []
        
        // Silent save failure: operation failed but no error handling was detected
        if !operation.success, let error = operation.error {
            let contextId = operation.contextSnapshot.contextId?.debugDescription ?? "unknown"
            
            anomalies.append(.silentSaveFailure(
                context: contextId,
                error: error,
                stackTrace: Thread.callStackSymbols
            ))
            
            logger.warning("Detected silent save failure: \(error.localizedDescription)")
        }
        
        return anomalies
    }
    
    private func detectTaskCreationFailures(_ operation: SaveOperationRecord) -> [SwiftDataAnomaly] {
        var anomalies: [SwiftDataAnomaly] = []
        
        // Task creation failure: save failed but user expects success
        if !operation.success && operation.contextSnapshot.insertedCount > 0 {
            // Check if this looks like a task creation scenario
            let recentTime = Date().addingTimeInterval(-2) // Last 2 seconds
            if operation.timestamp > recentTime {
                anomalies.append(.taskCreationFailure(
                    title: "Task creation save failed",
                    error: operation.error,
                    userExpectedSuccess: true
                ))
                
                logger.warning("Detected potential task creation failure")
            }
        }
        
        return anomalies
    }
    
    private func detectEntityPersistenceIssues(_ operation: SaveOperationRecord) -> [SwiftDataAnomaly] {
        var anomalies: [SwiftDataAnomaly] = []
        
        // Entity not persisted: entities were inserted but save failed
        if !operation.success && operation.contextSnapshot.insertedCount > 0 {
            let timeElapsed = Date().timeIntervalSince(operation.timestamp)
            
            if timeElapsed > 1.0 { // Entity not persisted after 1 second
                anomalies.append(.entityNotPersisted(
                    entityType: "Mixed", // Could be enhanced to track specific types
                    timeElapsed: timeElapsed
                ))
            }
        }
        
        return anomalies
    }
    
    // MARK: - Reporting
    
    private func reportAnomaly(_ anomaly: SwiftDataAnomaly) {
        let bug = createBugFromAnomaly(anomaly)
        onBugDetected?(bug)
    }
    
    private func createBugFromAnomaly(_ anomaly: SwiftDataAnomaly) -> DetectedBug {
        switch anomaly {
        case .silentSaveFailure(let context, let error, let stackTrace):
            return DetectedBug(
                type: .swiftDataAnomaly,
                severity: .high,
                title: "SwiftData Silent Save Failure",
                description: "A ModelContext save operation failed in context \(context) with error: \(error.localizedDescription). The error was not properly handled, leading to potential data loss or inconsistent app state.",
                confidence: 0.9,
                stackTrace: stackTrace
            )
            
        case .taskCreationFailure(let title, let error, _):
            var bug = DetectedBug(
                type: .taskCreationFailure,
                severity: .high,
                title: "Task Creation Failed Silently",
                description: "User attempted to create task '\(title)' but the save operation failed\(error != nil ? " with error: \(error!.localizedDescription)" : ""). User may believe the task was created successfully.",
                confidence: 0.85
            )
            
            bug.userImpact = "User believes task was created but it actually failed. This leads to confusion and lost data."
            bug.expectedBehavior = "Task creation should either succeed or show a clear error message to the user."
            bug.actualBehavior = "Task creation fails but user receives success feedback (haptic feedback)."
            bug.reproductionSteps = """
            1. Attempt to create a new task
            2. Save operation fails due to SwiftData error
            3. User receives haptic feedback indicating success
            4. Task is not actually saved to the database
            """
            
            return bug
            
        case .entityNotPersisted(let entityType, let timeElapsed):
            return DetectedBug(
                type: .swiftDataAnomaly,
                severity: .medium,
                title: "Entity Not Persisted",
                description: "\(entityType) entity was created in memory but not persisted to the database after \(String(format: "%.1f", timeElapsed)) seconds.",
                confidence: 0.7
            )
            
        case .batchOperationPartialFailure(let successCount, let failureCount):
            return DetectedBug(
                type: .swiftDataAnomaly,
                severity: .medium,
                title: "Batch Operation Partial Failure",
                description: "Batch operation completed with \(successCount) successes and \(failureCount) failures, indicating inconsistent data state.",
                confidence: 0.8
            )
            
        case .relationshipIntegrityViolation(let entityType, let relationshipName):
            return DetectedBug(
                type: .swiftDataAnomaly,
                severity: .high,
                title: "Relationship Integrity Violation",
                description: "Required relationship '\(relationshipName)' on \(entityType) was set to nil, violating data integrity constraints.",
                confidence: 0.9
            )
        }
    }
}

// MARK: - Operation Record

private struct SaveOperationRecord {
    let timestamp: Date
    let success: Bool
    let error: Error?
    let duration: TimeInterval
    let entitiesCount: Int
    let contextSnapshot: ContextSnapshot
}