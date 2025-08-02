//
//  Project.swift
//  Myprojects
//
//  Created by Claude on 2025-08-01.
//

import Foundation
import SwiftData

@Model
class Project {
    @Attribute(.unique) var id: UUID
    var name: String
    var goal: String                     // AI分解の元となる目標
    var startDate: Date?
    var endDate: Date?
    var status: ProjectStatus
    var reminderId: String?              // Apple Reminders連携ID
    var createdAt: Date
    var updatedAt: Date
    
    // リレーション
    @Relationship(deleteRule: .cascade)
    var tasks: [Task] = []
    
    @Relationship(deleteRule: .cascade)
    var templates: [TaskTemplate] = []
    
    @Relationship(deleteRule: .cascade)
    var aiContext: AIContext?
    
    init(name: String, goal: String, status: ProjectStatus = .planning) {
        self.id = UUID()
        self.name = name
        self.goal = goal
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}