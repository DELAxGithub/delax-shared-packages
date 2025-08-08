import SwiftUI
import CloudKit

// 共有状態管理
enum ShareState: Equatable {
    case notShared          // 未共有
    case creating           // Step 1: 共有作成中（URL生成待機）
    case ready              // Step 1完了: 共有準備完了（URL生成済み）
    case error(Error)       // エラー状態
    
    static func == (lhs: ShareState, rhs: ShareState) -> Bool {
        switch (lhs, rhs) {
        case (.notShared, .notShared), (.creating, .creating), (.ready, .ready):
            return true
        case (.error, .error):
            return true // エラーの内容に関わらず同じ状態として扱う
        default:
            return false
        }
    }
}

struct NoteListViewAlternative: View {
    @StateObject private var cloudKitManager = CloudKitManagerAlternative()
    @State private var showCreateNote = false
    @State private var selectedNote: Note?
    @State private var shareToPresent: CKShare?
    @State private var showSharingView = false
    @State private var showShareDebugInfo = false
    @State private var debugShareInfo: String = ""
    @State private var showShareURLAlert = false
    @State private var currentShareURL: String = ""
    @State private var shareStates: [String: ShareState] = [:]  // Note.id -> ShareState
    
    var body: some View {
        NavigationView {
            ZStack {
                if cloudKitManager.notes.isEmpty && !cloudKitManager.isLoading {
                    EmptyNoteView()
                } else {
                    NoteListContent(
                        notes: cloudKitManager.notes,
                        onSelectNote: { note in
                            selectedNote = note
                        },
                        onDeleteNotes: deleteNotes,
                        onToggleFavorite: { note in
                            cloudKitManager.toggleFavorite(note)
                        },
                        onCreateShare: { note in
                            handleShareCreation(note)
                        },
                        onManageShare: { note in
                            handleShareManagement(note)
                        },
                        shareStates: shareStates
                    )
                }
                
                if cloudKitManager.isLoading {
                    ProgressView("読み込み中...")
                }
            }
            .navigationTitle("ノート（代替実装）")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("PoC情報") {
                        generateShareDebugInfo()
                        showShareDebugInfo = true
                    }
                    .font(.caption)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateNote = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                cloudKitManager.fetchNotes()
                initializeShareStates()
            }
            .refreshable {
                cloudKitManager.fetchNotes()
            }
            .sheet(isPresented: $showCreateNote) {
                CreateNoteViewAlternative(cloudKitManager: cloudKitManager)
            }
            .sheet(item: $selectedNote) { note in
                EditNoteViewAlternative(note: note, cloudKitManager: cloudKitManager)
            }
            .sheet(isPresented: $showSharingView) {
                if let share = shareToPresent {
                    CloudSharingView(share: share, container: cloudKitManager.container) {
                        // 共有保存時の処理
                        print("🔄 共有保存完了 - ノート一覧を更新")
                        cloudKitManager.loadAllNotes()
                    } onShareStopped: {
                        // 共有停止時の処理
                        print("⏹️ 共有停止完了 - ノート一覧を更新")
                        cloudKitManager.loadAllNotes()
                    }
                }
            }
            .alert("PoC検証情報", isPresented: $showShareDebugInfo, actions: {
                Button("コピー") {
                    UIPasteboard.general.string = debugShareInfo
                }
                Button("OK") { }
            }, message: {
                Text(debugShareInfo)
            })
            .alert("共有URL", isPresented: $showShareURLAlert, actions: {
                Button("URLをコピー") {
                    UIPasteboard.general.string = currentShareURL
                    print("📋 共有URLをクリップボードにコピー: \(currentShareURL)")
                }
                Button("OK") { }
            }, message: {
                Text("共有URLをコピーして別のApple IDデバイスでアクセスしてください:\n\n\(currentShareURL)")
            })
            .alert("エラー", isPresented: .constant(cloudKitManager.errorMessage != nil), actions: {
                Button("OK") {
                    cloudKitManager.errorMessage = nil
                }
            }, message: {
                if let errorMessage = cloudKitManager.errorMessage {
                    Text(errorMessage)
                }
            })
        }
    }
    
    // Step 1: 共有作成（CKShare作成 + URL生成）
    private func handleShareCreation(_ note: Note) {
        print("🔗 【Step 1】共有作成ボタンがタップされました - ノート: \(note.title)")
        print("🔍 現在の共有状態: \(note.isShared)")
        print("📝 ShareRecord: \(note.shareRecord != nil ? "存在" : "なし")")
        
        // 状態を作成中に変更
        shareStates[note.id] = .creating
        
        cloudKitManager.createShare(for: note) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let share):
                    print("✅ 【Step 1完了】共有作成成功: \(share.url?.absoluteString ?? "URLなし")")
                    // 状態を準備完了に変更
                    self.shareStates[note.id] = .ready
                    // ノート一覧を更新
                    self.cloudKitManager.loadAllNotes()
                case .failure(let error):
                    print("❌ 【Step 1失敗】共有エラー発生")
                    // エラー状態に変更
                    self.shareStates[note.id] = .error(error)
                    if let sharingError = error as? CloudKitSharingError {
                        print("共有エラー: \(sharingError.localizedDescription)")
                    } else {
                        print("共有エラー: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // Step 2: 共有管理（UICloudSharingController表示）
    private func handleShareManagement(_ note: Note) {
        print("🎛️ 【Step 2】共有管理ボタンがタップされました - ノート: \(note.title)")
        
        guard let shareRecord = note.shareRecord else {
            print("❌ ShareRecordが存在しません")
            return
        }
        
        if shareRecord.url != nil {
            print("✅ 【Step 2】UICloudSharingControllerを表示")
            shareToPresent = shareRecord
            showSharingView = true
        } else {
            print("⚠️ URL未生成 - URLを直接表示")
            // URLが生成されていない場合は、PoC情報を表示
            generateShareDebugInfo()
            showShareDebugInfo = true
        }
    }
    
    private func generateShareDebugInfo() {
        let sharedNotes = cloudKitManager.notes.filter { $0.isShared }
        var info = "=== CloudKit共有 PoC検証情報 ===\n\n"
        
        info += "📊 概要:\n"
        info += "全ノート数: \(cloudKitManager.notes.count)\n"
        info += "共有ノート数: \(sharedNotes.count)\n\n"
        
        if sharedNotes.isEmpty {
            info += "⚠️ 共有されているノートがありません\n"
            info += "PoC手順: ノートを作成して共有ボタンをタップし、Apple IDユーザーを招待してください\n"
        } else {
            info += "🔗 共有ノート詳細:\n"
            for (index, note) in sharedNotes.enumerated() {
                info += "\(index + 1). \(note.title)\n"
                if let shareRecord = note.shareRecord {
                    info += "   参加者数: \(shareRecord.participants.count)\n"
                    
                    // URL状態の詳細表示
                    if let url = shareRecord.url {
                        info += "   共有URL: \(url.absoluteString)\n"
                        info += "   📱 URL状態: ✅ 生成済み（共有可能）\n"
                    } else {
                        info += "   📱 URL状態: ⏳ 生成中またはエラー\n"
                        info += "   💡 対処法: アプリを再起動してから「PoC情報」を再度確認\n"
                    }
                    
                    let pendingCount = shareRecord.participants.filter { $0.acceptanceStatus == .pending }.count
                    let acceptedCount = shareRecord.participants.filter { $0.acceptanceStatus == .accepted }.count
                    info += "   招待待ち: \(pendingCount)人, 承認済み: \(acceptedCount)人\n"
                    
                    // 参加者詳細
                    for (pIndex, participant) in shareRecord.participants.enumerated() {
                        let status = participant.acceptanceStatus == .pending ? "⏳招待中" :
                                   participant.acceptanceStatus == .accepted ? "✅承認済み" : "❓不明"
                        let role = participant.role == .owner ? "👑オーナー" : "👥参加者"
                        info += "     \(pIndex + 1). \(role) \(status)\n"
                    }
                }
                info += "\n"
            }
            
            // 共有URL一覧（コピー用）
            let shareURLs = sharedNotes.compactMap { $0.shareRecord?.url?.absoluteString }.filter { !$0.isEmpty }
            if !shareURLs.isEmpty {
                info += "📋 共有URL一覧（コピー用）:\n"
                for (index, urlString) in shareURLs.enumerated() {
                    info += "\(index + 1). \(urlString)\n"
                }
                info += "\n"
            }
        }
        
        info += "🎯 Apple ID共有PoC検証手順:\n"
        info += "1. 【共有作成】グレーの「共有」ボタンをタップして共有を作成\n"
        info += "2. 【招待送信】UICloudSharingControllerで連絡先を選択して招待\n"
        info += "3. 【URL確認】青い「表示」ボタンをタップして共有URLをコピー\n"
        info += "4. 【別デバイス】コピーしたURLを別のApple IDデバイスでアクセス\n"
        info += "5. 【権限確認】共有ノートの閲覧・編集権限をテスト\n"
        info += "6. 【状況追跡】招待状況が「招待中」→「承認済み」に変わることを確認\n\n"
        
        info += "💡 ヒント:\n"
        info += "・共有ボタンの色: グレー(未共有) → オレンジ(生成中) → 青(共有完了)\n"
        info += "・長押し不要: 1回タップで共有作成または情報表示\n"
        info += "・デバイス準備: 2つの異なるApple IDでサインインしたデバイスが必要\n"
        
        debugShareInfo = info
    }
    
    private func initializeShareStates() {
        for note in cloudKitManager.notes {
            if shareStates[note.id] == nil {
                if note.isShared {
                    shareStates[note.id] = .ready
                } else {
                    shareStates[note.id] = .notShared
                }
            }
        }
    }
    
    private func showURLAlert(_ url: String) {
        currentShareURL = url
        showShareURLAlert = true
    }
    
    private func deleteNotes(at offsets: IndexSet) {
        for index in offsets {
            let note = cloudKitManager.notes[index]
            cloudKitManager.deleteNote(note) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    print("削除エラー: \(error)")
                }
            }
        }
    }
}

