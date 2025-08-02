//
//  ProjectStatus.swift
//  Myprojects
//
//  Created by Claude on 2025-08-01.
//

import Foundation

enum ProjectStatus: String, CaseIterable, Codable {
    case planning = "planning"
    case active = "active"
    case paused = "paused"
    case completed = "completed"
    case cancelled = "cancelled"
}

enum TaskStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case inProgress = "in_progress"
    case blocked = "blocked"
    case completed = "completed"
    case cancelled = "cancelled"
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
}

enum FeedbackAction: String, CaseIterable, Codable {
    case modified = "modified"
    case deleted = "deleted"
    case completed = "completed"
    case reordered = "reordered"
    case priorityChanged = "priority_changed"
}