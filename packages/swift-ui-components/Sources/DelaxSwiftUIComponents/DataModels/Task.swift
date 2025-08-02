//
//  Task.swift
//  Myprojects
//
//  Created by Claude on 2025-08-01.
//

import Foundation
import SwiftData

@Model
class Task {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String?
    var status: TaskStatus
    var priority: TaskPriority
    var dueDate: Date?
    var completedAt: Date?
    var estimatedDuration: TimeInterval?
    var aiGenerated: Bool                // AI生成タスクかどうか
    var reminderId: String?              // Apple Reminders連携ID
    var hierarchyLevel: Int              // WBS階層レベル
    var sortOrder: Int                   // 表示順序
    var createdAt: Date
    var updatedAt: Date
    
    // リレーション
    @Relationship(inverse: \Project.tasks)
    var project: Project?
    
    @Relationship(inverse: \Task.subtasks)
    var parentTask: Task?
    
    @Relationship(deleteRule: .cascade)
    var subtasks: [Task] = []
    
    @Relationship(deleteRule: .cascade)
    var feedback: [UserFeedback] = []
    
    init(
        title: String,
        status: TaskStatus = .pending,
        priority: TaskPriority = .medium,
        aiGenerated: Bool = false,
        hierarchyLevel: Int = 0,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.status = status
        self.priority = priority
        self.aiGenerated = aiGenerated
        self.hierarchyLevel = hierarchyLevel
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}