//
//  ProjectCard.swift
//  Myprojects
//
//  Created by Claude on 2025-08-01.
//

import SwiftUI

struct ProjectCard: View {
    let project: Project
    
    private var completionPercentage: Double {
        guard !project.tasks.isEmpty else { return 0 }
        let completedCount = project.tasks.filter { $0.status == .completed }.count
        return Double(completedCount) / Double(project.tasks.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(project.status.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(4)
            }
            
            Text(project.goal)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                ProgressRing(progress: completionPercentage, size: 24)
                Text("\(project.tasks.filter { $0.status == .completed }.count)/\(project.tasks.count) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(project.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(Color.primary.opacity(0.6))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var statusColor: Color {
        switch project.status {
        case .active: return .blue
        case .completed: return .green
        case .paused: return .orange
        case .cancelled: return .red
        default: return .gray
        }
    }
}

#Preview {
    let sampleProject = Project(name: "Sample Project", goal: "This is a sample project goal")
    
    ProjectCard(project: sampleProject)
        .padding()
}