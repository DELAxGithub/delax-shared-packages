// CloudKitSharingKit - Full Featured Implementation Template
// CloudKit共有機能の全機能を実装するテンプレート

import SwiftUI
import DelaxCloudKitSharingKit
import CloudKit
import Combine

// MARK: - Enhanced Data Model

struct Task: SharableRecord {
    let id: String
    var record: CKRecord?
    var shareRecord: CKShare?
    
    // Task properties
    var title: String
    var description: String
    var isCompleted: Bool
    var priority: Priority
    var dueDate: Date?
    var createdAt: Date
    var modifiedAt: Date
    
    static var recordType: String { "Task" }
    
    enum Priority: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
    
    // Initializers
    init(title: String, description: String = "", priority: Priority = .medium, dueDate: Date? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.isCompleted = false
        self.priority = priority
        self.dueDate = dueDate
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.record = nil
        self.shareRecord = nil
    }
    
    init(from record: CKRecord, shareRecord: CKShare? = nil) {
        self.id = record.recordID.recordName
        self.title = record["title"] as? String ?? ""
        self.description = record["description"] as? String ?? ""
        self.isCompleted = (record["isCompleted"] as? Int64) == 1
        self.priority = Priority(rawValue: record["priority"] as? String ?? "medium") ?? .medium
        self.dueDate = record["dueDate"] as? Date
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.modifiedAt = record["modifiedAt"] as? Date ?? Date()
        self.record = record
        self.shareRecord = shareRecord
    }
    
    func toCKRecord(zoneID: CKRecordZone.ID?) -> CKRecord {
        let record: CKRecord
        
        if let existingRecord = self.record {
            record = existingRecord
        } else if let zoneID = zoneID {
            let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
            record = CKRecord(recordType: Task.recordType, recordID: recordID)
        } else {
            record = CKRecord(recordType: Task.recordType)
        }
        
        record["title"] = title
        record["description"] = description
        record["isCompleted"] = isCompleted ? 1 : 0
        record["priority"] = priority.rawValue
        record["dueDate"] = dueDate
        record["createdAt"] = createdAt
        record["modifiedAt"] = Date()
        
        return record
    }
}

// MARK: - View Model

@MainActor
class TaskViewModel: ObservableObject {
    private let sharingManager: CloudKitSharingManager<Task>
    
    @Published var tasks: [Task] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    // Filtering and sorting
    @Published var showCompletedTasks = true
    @Published var selectedPriority: Task.Priority?
    @Published var sortOrder: SortOrder = .dueDate
    
    enum SortOrder: String, CaseIterable {
        case dueDate = "Due Date"
        case priority = "Priority"
        case title = "Title"
        case createdAt = "Created"
    }
    
