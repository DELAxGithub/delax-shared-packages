import SwiftUI
import DelaxCloudKitSharingKit

struct NoteDetailView: View {
    @EnvironmentObject private var sharingManager: CloudKitSharingManager<Note>
    @Environment(\\.presentationMode) var presentationMode
    
    let note: Note
    @State private var editedTitle: String
    @State private var editedContent: String
    @State private var isEditing = false
    @State private var isLoading = false
    @State private var hasChanges = false
    
    init(note: Note) {
        self.note = note
        self._editedTitle = State(initialValue: note.title)
        self._editedContent = State(initialValue: note.content)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isEditing {
                    editingView
                } else {
                    readOnlyView
                }
            }
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        if hasChanges && isEditing {
                            saveChanges()
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        HStack {
                            if hasChanges {
                                Button("Save") {
                                    saveChanges()
                                }
                                .disabled(editedTitle.isEmpty || isLoading)
                            }
                            
                            Button("Cancel") {
                                cancelEditing()
                            }
                            .disabled(isLoading)
                        }
                    } else {
                        Button("Edit") {
                            startEditing()
                        }
                    }
                }
            }
            .onChange(of: editedTitle) { _ in
                updateHasChanges()
            }
            .onChange(of: editedContent) { _ in
                updateHasChanges()
            }
        }
    }
    
    // MARK: - View Components
    
    private var readOnlyView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text(note.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Content
                if !note.content.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(note.content)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text("Info")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Created:")
                            Spacer()
                            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Modified:")
                            Spacer()
                            Text(note.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Sharing:")
                            Spacer()
                            if note.isShared {
                                Label("Shared", systemImage: "person.2.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Text("Private")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .font(.subheadline)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var editingView: some View {
        VStack {
            Form {
                Section("Title") {
                    TextField("Enter title...", text: $editedTitle)
                        .textFieldStyle(.automatic)
                }
                
                Section("Content") {
                    TextEditor(text: $editedContent)
                        .frame(minHeight: 200)
                }
            }
            
            if isLoading {
                ProgressView("Saving...")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }
    
    // MARK: - Actions
    
    private func startEditing() {
        isEditing = true
        editedTitle = note.title
        editedContent = note.content
        hasChanges = false
    }
    
    private func cancelEditing() {
        isEditing = false
        editedTitle = note.title
        editedContent = note.content
        hasChanges = false
    }
    
    private func updateHasChanges() {
        hasChanges = editedTitle != note.title || editedContent != note.content
    }
    
    private func saveChanges() {
        guard hasChanges else {
            isEditing = false
            return
        }
        
        guard !editedTitle.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                var updatedNote = note
                updatedNote.title = editedTitle
                updatedNote.content = editedContent
                updatedNote.modifiedAt = Date()
                
                _ = try await sharingManager.saveRecord(updatedNote)
                try await sharingManager.fetchRecords()
                
                await MainActor.run {
                    isEditing = false
                    hasChanges = false
                    isLoading = false
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("Failed to save changes: \\(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    let sampleNote = Note(title: "Sample Note", content: "This is a sample note content for preview purposes.")
    
    return NoteDetailView(note: sampleNote)
        .environmentObject(CloudKitSharingManager<Note>(
            containerIdentifier: "iCloud.com.example.SimpleNoteApp"
        ))
}