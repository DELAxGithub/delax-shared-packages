import SwiftUI
import DelaxCloudKitSharingKit
import CloudKit

struct ContentView: View {
    @EnvironmentObject private var sharingManager: CloudKitSharingManager<Note>
    @State private var showingNewNoteSheet = false
    @State private var showingSharingView = false
    @State private var shareToPresent: CKShare?
    @State private var selectedNote: Note?
    
    var body: some View {
        NavigationView {
            VStack {
                if sharingManager.isLoading {
                    loadingView
                } else if sharingManager.records.isEmpty {
                    emptyStateView
                } else {
                    noteListView
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if sharingManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Note") {
                        showingNewNoteSheet = true
                    }
                }
            }
            .onAppear {
                loadNotes()
            }
            .refreshable {
                await refreshNotes()
            }
        }
        .sheet(isPresented: $showingNewNoteSheet) {
            NewNoteView()
        }
        .sheet(item: $selectedNote) { note in
            NoteDetailView(note: note)
        }
        .sheet(isPresented: $showingSharingView) {
            if let share = shareToPresent {
                CloudSharingView(
                    share: share,
                    container: sharingManager.container,
                    onShareSaved: {
                        Task {
                            await refreshNotes()
                        }
                    },
                    onShareStopped: {
                        Task {
                            await refreshNotes()
                        }
                    }
                )
            }
        }
        .alert("Error", isPresented: .constant(sharingManager.errorMessage != nil)) {
            Button("OK") {
                sharingManager.errorMessage = nil
            }
        } message: {
            Text(sharingManager.errorMessage ?? "")
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading notes...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No notes yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Tap 'Add Note' to create your first note")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add Note") {
                showingNewNoteSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
    
    private var noteListView: some View {
        List {
            ForEach(sharingManager.records) { note in
                NoteRowView(note: note) {
                    selectedNote = note
                } onShare: {
                    shareNote(note)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", role: .destructive) {
                        deleteNote(note)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadNotes() {
        Task {
            do {
                try await sharingManager.fetchRecords()
            } catch {
                print("Failed to load notes: \\(error)")
            }
        }
    }
    
    private func refreshNotes() async {
        do {
            try await sharingManager.fetchRecords()
        } catch {
            print("Failed to refresh notes: \\(error)")
        }
    }
    
    private func shareNote(_ note: Note) {
        Task {
            do {
                if let existingShare = note.shareRecord {
                    // 既に共有されている場合
                    await MainActor.run {
                        shareToPresent = existingShare
                        showingSharingView = true
                    }
                } else {
                    // 新しい共有を作成
                    let share = try await sharingManager.startSharing(record: note)
                    await MainActor.run {
                        shareToPresent = share
                        showingSharingView = true
                    }
                }
            } catch {
                print("Failed to share note: \\(error)")
            }
        }
    }
    
    private func deleteNote(_ note: Note) {
        Task {
            do {
                try await sharingManager.deleteRecord(note)
                await refreshNotes()
            } catch {
                print("Failed to delete note: \\(error)")
            }
        }
    }
}

// MARK: - Note Row View

struct NoteRowView: View {
    let note: Note
    let onTap: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(note.preview)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(note.relativeTimeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if note.isShared {
                        Label("Shared", systemImage: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            Button(action: onShare) {
                Image(systemName: note.isShared ? "person.2.fill" : "person.2")
                    .font(.title2)
                    .foregroundColor(note.isShared ? .blue : .gray)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .padding(.vertical, 4)
    }
}

// MARK: - New Note View

struct NewNoteView: View {
    @EnvironmentObject private var sharingManager: CloudKitSharingManager<Note>
    @Environment(\\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var content = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section("Title") {
                        TextField("Enter title...", text: $title)
                    }
                    
                    Section("Content") {
                        TextEditor(text: $content)
                            .frame(minHeight: 100)
                    }
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(title.isEmpty || isLoading)
                }
            }
        }
    }
    
    private func saveNote() {
        isLoading = true
        
        Task {
            do {
                let note = Note(title: title, content: content)
                _ = try await sharingManager.saveRecord(note)
                try await sharingManager.fetchRecords()
                
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("Failed to save note: \\(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CloudKitSharingManager<Note>(
            containerIdentifier: "iCloud.com.example.SimpleNoteApp"
        ))
}