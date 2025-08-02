//
//  ProgressIndicator.swift
//  Myprojects
//
//  Created by Claude on 2025-08-01.
//

import SwiftUI

struct ProgressIndicator: View {
    let project: Project
    
    private var completionPercentage: Double {
        guard !project.tasks.isEmpty else { return 0 }
        let completedCount = project.tasks.filter { $0.status == .completed }.count
        return Double(completedCount) / Double(project.tasks.count)
    }
    
    private var completedTasks: Int {
        project.tasks.filter { $0.status == .completed }.count
    }
    
    private var totalTasks: Int {
        project.tasks.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(completionPercentage * 100))%")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            ProgressView(value: completionPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Label("\(completedTasks) completed", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Spacer()
                
                Label("\(totalTasks - completedTasks) remaining", systemImage: "circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if totalTasks > 0 {
                HStack(spacing: 8) {
                    ForEach(TaskStatus.allCases, id: \.self) { status in
                        let count = project.tasks.filter { $0.status == status }.count
                        if count > 0 {
                            StatusBadge(status: status, count: count)
                        }
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

struct StatusBadge: View {
    let status: TaskStatus
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text("\(count) \(status.rawValue)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(statusColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case .completed: return .green
        case .inProgress: return .blue
        case .blocked: return .red
        default: return .gray
        }
    }
}

#Preview {
    let sampleProject = Project(name: "Sample Project", goal: "Sample goal")
    
    ProgressIndicator(project: sampleProject)
        .padding()
}