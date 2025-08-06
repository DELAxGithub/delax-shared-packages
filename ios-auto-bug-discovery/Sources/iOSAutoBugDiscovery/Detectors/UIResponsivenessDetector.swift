//
//  UIResponsivenessDetector.swift
//  iOS Auto Bug Discovery Framework
//
//  Created by DELAX Code Generator on 2025-08-06.
//

import Foundation
import UIKit
import QuartzCore
import OSLog

// MARK: - UI Responsiveness Detection Results

/// Types of UI responsiveness issues that can be detected
public enum UIResponsivenessAnomaly: Equatable {
    case frameDrops(count: Int, duration: TimeInterval, context: String)
    case mainActorBlocking(duration: TimeInterval, suspectedCause: String?)
    case sheetConflict(existingSheet: String, newSheet: String)
    case unresponsiveElement(elementType: String, responseTime: TimeInterval)
    case sharingViewFreeze(duration: TimeInterval, transitionType: String)
    
    public static func == (lhs: UIResponsivenessAnomaly, rhs: UIResponsivenessAnomaly) -> Bool {
        switch (lhs, rhs) {
        case (.frameDrops(let lCount, _, _), .frameDrops(let rCount, _, _)):
            return lCount == rCount
        case (.mainActorBlocking(let lDuration, _), .mainActorBlocking(let rDuration, _)):
            return abs(lDuration - rDuration) < 0.1
        case (.sharingViewFreeze(let lDuration, _), .sharingViewFreeze(let rDuration, _)):
            return abs(lDuration - rDuration) < 0.1
        default:
            return false
        }
    }
}

// MARK: - UI Event Types

/// Frame drop event for performance monitoring
public struct FrameDropEvent: DetectionEvent {
    public let timestamp = Date()
    public let eventType = "FrameDropEvent"
    
    public let droppedFrames: Int
    public let duration: TimeInterval
    public let context: String
    
    public init(droppedFrames: Int, duration: TimeInterval, context: String = "Unknown") {
        self.droppedFrames = droppedFrames
        self.duration = duration
        self.context = context
    }
}

/// Sheet presentation event
public struct SheetEvent: DetectionEvent {
    public let timestamp = Date()
    public let eventType = "SheetEvent"
    
    public enum EventType {
        case presented(String)
        case dismissed(String)
        case conflict(existing: String, new: String)
    }
    
    public let sheetEventType: EventType
    
    public init(sheetEventType: EventType) {
        self.sheetEventType = sheetEventType
    }
}

/// Main actor blocking event
public struct MainActorBlockingEvent: DetectionEvent {
    public let timestamp = Date()
    public let eventType = "MainActorBlockingEvent"
    
    public let blockingDuration: TimeInterval
    public let suspectedCause: String?
    public let callStack: [String]
    
    public init(blockingDuration: TimeInterval, suspectedCause: String? = nil) {
        self.blockingDuration = blockingDuration
        self.suspectedCause = suspectedCause
        self.callStack = Array(Thread.callStackSymbols.prefix(15))
    }
}

// MARK: - UI Responsiveness Detector

/// Detector for UI responsiveness issues and performance problems
public class UIResponsivenessDetector: BugDetector {
    public typealias DetectionResult = UIResponsivenessAnomaly
    
    public var isEnabled: Bool = true
    public var onBugDetected: ((DetectedBug) -> Void)?
    
    private var isMonitoring = false
    private var displayLink: CADisplayLink?
    private var lastFrameTime: CFTimeInterval = 0
    private var lastMainThreadCheck: Date?
    private var activeSheets: Set<String> = []
    private var recentSheetEvents: [SheetEvent] = []
    
    private let logger = Logger(subsystem: "BugDetection", category: "UIResponsivenessDetector")
    
    // Configuration
    private let frameDropThreshold: CFTimeInterval = 0.0334 // 2 frames at 60fps = 33ms
    private let mainActorBlockingThreshold: TimeInterval = 1.0 // 1 second
    private let criticalBlockingThreshold: TimeInterval = 2.0 // 2 seconds
    
    public init() {
        logger.info("UIResponsivenessDetector initialized")
    }
    
    public func startDetection() {
        guard !isMonitoring else { return }
        
        startFrameDropMonitoring()
        startMainActorMonitoring()
        
        isMonitoring = true
        logger.info("UI responsiveness detection started")
    }
    
    public func stopDetection() {
        guard isMonitoring else { return }
        
        stopFrameDropMonitoring()
        stopMainActorMonitoring()
        
        isMonitoring = false
        logger.info("UI responsiveness detection stopped")
    }
    
    // MARK: - Frame Drop Monitoring
    
