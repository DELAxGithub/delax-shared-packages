import SwiftUI

struct NoteListView: View {
    @StateObject private var cloudKitManager = CloudKitManager()
    @State private var showCreateNote = false
    @State private var selectedNote: Note?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(cloudKitManager.notes) { note in
                    Button(action: {
                        selectedNote = note
                    }) {
                        VStack(alignment: .leading) {
                            Text(note.title)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .onDelete(perform: deleteNotes)
            }
            .navigationTitle("ノート")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateNote = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                cloudKitManager.fetchNotes()
            }
            .refreshable {
                cloudKitManager.fetchNotes()
            }
            .overlay {
                if cloudKitManager.isLoading {
                    ProgressView("読み込み中...")
                }
            }
            .sheet(isPresented: $showCreateNote) {
                CreateNoteView(cloudKitManager: cloudKitManager)
            }
            .sheet(item: $selectedNote) { note in
                EditNoteView(note: note, cloudKitManager: cloudKitManager)
            }
            .alert("エラー", isPresented: .constant(cloudKitManager.errorMessage != nil), actions: {
                Button("OK") {
                    cloudKitManager.errorMessage = nil
                }
                if cloudKitManager.showSetupGuide {
                    Button("設定ガイドを表示") {
                        cloudKitManager.errorMessage = nil
                        // ここで設定ガイドを表示
                    }
                }
            }, message: {
                if let errorMessage = cloudKitManager.errorMessage {
                    Text(errorMessage)
                }
            })
        }
    }
    
    private func deleteNotes(at offsets: IndexSet) {
        for index in offsets {
            let note = cloudKitManager.notes[index]
            cloudKitManager.deleteNote(note) { result in
                switch result {
                case .success:
                    cloudKitManager.fetchNotes()
                case .failure(let error):
                    print("削除エラー: \(error)")
                }
            }
        }
    }
}