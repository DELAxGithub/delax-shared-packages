//
//  TaskTemplate.swift
//  Myprojects
//
//  Created by Claude on 2025-08-01.
//

import Foundation
import SwiftData

@Model
class TaskTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var pattern: String                  // テンプレートパターン
    var frequency: Int                   // 使用頻度
    var tags: [String]                   // 分類タグ
    var createdAt: Date
    
    // リレーション
    @Relationship(inverse: \Project.templates)
    var project: Project?
    
    init(name: String, pattern: String, tags: [String] = []) {
        self.id = UUID()
        self.name = name
        self.pattern = pattern
        self.frequency = 0
        self.tags = tags
        self.createdAt = Date()
    }
}