    init(containerIdentifier: String) {
        self.sharingManager = CloudKitSharingManager<Task>(
            containerIdentifier: containerIdentifier,
            customZoneName: "TasksZone"
        )
        
        // Monitor CloudKit availability
        sharingManager.$isCloudKitAvailable
            .sink { [weak self] isAvailable in
                if isAvailable {
                    Task {
                        await self?.loadTasks()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    var filteredTasks: [Task] {
        var filtered = tasks
        
        // Filter by completion status
        if !showCompletedTasks {
            filtered = filtered.filter { !$0.isCompleted }
        }
        
        // Filter by priority
        if let selectedPriority = selectedPriority {
            filtered = filtered.filter { $0.priority == selectedPriority }
        }
        
        // Sort
        switch sortOrder {
        case .dueDate:
            filtered.sort { lhs, rhs in
                guard let lhsDate = lhs.dueDate else { return false }
                guard let rhsDate = rhs.dueDate else { return true }
                return lhsDate < rhsDate
            }
        case .priority:
            filtered.sort { lhs, rhs in
                let priorityOrder: [Task.Priority] = [.high, .medium, .low]
                let lhsIndex = priorityOrder.firstIndex(of: lhs.priority) ?? 0
                let rhsIndex = priorityOrder.firstIndex(of: rhs.priority) ?? 0
                return lhsIndex < rhsIndex
            }
        case .title:
            filtered.sort { $0.title < $1.title }
        case .createdAt:
            filtered.sort { $0.createdAt > $1.createdAt }
        }
        
        return filtered
    }
    
    // MARK: - Task Operations
    
    func loadTasks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await sharingManager.fetchRecords()
            tasks = sharingManager.records
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func saveTask(_ task: Task) async {
        do {
            _ = try await sharingManager.saveRecord(task)
            await loadTasks()
        } catch {
            handleError(error)
        }
    }
    
    func deleteTask(_ task: Task) async {
        do {
            try await sharingManager.deleteRecord(task)
            await loadTasks()
        } catch {
            handleError(error)
        }
    }
    
    func toggleTaskCompletion(_ task: Task) async {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        updatedTask.modifiedAt = Date()
        await saveTask(updatedTask)
    }
    
    // MARK: - Sharing Operations
    
    func shareTask(_ task: Task) async throws -> CKShare {
        return try await sharingManager.startSharing(record: task)
    }
    
    func stopSharingTask(_ task: Task) async {
        do {
            try await sharingManager.stopSharing(record: task)
            await loadTasks()
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        print("TaskViewModel Error: \\(error)")
        
        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated:
                errorMessage = "Please sign in to iCloud in Settings"
            case .networkFailure, .networkUnavailable:
                errorMessage = "Network connection required"
            case .quotaExceeded:
                errorMessage = "iCloud storage is full"
            default:
                errorMessage = ckError.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
        
        showingError = true
    }
}

// MARK: - Main App

@main
struct TaskSharingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Main Views

struct ContentView: View {
    @StateObject private var viewModel = TaskViewModel(
        containerIdentifier: "iCloud.com.yourteam.TaskApp"  // ⚠️ Change this
    )
    
    var body: some View {
        NavigationView {
            TaskListView()
                .environmentObject(viewModel)
        }
    }
}

struct TaskListView: View {
    @EnvironmentObject private var viewModel: TaskViewModel
    @State private var showingNewTaskSheet = false
    @State private var showingFilterSheet = false
    @State private var showingSharingView = false
    @State private var shareToPresent: CKShare?
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading tasks...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredTasks.isEmpty {
                EmptyStateView()
            } else {
                List {
                    ForEach(viewModel.filteredTasks) { task in
                        TaskRowView(task: task)
                    }
                    .onDelete(perform: deleteTasks)
                }
            }
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Filter") {
                    showingFilterSheet = true
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    showingNewTaskSheet = true
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadTasks()
            }
        }
        .refreshable {
            await viewModel.loadTasks()
        }
        .sheet(isPresented: $showingNewTaskSheet) {
            NewTaskView()
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterView()
        }
        .sheet(isPresented: $showingSharingView) {
            if let share = shareToPresent {
                CloudSharingView(
                    share: share,
                    container: viewModel.sharingManager.container,
                    onShareSaved: {
                        Task {
                            await viewModel.loadTasks()
                        }
                    },
                    onShareStopped: {
                        Task {
                            await viewModel.loadTasks()
                        }
                    }
                )
            }
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        for index in offsets {
            let task = viewModel.filteredTasks[index]
            Task {
                await viewModel.deleteTask(task)
            }
        }
    }
}

struct TaskRowView: View {
    @EnvironmentObject private var viewModel: TaskViewModel
    let task: Task
    @State private var showingSharingView = false
    @State private var shareToPresent: CKShare?
    
    var body: some View {
        HStack {
            Button(action: {
                Task {
                    await viewModel.toggleTaskCompletion(task)
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    // Priority indicator
                    Label(task.priority.displayName, systemImage: "flag.fill")
                        .font(.caption)
                        .foregroundColor(task.priority.color)
                    
                    Spacer()
                    
                    // Due date
                    if let dueDate = task.dueDate {
                        Label(
                            dueDate.formatted(date: .abbreviated, time: .omitted),
                            systemImage: "calendar"
                        )
                        .font(.caption)
                        .foregroundColor(dueDate < Date() ? .red : .secondary)
                    }
                    
                    // Sharing status
                    if task.isShared {
                        Label("Shared", systemImage: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            // Share button
            Button(action: shareTask) {
                Image(systemName: task.isShared ? "person.2.fill" : "person.2")
                    .foregroundColor(task.isShared ? .blue : .gray)
            }
        }
        .padding(.vertical, 2)
        .sheet(isPresented: $showingSharingView) {
            if let share = shareToPresent {
                CloudSharingView(
                    share: share,
                    container: viewModel.sharingManager.container
                )
            }
        }
    }
    
    private func shareTask() {
        Task {
            do {
                if let existingShare = task.shareRecord {
                    shareToPresent = existingShare
                } else {
                    let share = try await viewModel.shareTask(task)
                    shareToPresent = share
                }
                showingSharingView = true
            } catch {
                print("Sharing error: \\(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No tasks yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the Add button to create your first task")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NewTaskView: View {
    @EnvironmentObject private var viewModel: TaskViewModel
    @Environment(\\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority: Task.Priority = .medium
    @State private var dueDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var hasDueDate = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Task.Priority.allCases, id: \\.self) { priority in
                            Label(priority.displayName, systemImage: "flag.fill")
                                .foregroundColor(priority.color)
                                .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty || isLoading)
                }
            }
        }
    }
    
    private func saveTask() {
        isLoading = true
        Task {
            let task = Task(
                title: title,
                description: description,
                priority: priority,
                dueDate: hasDueDate ? dueDate : nil
            )
            
            await viewModel.saveTask(task)
            
            await MainActor.run {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct FilterView: View {
    @EnvironmentObject private var viewModel: TaskViewModel
    @Environment(\\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section("Show Tasks") {
                    Toggle("Completed tasks", isOn: $viewModel.showCompletedTasks)
                }
                
                Section("Filter by Priority") {
                    Picker("Priority", selection: $viewModel.selectedPriority) {
                        Text("All Priorities")
                            .tag(nil as Task.Priority?)
                        
                        ForEach(Task.Priority.allCases, id: \\.self) { priority in
                            Label(priority.displayName, systemImage: "flag.fill")
                                .foregroundColor(priority.color)
                                .tag(priority as Task.Priority?)
                        }
                    }
                }
                
                Section("Sort By") {
                    Picker("Sort Order", selection: $viewModel.sortOrder) {
                        ForEach(TaskViewModel.SortOrder.allCases, id: \\.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Setup Instructions

/*
 
 📋 Full Featured Setup Instructions:

 1. CloudKit Dashboard Setup:
    - Create "Task" record type with these fields:
      - title (String, Indexed, Required)
      - description (String)
      - isCompleted (Int64)
      - priority (String, Indexed)
      - dueDate (Date/Time, Indexed)
      - createdAt (Date/Time, Indexed)
      - modifiedAt (Date/Time, Indexed)
    - Enable "Shared" for the Task record type

 2. Xcode Setup:
    - Enable CloudKit capability
    - Set container identifier

 3. Code Customization:
    - Replace "iCloud.com.yourteam.TaskApp" with your actual container ID
    - Customize Task properties as needed
    - Add additional features (notifications, widgets, etc.)

 4. Advanced Features Included:
    - Complete CRUD operations
    - Filtering and sorting
    - Offline support
    - Error handling
    - Loading states
    - Sharing management

 */