    private func startFrameDropMonitoring() {
        displayLink = CADisplayLink(target: self, selector: #selector(monitorFrameRate))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopFrameDropMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func monitorFrameRate() {
        let currentTime = CACurrentMediaTime()
        
        if lastFrameTime > 0 {
            let frameDuration = currentTime - lastFrameTime
            
            if frameDuration > frameDropThreshold {
                let droppedFrames = Int(frameDuration / 0.0167) // 60fps baseline
                let context = identifyCurrentContext()
                
                // Record frame drop event
                BugDetectionEngine.shared.recordEvent(FrameDropEvent(
                    droppedFrames: droppedFrames,
                    duration: frameDuration,
                    context: context
                ))
            }
        }
        
        lastFrameTime = currentTime
    }
    
    private func identifyCurrentContext() -> String {
        // Try to identify what the user is currently doing
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return "Unknown"
        }
        
        // Look for presented view controllers
        var currentVC = rootViewController
        while let presentedVC = currentVC.presentedViewController {
            currentVC = presentedVC
        }
        
        let vcName = String(describing: type(of: currentVC))
        
        // Identify specific contexts
        if vcName.contains("Sharing") || vcName.contains("Share") {
            return "SharingView"
        } else if vcName.contains("Task") {
            return "TaskView"  
        } else if vcName.contains("Project") {
            return "ProjectView"
        }
        
        return vcName
    }
    
    // MARK: - MainActor Monitoring
    
