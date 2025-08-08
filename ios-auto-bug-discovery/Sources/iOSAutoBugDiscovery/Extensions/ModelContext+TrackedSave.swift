//
//  ModelContext+TrackedSave.swift
//  iOS Auto Bug Discovery Framework
//
//  Created by DELAX Code Generator on 2025-08-06.
//

import Foundation
import SwiftData

// MARK: - ModelContext Extension for Bug Detection Integration

extension ModelContext {
    /// Tracked save method that records metrics for bug detection
    /// Use this instead of save() to enable SwiftData anomaly detection
    public func trackedSave() throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        let preSaveSnapshot = ContextSnapshot(context: self)
        
        do {
            try save()
            
            // Record successful save
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            BugDetectionEngine.shared.recordSaveOperation(
                context: self,
                success: true,
                error: nil,
                duration: duration,
                entitiesCount: preSaveSnapshot.insertedCount + preSaveSnapshot.modifiedCount + preSaveSnapshot.deletedCount
            )
            
        } catch {
            // Record failed save
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            BugDetectionEngine.shared.recordSaveOperation(
                context: self,
                success: false,
                error: error,
                duration: duration,
                entitiesCount: preSaveSnapshot.insertedCount + preSaveSnapshot.modifiedCount + preSaveSnapshot.deletedCount
            )
            
            throw error
        }
    }
}