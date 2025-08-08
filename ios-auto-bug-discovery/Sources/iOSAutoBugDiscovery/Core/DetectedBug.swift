//
//  DetectedBug.swift
//  iOS Auto Bug Discovery Framework
//
//  Created by DELAX Code Generator on 2025-08-06.
//

import Foundation

// MARK: - Bug Detection Types

/// Types of bugs that can be detected
public enum BugType: String, CaseIterable {
    case swiftDataAnomaly = "SwiftData Anomaly"
    case uiResponsiveness = "UI Responsiveness"
    case cloudKitConflict = "CloudKit Conflict"
    case memoryLeak = "Memory Leak"
    case taskCreationFailure = "Task Creation Failure"
    case sharingViewFreeze = "Sharing View Freeze"
    case ckErrorHandling = "CloudKit Error Handling"
}

/// Severity levels for detected bugs
public enum BugSeverity: String, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    /// Priority value for sorting (higher = more important)
    public var priority: Int {
        switch self {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

/// Represents a detected bug with comprehensive information
public struct DetectedBug {
    public let id = UUID()
    public let type: BugType
    public let severity: BugSeverity
    public let title: String
    public let description: String
    public let timestamp: Date
    public let stackTrace: [String]
    public let confidence: Double
    public var userImpact: String?
    public var reproductionSteps: String?
    public var expectedBehavior: String?
    public var actualBehavior: String?
    public var codeContext: String?
    public var aiAnalysis: AIAnalysisResult?
    
    public init(
        type: BugType,
        severity: BugSeverity,
        title: String,
        description: String,
        confidence: Double = 0.8,
        stackTrace: [String] = Thread.callStackSymbols
    ) {
        self.type = type
        self.severity = severity
        self.title = title
        self.description = description
        self.confidence = confidence
        self.timestamp = Date()
        self.stackTrace = Array(stackTrace.prefix(20)) // Limit stack trace length
    }
}

// MARK: - AI Analysis

/// Result of AI analysis for a detected bug
public struct AIAnalysisResult {
    public let rootCause: String
    public let suggestedFix: String
    public let preventionStrategy: String
    public let confidence: Double
    
    public init(rootCause: String, suggestedFix: String, preventionStrategy: String, confidence: Double) {
        self.rootCause = rootCause
        self.suggestedFix = suggestedFix
        self.preventionStrategy = preventionStrategy
        self.confidence = confidence
    }
    
    /// Fallback analysis when AI is not available
    public static func fallback(for bug: DetectedBug) -> AIAnalysisResult {
        return AIAnalysisResult(
            rootCause: "Analysis pending - \(bug.type.rawValue) detected",
            suggestedFix: "Manual investigation required",
            preventionStrategy: "Implement proper error handling",
            confidence: 0.3
        )
    }
}