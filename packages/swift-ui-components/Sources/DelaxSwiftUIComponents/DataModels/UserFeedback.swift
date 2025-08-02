//
//  UserFeedback.swift
//  Myprojects
//
//  Created by Claude on 2025-08-01.
//

import Foundation
import SwiftData

@Model
class UserFeedback {
    @Attribute(.unique) var id: UUID
    var taskId: UUID
    var action: FeedbackAction           // 修正、削除、完了など
    var originalValue: String?
    var modifiedValue: String?
    var timestamp: Date
    
    // リレーション
    @Relationship(inverse: \Task.feedback)
    var task: Task?
    
    init(taskId: UUID, action: FeedbackAction, originalValue: String? = nil, modifiedValue: String? = nil) {
        self.id = UUID()
        self.taskId = taskId
        self.action = action
        self.originalValue = originalValue
        self.modifiedValue = modifiedValue
        self.timestamp = Date()
    }
}