// 空状態のビュー
struct EmptyNoteView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("ノートがありません")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("＋ボタンをタップして最初のノートを作成してください")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// ノートリストのコンテンツ
struct NoteListContent: View {
    let notes: [Note]
    let onSelectNote: (Note) -> Void
    let onDeleteNotes: (IndexSet) -> Void
    let onToggleFavorite: (Note) -> Void
    let onCreateShare: ((Note) -> Void)?
    let onManageShare: ((Note) -> Void)?
    let shareStates: [String: ShareState]
    
    var body: some View {
        List {
            ForEach(notes) { note in
                NoteRowView(note: note, action: {
                    onSelectNote(note)
                }, onToggleFavorite: onToggleFavorite, onCreateShare: onCreateShare, onManageShare: onManageShare, shareState: shareStates[note.id] ?? .notShared)
            }
            .onDelete(perform: onDeleteNotes)
        }
    }
}

// ノート行のビュー
struct NoteRowView: View {
    let note: Note
    let action: () -> Void
    let onToggleFavorite: (Note) -> Void
    let onCreateShare: ((Note) -> Void)?
    let onManageShare: ((Note) -> Void)?
    let shareState: ShareState
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if !note.content.isEmpty {
                        Text(note.content)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Text(note.modifiedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(Color.secondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            HStack(spacing: 8) {
                // 共有ボタン - 2段階フローに対応
                Button(action: {
                    handleShareAction()
                }) {
                    VStack(spacing: 2) {
                        // アイコンと色で状態を表現
                        Group {
                            switch shareState {
                            case .notShared:
                                Image(systemName: "person.2.badge.plus")
                                    .foregroundColor(.gray)
                            case .creating:
                                Image(systemName: "person.2.circle")
                                    .foregroundColor(.orange)
                            case .ready:
                                if note.shareRecord?.url != nil {
                                    Image(systemName: "person.2.circle.fill")
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "person.2.circle")
                                        .foregroundColor(.orange)
                                }
                            case .error:
                                Image(systemName: "person.2.badge.gearshape")
                                    .foregroundColor(.red)
                            }
                        }
                        .font(.system(size: 16))
                        
                        // 状態テキスト
                        Text(getButtonText())
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(getButtonColor())
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(shareState == .creating) // 作成中は無効化
                
                // お気に入りボタン
                Button(action: {
                    onToggleFavorite(note)
                }) {
                    Image(systemName: note.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(note.isFavorite ? .red : .gray)
                        .font(.system(size: 20))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.trailing, 4)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - ヘルパーメソッド
    
    private func handleShareAction() {
        print("🔗 共有ボタンタップ - \(note.title) (状態: \(shareState))")
        
        switch shareState {
        case .notShared:
            // Step 1: 共有作成
            print("🆕 【Step 1開始】 共有作成")
            onCreateShare?(note)
        case .creating:
            // 作成中は何もしない（ボタンは無効化されている）
            print("⏳ 共有作成中 - 待機してください")
        case .ready:
            // Step 2: 共有管理
            print("🎛️ 【Step 2開始】 共有管理")
            onManageShare?(note)
        case .error:
            // エラー時は再試行
            print("🔄 エラーから再試行")
            onCreateShare?(note)
        }
    }
    
    private func getButtonText() -> String {
        switch shareState {
        case .notShared:
            return "作成"
        case .creating:
            return "作成中"
        case .ready:
            return note.shareRecord?.url != nil ? "管理" : "確認"
        case .error:
            return "再試行"
        }
    }
    
    private func getButtonColor() -> Color {
        switch shareState {
        case .notShared:
            return .gray
        case .creating:
            return .orange
        case .ready:
            return note.shareRecord?.url != nil ? .blue : .orange
        case .error:
            return .red
        }
    }
}

// CreateNoteViewの代替版
struct CreateNoteViewAlternative: View {
    @ObservedObject var cloudKitManager: CloudKitManagerAlternative
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var content = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("タイトル") {
                    TextField("タイトルを入力", text: $title)
                }
                
                Section("内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("新規ノート")
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
        }
    }
    
    private func saveNote() {
        isSaving = true
        let note = Note(title: title, content: content)
        
        cloudKitManager.saveNote(note) { result in
            isSaving = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                print("保存エラー: \(error)")
            }
        }
    }
}

// EditNoteViewの代替版
struct EditNoteViewAlternative: View {
    @State var note: Note
    @ObservedObject var cloudKitManager: CloudKitManagerAlternative
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("タイトル") {
                    TextField("タイトルを入力", text: $title)
                }
                
                Section("内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
                
                Section("情報") {
                    HStack {
                        Text("作成日時")
                        Spacer()
                        Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("更新日時")
                        Spacer()
                        Text(note.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                }
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
                content = note.content
            }
        }
    }
    
    private func saveNote() {
        isSaving = true
        note.title = title
        note.content = content
        note.modifiedAt = Date()
        
        cloudKitManager.saveNote(note) { result in
            isSaving = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                print("保存エラー: \(error)")
            }
        }
    }
}