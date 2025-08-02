//
//  ProjectImportData.swift
//  Myprojects
//
//  Created by Claude on 2025-08-01.
//

import Foundation

struct ProjectImportData: Codable {
    let project: ProjectData
    
    struct ProjectData: Codable {
        let name: String
        let goal: String
        let status: String
        let startDate: Date?
        let endDate: Date?
        let tasks: [TaskData]
    }
    
    struct TaskData: Codable {
        let title: String
        let notes: String?
        let status: String
        let priority: String
        let estimatedDuration: TimeInterval?
        let hierarchyLevel: Int
        let sortOrder: Int
        let aiGenerated: Bool
        let subtasks: [SubtaskData]
    }
    
    struct SubtaskData: Codable {
        let title: String
        let notes: String?
        let hierarchyLevel: Int
        let sortOrder: Int
        let aiGenerated: Bool
    }
}