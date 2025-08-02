//
//  DataManager.swift
//  Myprojects
//
//  Created by Claude on 2025-08-01.
//

import Foundation
import SwiftData

@MainActor
class DataManager: ObservableObject {
    static var shared: DataManager!
    
    private let modelContainer: ModelContainer
    
    private lazy var modelContext: ModelContext = {
        modelContainer.mainContext
    }()
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    func save<T: PersistentModel>(_ model: T) {
        modelContext.insert(model)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save: \(error)")
        }
    }
    
    func delete<T: PersistentModel>(_ model: T) {
        modelContext.delete(model)
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete: \(error)")
        }
    }
    
    func fetch<T: PersistentModel>(_ modelType: T.Type) -> [T] {
        do {
            let descriptor = FetchDescriptor<T>()
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch: \(error)")
            return []
        }
    }
    
    var context: ModelContext {
        return modelContext
    }
}