//
//  JSONImportService.swift
//  Myprojects
//
//  Created by Claude on 2025-08-01.
//

import Foundation

enum ImportError: LocalizedError {
    case invalidJSON
    case missingRequiredFields
    case modelCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON: return "Invalid JSON format"
        case .missingRequiredFields: return "Required fields missing"
        case .modelCreationFailed: return "Failed to create models"
        }
    }
}

@MainActor
class JSONImportService: ObservableObject {
    private let dataManager: DataManager
    
    init(dataManager: DataManager? = nil) {
        self.dataManager = dataManager ?? DataManager.shared
    }
    
    func importProject(from data: Data) async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let importData = try decoder.decode(ProjectImportData.self, from: data)
            
            // Project作成
            let project = Project(
                name: importData.project.name,
                goal: importData.project.goal,
                status: ProjectStatus(rawValue: importData.project.status) ?? .planning
            )
            
            if let startDate = importData.project.startDate {
                project.startDate = startDate
            }
            if let endDate = importData.project.endDate {
                project.endDate = endDate
            }
            
            // Tasks作成
            var taskMap: [String: Task] = [:] // タスクの親子関係処理用
            
            for (_, taskData) in importData.project.tasks.enumerated() {
                let task = Task(
                    title: taskData.title,
                    status: TaskStatus(rawValue: taskData.status) ?? .pending,
                    priority: TaskPriority(rawValue: taskData.priority) ?? .medium,
                    aiGenerated: taskData.aiGenerated,
                    hierarchyLevel: taskData.hierarchyLevel,
                    sortOrder: taskData.sortOrder
                )
                
                task.notes = taskData.notes
                task.estimatedDuration = taskData.estimatedDuration
                task.project = project
                
                taskMap[taskData.title] = task
                
                // Subtasks処理
                for (_, subtaskData) in taskData.subtasks.enumerated() {
                    let subtask = Task(
                        title: subtaskData.title,
                        aiGenerated: subtaskData.aiGenerated,
                        hierarchyLevel: subtaskData.hierarchyLevel,
                        sortOrder: subtaskData.sortOrder
                    )
                    subtask.notes = subtaskData.notes
                    subtask.project = project
                    subtask.parentTask = task
                }
            }
            
            dataManager.save(project)
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            throw ImportError.invalidJSON
        } catch {
            print("Import error: \(error)")
            throw ImportError.modelCreationFailed
        }
    }
    
    func importProjectFromFile(url: URL) async throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.invalidJSON
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let data = try Data(contentsOf: url)
        try await importProject(from: data)
    }
}