//
//  TaskHierarchyView.swift
//  Myprojects
//
//  Created by Claude on 2025-08-01.
//

import SwiftUI

public struct TaskHierarchyView: View {
    let project: Project
    
    private var sortedTasks: [Task] {
        project.tasks.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tasks")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(project.tasks.filter { $0.status == .completed }.count)/\(project.tasks.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if sortedTasks.isEmpty {
                VStack {
                    Image(systemName: "checklist")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No tasks yet")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(sortedTasks) { task in
                        TaskRow(
                            task: task,
                            level: task.hierarchyLevel,
                            onToggle: { },
                            onEdit: { }
                        )
                        .padding(.leading, CGFloat(task.hierarchyLevel * 16))
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    let sampleProject = Project(name: "Sample Project", goal: "Sample goal")
    
    VStack {
        Text("TaskHierarchyView Preview")
        Text("Project: \(sampleProject.name)")
    }
    .padding()
}