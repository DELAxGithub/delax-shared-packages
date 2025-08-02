//
//  AIContext.swift
//  Myprojects
//
//  Created by Claude on 2025-08-01.
//

import Foundation
import SwiftData

@Model
class AIContext {
    @Attribute(.unique) var id: UUID
    var projectId: UUID
    var learningData: Data?              // 機械学習用データ
    var lastUpdated: Date
    
    // リレーション
    @Relationship(inverse: \Project.aiContext)
    var project: Project?
    
    init(projectId: UUID) {
        self.id = UUID()
        self.projectId = projectId
        self.lastUpdated = Date()
    }
}