    private func startMainActorMonitoring() {
        // Use a RunLoop observer to detect main thread blocking
        let observer = CFRunLoopObserverCreateWithHandler(
            kCFAllocatorDefault,
            CFRunLoopActivity.beforeWaiting.rawValue,
            true, // repeat
            0,    // order
            { [weak self] _, _ in
                self?.checkMainThreadResponsiveness()
            }
        )
        
        if let observer = observer {
            CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
        }
        
        // Also use a timer for periodic checks
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkMainThreadResponsiveness()
        }
    }
    
    private func stopMainActorMonitoring() {
        // RunLoop observer will be cleaned up automatically
        lastMainThreadCheck = nil
    }
    
    private func checkMainThreadResponsiveness() {
        let currentTime = Date()
        
        if let lastCheck = lastMainThreadCheck {
            let timeDiff = currentTime.timeIntervalSince(lastCheck)
            
            if timeDiff > mainActorBlockingThreshold {
                let suspectedCause = identifySuspectedBlockingCause()
                
                // Record blocking event
                BugDetectionEngine.shared.recordEvent(MainActorBlockingEvent(
                    blockingDuration: timeDiff,
                    suspectedCause: suspectedCause
                ))
            }
        }
        
        lastMainThreadCheck = currentTime
    }
    
    private func identifySuspectedBlockingCause() -> String? {
        let stackTrace = Thread.callStackSymbols
        
        // Look for common blocking patterns in the stack trace
        for frame in stackTrace.prefix(10) {
            if frame.contains("CloudKit") || frame.contains("CK") {
                return "CloudKit operation on main thread"
            } else if frame.contains("save") && frame.contains("Context") {
                return "SwiftData save operation on main thread"
            } else if frame.contains("URLSession") || frame.contains("Network") {
                return "Network operation on main thread"
            } else if frame.contains("FileManager") || frame.contains("NSData") {
                return "File I/O on main thread"
            }
        }
        
        return nil
    }
    
    // MARK: - Event Processing
    
    public func processEvent<T>(_ event: T) -> [UIResponsivenessAnomaly] {
        guard isEnabled else { return [] }
        
        var anomalies: [UIResponsivenessAnomaly] = []
        
        if let frameDropEvent = event as? FrameDropEvent {
            anomalies.append(contentsOf: processFrameDropEvent(frameDropEvent))
        } else if let blockingEvent = event as? MainActorBlockingEvent {
            anomalies.append(contentsOf: processMainActorBlockingEvent(blockingEvent))
        } else if let sheetEvent = event as? SheetEvent {
            anomalies.append(contentsOf: processSheetEvent(sheetEvent))
        }
        
        // Report anomalies
        for anomaly in anomalies {
            reportAnomaly(anomaly)
        }
        
        return anomalies
    }
    
    private func processFrameDropEvent(_ event: FrameDropEvent) -> [UIResponsivenessAnomaly] {
        var anomalies: [UIResponsivenessAnomaly] = []
        
        // Significant frame drops
        if event.droppedFrames >= 30 { // 0.5 seconds of dropped frames
            anomalies.append(.frameDrops(
                count: event.droppedFrames,
                duration: event.duration,
                context: event.context
            ))
            
            // Check if this is a sharing view freeze
            if event.context == "SharingView" && event.duration > 1.0 {
                anomalies.append(.sharingViewFreeze(
                    duration: event.duration,
                    transitionType: "FrameDrops"
                ))
            }
        }
        
        return anomalies
    }
    
    private func processMainActorBlockingEvent(_ event: MainActorBlockingEvent) -> [UIResponsivenessAnomaly] {
        var anomalies: [UIResponsivenessAnomaly] = []
        
        if event.blockingDuration > mainActorBlockingThreshold {
            anomalies.append(.mainActorBlocking(
                duration: event.blockingDuration,
                suspectedCause: event.suspectedCause
            ))
        }
        
        return anomalies
    }
    
    private func processSheetEvent(_ event: SheetEvent) -> [UIResponsivenessAnomaly] {
        var anomalies: [UIResponsivenessAnomaly] = []
        recentSheetEvents.append(event)
        
        // Keep only recent events (last 10 seconds)
        let cutoffTime = Date().addingTimeInterval(-10)
        recentSheetEvents = recentSheetEvents.filter { $0.timestamp > cutoffTime }
        
        switch event.sheetEventType {
        case .conflict(let existing, let new):
            anomalies.append(.sheetConflict(
                existingSheet: existing,
                newSheet: new
            ))
            
        case .presented(let sheetName):
            activeSheets.insert(sheetName)
            
        case .dismissed(let sheetName):
            activeSheets.remove(sheetName)
        }
        
        return anomalies
    }
    
    // MARK: - Reporting
    
    private func reportAnomaly(_ anomaly: UIResponsivenessAnomaly) {
        let bug = createBugFromAnomaly(anomaly)
        onBugDetected?(bug)
    }
    
    private func createBugFromAnomaly(_ anomaly: UIResponsivenessAnomaly) -> DetectedBug {
        switch anomaly {
        case .frameDrops(let count, let duration, let context):
            var bug = DetectedBug(
                type: .uiResponsiveness,
                severity: count > 60 ? .critical : .high,
                title: "Significant Frame Drops Detected",
                description: "UI became unresponsive with \(count) dropped frames over \(String(format: "%.2f", duration)) seconds in \(context).",
                confidence: 0.9
            )
            
            bug.userImpact = "User experiences stuttering, freezing, or unresponsive UI."
            bug.expectedBehavior = "UI should remain smooth and responsive at all times."
            bug.actualBehavior = "UI freezes or stutters significantly."
            
            return bug
            
        case .mainActorBlocking(let duration, let suspectedCause):
            let description = "Main thread was blocked for \(String(format: "%.2f", duration)) seconds, causing UI to become unresponsive." + (suspectedCause != nil ? " Suspected cause: \(suspectedCause!)" : "")
            
            var bug = DetectedBug(
                type: .uiResponsiveness,
                severity: duration > criticalBlockingThreshold ? .critical : .high,
                title: "Main Thread Blocking Detected",
                description: description,
                confidence: 0.85
            )
            
            bug.userImpact = "User cannot interact with the app during blocking period."
            bug.expectedBehavior = "UI should remain responsive to user interactions."
            bug.actualBehavior = "UI becomes completely unresponsive."
            
            return bug
            
        case .sheetConflict(let existing, let new):
            var bug = DetectedBug(
                type: .uiResponsiveness,
                severity: .medium,
                title: "Sheet Presentation Conflict",
                description: "Attempted to present '\(new)' sheet while '\(existing)' sheet was already active.",
                confidence: 0.8
            )
            
            bug.userImpact = "App may crash or display incorrect UI."
            bug.reproductionSteps = "Multiple sheet presentations attempted simultaneously."
            
            return bug
            
        case .sharingViewFreeze(let duration, let transitionType):
            var bug = DetectedBug(
                type: .sharingViewFreeze,
                severity: .high,
                title: "Sharing View Freeze Detected",
                description: "Sharing view became unresponsive for \(String(format: "%.2f", duration)) seconds during \(transitionType).",
                confidence: 0.9
            )
            
            bug.userImpact = "User cannot return from sharing view, app appears frozen."
            bug.expectedBehavior = "Sharing view should dismiss smoothly and return to project list."
            bug.actualBehavior = "Sharing view freezes, preventing user from continuing."
            bug.reproductionSteps = """
            1. Open project sharing view
            2. Configure sharing settings
            3. Attempt to return to project list
            4. UI freezes during transition
            """
            
            return bug
            
        case .unresponsiveElement(let elementType, let responseTime):
            var bug = DetectedBug(
                type: .uiResponsiveness,
                severity: .medium,
                title: "Unresponsive UI Element",
                description: "\(elementType) element took \(String(format: "%.2f", responseTime)) seconds to respond to user interaction.",
                confidence: 0.7
            )
            
            bug.userImpact = "User experiences delayed or no response to taps/interactions."
            
            return bug
        }
    }
}