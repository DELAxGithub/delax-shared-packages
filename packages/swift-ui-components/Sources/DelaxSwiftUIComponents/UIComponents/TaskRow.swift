//
//  TaskRow.swift
//  Myprojects
//
//  Created by Claude on 2025-08-01.
//

import SwiftUI

struct TaskRow: View {
    let task: Task
    let level: Int
    let onToggle: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.status == .completed ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough(task.status == .completed)
                    .foregroundColor(task.status == .completed ? .secondary : .primary)
                
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Priority indicator
            if task.priority != .medium {
                priorityIndicator
            }
            
            if task.aiGenerated {
                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .padding(.leading, CGFloat(level * 16))
    }
    
    @ViewBuilder
    private var priorityIndicator: some View {
        Circle()
            .fill(priorityColor)
            .frame(width: 8, height: 8)
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .urgent: return .red
        case .high: return .orange
        case .low: return .blue
        default: return .clear
        }
    }
}

#Preview {
    let sampleTask = Task(title: "Sample Task", priority: .high, hierarchyLevel: 0)
    
    VStack {
        TaskRow(task: sampleTask, level: 0, onToggle: {}, onEdit: {})
        TaskRow(task: sampleTask, level: 1, onToggle: {}, onEdit: {})
        TaskRow(task: sampleTask, level: 2, onToggle: {}, onEdit: {})
    }
    .padding()
    .onAppear {
        sampleTask.notes = "This is a sample note"
    }
}