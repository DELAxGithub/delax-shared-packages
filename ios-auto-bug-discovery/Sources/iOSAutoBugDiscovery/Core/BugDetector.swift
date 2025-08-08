//
//  BugDetector.swift
//  iOS Auto Bug Discovery Framework
//
//  Created by DELAX Code Generator on 2025-08-06.
//

import Foundation

// MARK: - Core Protocols

/// Protocol for implementing custom bug detectors
public protocol BugDetector: AnyObject {
    associatedtype DetectionResult: Equatable
    
    /// Whether this detector is currently enabled
    var isEnabled: Bool { get set }
    
    /// Callback when a bug is detected
    var onBugDetected: ((DetectedBug) -> Void)? { get set }
    
    /// Start bug detection monitoring
    func startDetection()
    
    /// Stop bug detection monitoring
    func stopDetection()
    
    /// Process an event and return detection results
    func processEvent<T>(_ event: T) -> [DetectionResult]
}

// MARK: - Detection Events

/// Base protocol for all detection events
public protocol DetectionEvent {
    var timestamp: Date { get }
    var eventType: String { get }
}