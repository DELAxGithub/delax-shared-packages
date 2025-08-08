import SwiftUI

struct EditNoteView: View {
    @State var note: Note
    @ObservedObject var cloudKitManager: CloudKitManager
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                TextField("タイトル", text: $title)
            }
            .navigationTitle("ノートを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveNote()
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    ProgressView("保存中...")
                }
            }
            .onAppear {
                title = note.title
            }
        }
    }
    
    private func saveNote() {
        isSaving = true
        note.title = title
        
        cloudKitManager.saveNote(note) { result in
            isSaving = false
            switch result {
            case .success:
                cloudKitManager.fetchNotes()
                dismiss()
            case .failure(let error):
                print("保存エラー: \(error)")
            }
        }
    }
}