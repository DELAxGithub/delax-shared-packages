# CloudKitSharingKit ベストプラクティス

CloudKitSharingKitを使用した効率的で安全な実装のためのベストプラクティス集です。

## 🏗️ アーキテクチャのベストプラクティス

### 1. シングルトンパターンの適用

アプリケーション全体で一つの`CloudKitSharingManager`インスタンスを使用します。

```swift
// ✅ 推奨: アプリレベルでの管理
@main
struct MyApp: App {
    @StateObject private var sharingManager = CloudKitSharingManager<Note>(
        containerIdentifier: "iCloud.com.example.MyApp"
    )
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharingManager)
        }
    }
}

// ❌ 非推奨: 複数のインスタンス作成
struct SomeView: View {
    @StateObject private var localManager = CloudKitSharingManager<Note>(...)
    // 複数のインスタンスは同期問題を引き起こす可能性
}
```

### 2. 適切なデータモデル設計

```swift
struct Note: SharableRecord {
    // 必須フィールドは最小限に
    let id: String
    var record: CKRecord?
    var shareRecord: CKShare?
    
    // ビジネスロジックに必要なプロパティ
    var title: String
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    
    // ✅ 推奨: 機密情報は含めない
    // var password: String // ❌ 共有される可能性があるため避ける
    
    static var recordType: String { "Note" }
    
    // ✅ 推奨: バリデーション付きの初期化
    init(title: String, content: String = "") {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fatalError("Title cannot be empty")
        }
        
        self.id = UUID().uuidString
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.record = nil
        self.shareRecord = nil
    }
}
```

### 3. エラーハンドリングの標準化

```swift
@MainActor
class ErrorHandler: ObservableObject {
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    func handle(_ error: Error, context: String = "") {
        if let sharingError = error as? CloudKitSharingError {
            handleSharingError(sharingError, context: context)
        } else if let ckError = error as? CKError {
            handleCloudKitError(ckError, context: context)
        } else {
            handleGenericError(error, context: context)
        }
    }
    
    private func handleSharingError(_ error: CloudKitSharingError, context: String) {
        switch error {
        case .alreadyShared:
            alertTitle = "Already Shared"
            alertMessage = "This item is already being shared."
        case .noRecord:
            alertTitle = "Item Not Found"
            alertMessage = "The item you're trying to share wasn't found."
        default:
            alertTitle = "Sharing Error"
            alertMessage = error.localizedDescription
        }
        showingAlert = true
    }
    
    private func handleCloudKitError(_ error: CKError, context: String) {
        switch error.code {
        case .notAuthenticated:
            alertTitle = "Sign In Required"
            alertMessage = "Please sign in to iCloud in Settings to use this feature."
        case .networkFailure, .networkUnavailable:
            alertTitle = "Network Error"
            alertMessage = "Please check your internet connection and try again."
        case .quotaExceeded:
            alertTitle = "Storage Full"
            alertMessage = "Your iCloud storage is full. Please free up space."
        default:
            alertTitle = "Error"
            alertMessage = "\\(context.isEmpty ? "" : "\\(context): ")\\(error.localizedDescription)"
        }
        showingAlert = true
    }
}
```

## 📱 UI/UX のベストプラクティス

### 1. ローディング状態の適切な表示

```swift
struct ContentView: View {
    @EnvironmentObject private var sharingManager: CloudKitSharingManager<Note>
    @StateObject private var errorHandler = ErrorHandler()
    
    var body: some View {
        NavigationView {
            Group {
                if sharingManager.isLoading {
                    LoadingView()
                } else if sharingManager.records.isEmpty {
                    EmptyStateView()
                } else {
                    NoteListView()
                }
            }
            .refreshable {
                await loadData()
            }
            .alert(errorHandler.alertTitle, isPresented: $errorHandler.showingAlert) {
                Button("OK") { }
            } message: {
                Text(errorHandler.alertMessage)
            }
        }
    }
    
    private func loadData() async {
        do {
            try await sharingManager.fetchRecords()
        } catch {
            errorHandler.handle(error, context: "Loading data")
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}
```

### 2. 共有状態の視覚的フィードバック

```swift
struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(note.title)
                    .font(.headline)
                
                // ✅ 推奨: 共有状態の明確な表示
                HStack {
                    if note.isShared {
                        Label("Shared", systemImage: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        if !note.isOwner {
                            Label("Read Only", systemImage: "eye")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            Spacer()
            
            // 共有ボタンの状態表示
            Button(action: shareNote) {
                Image(systemName: note.isShared ? "person.2.fill" : "person.2")
                    .foregroundColor(note.isShared ? .blue : .gray)
            }
        }
    }
}
```

### 3. 適切なUXフロー

```swift
struct ShareFlowView: View {
    let note: Note
    @State private var showingShareSheet = false
    @State private var shareToPresent: CKShare?
    @State private var isLoading = false
    
    var body: some View {
        Button("Share Note") {
            initiateSharing()
        }
        .disabled(isLoading)
        .sheet(isPresented: $showingShareSheet) {
            if let share = shareToPresent {
                CloudSharingView(
                    share: share,
                    container: sharingManager.container,
                    onShareSaved: {
                        // ✅ 推奨: 共有後の状態更新
                        Task {
                            try? await sharingManager.fetchRecords()
                        }
                    }
                )
            }
        }
    }
    
    private func initiateSharing() {
        isLoading = true
        
        Task {
            do {
                let share: CKShare
                if let existingShare = note.shareRecord {
                    // 既存の共有を使用
                    share = existingShare
                } else {
                    // 新しい共有を作成
                    share = try await sharingManager.startSharing(record: note)
                }
                
                await MainActor.run {
                    shareToPresent = share
                    showingShareSheet = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // エラーハンドリング
                }
            }
        }
    }
}
```

## 🚀 パフォーマンスのベストプラクティス

### 1. 効率的なデータ取得

```swift
class DataManager: ObservableObject {
    private let sharingManager: CloudKitSharingManager<Note>
    @Published var notes: [Note] = []
    private var lastFetchDate: Date?
    
    init(sharingManager: CloudKitSharingManager<Note>) {
        self.sharingManager = sharingManager
    }
    
    func loadNotesIfNeeded() async {
        // ✅ 推奨: 必要な場合のみデータを取得
        let now = Date()
        if let lastFetch = lastFetchDate,
           now.timeIntervalSince(lastFetch) < 30 { // 30秒間はキャッシュを使用
            return
        }
        
        do {
            try await sharingManager.fetchRecords()
            notes = sharingManager.records
            lastFetchDate = now
        } catch {
            // エラーハンドリング
        }
    }
    
    func forceRefresh() async {
        lastFetchDate = nil
        await loadNotesIfNeeded()
    }
}
```

### 2. バッチ操作の実装

```swift
extension CloudKitSharingManager {
    // ✅ 推奨: 複数レコードの効率的な保存
    func saveRecords(_ records: [T]) async throws -> [T] {
        var savedRecords: [T] = []
        
        for record in records {
            do {
                let saved = try await saveRecord(record)
                savedRecords.append(saved)
            } catch {
                print("Failed to save record \\(record.id): \\(error)")
                // 一部失敗しても継続
            }
        }
        
        // 最後に一括取得で状態を同期
        try await fetchRecords()
        
        return savedRecords
    }
}
```

### 3. メモリ効率的な実装

```swift
struct LargeDataView: View {
    @EnvironmentObject private var sharingManager: CloudKitSharingManager<Note>
    @State private var searchText = ""
    
    // ✅ 推奨: フィルタリングでメモリ使用量を削減
    private var filteredNotes: [Note] {
        if searchText.isEmpty {
            return sharingManager.records
        } else {
            return sharingManager.records.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        List(filteredNotes) { note in
            NoteRowView(note: note)
                .onAppear {
                    // ✅ 推奨: 遅延読み込み
                    if note == filteredNotes.last {
                        // 必要に応じて追加データを読み込み
                    }
                }
        }
        .searchable(text: $searchText)
    }
}
```

## 🔒 セキュリティのベストプラクティス

### 1. データプライバシーの保護

```swift
struct SecureNote: SharableRecord {
    let id: String
    var record: CKRecord?
    var shareRecord: CKShare?
    
    var title: String
    var content: String
    
    // ✅ 推奨: 機密情報は別管理
    private var encryptionKey: String? // ローカルのみ保存
    
    static var recordType: String { "SecureNote" }
    
    func toCKRecord(zoneID: CKRecordZone.ID?) -> CKRecord {
        let record = createBasicRecord(zoneID: zoneID)
        
        // ✅ 推奨: 機密データは暗号化
        if let key = encryptionKey {
            record["content"] = encrypt(content, key: key)
        } else {
            record["content"] = content
        }
        
        // ❌ 絶対に避ける: 機密情報を直接保存
        // record["password"] = password
        // record["creditCardNumber"] = creditCardNumber
        
        return record
    }
    
    private func encrypt(_ text: String, key: String) -> String {
        // 暗号化実装
        return text // 簡略化
    }
}
```

### 2. 共有権限の適切な管理

```swift
struct ShareManagementView: View {
    let note: Note
    @State private var sharePermission: CKShare.ParticipantPermission = .readOnly
    
    var body: some View {
        VStack {
            if note.isOwner {
                // ✅ 推奨: オーナーのみが権限設定可能
                Picker("Permission", selection: $sharePermission) {
                    Text("Read Only").tag(CKShare.ParticipantPermission.readOnly)
                    Text("Read & Write").tag(CKShare.ParticipantPermission.readWrite)
                }
                
                Button("Update Sharing") {
                    updateSharingPermissions()
                }
            } else {
                // 参加者には現在の権限のみ表示
                Text("Permission: \\(note.sharePermission?.description ?? "Unknown")")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func updateSharingPermissions() {
        // 権限更新の実装
    }
}
```

## 🧪 テストのベストプラクティス

### 1. モックオブジェクトの使用

```swift
// テスト用のモック実装
class MockCloudKitSharingManager<T: SharableRecord>: ObservableObject {
    @Published var records: [T] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var mockRecords: [T] = []
    private var shouldFailNextOperation = false
    
    func setMockRecords(_ records: [T]) {
        self.mockRecords = records
        self.records = records
    }
    
    func setShouldFail(_ shouldFail: Bool) {
        self.shouldFailNextOperation = shouldFail
    }
    
    func fetchRecords() async throws {
        if shouldFailNextOperation {
            shouldFailNextOperation = false
            throw CKError(.networkFailure)
        }
        
        isLoading = true
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒のシミュレート
        
        await MainActor.run {
            self.records = mockRecords
            self.isLoading = false
        }
    }
}

// SwiftUIテストでの使用例
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let mockManager = MockCloudKitSharingManager<Note>()
        mockManager.setMockRecords([
            Note(title: "Test Note 1", content: "Content 1"),
            Note(title: "Test Note 2", content: "Content 2")
        ])
        
        return ContentView()
            .environmentObject(mockManager as! CloudKitSharingManager<Note>)
    }
}
```

### 2. エラーケースのテスト

```swift
class SharingFlowTests: XCTestCase {
    func testSharingAlreadySharedNote() async {
        // Arrange
        let mockManager = MockCloudKitSharingManager<Note>()
        let note = Note(title: "Test", content: "Content")
        note.shareRecord = CKShare() // 既に共有済みの状態
        
        // Act & Assert
        do {
            _ = try await mockManager.startSharing(record: note)
            XCTFail("Should have thrown alreadyShared error")
        } catch CloudKitSharingError.alreadyShared {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \\(error)")
        }
    }
}
```

## 📊 監視とデバッグ

### 1. ログ戦略

```swift
extension CloudKitSharingManager {
    private func logOperation(_ operation: String, recordID: String? = nil) {
        let timestamp = DateFormatter.iso8601.string(from: Date())
        let message = "[\\(timestamp)] CloudKitSharingManager: \\(operation)"
        
        if let recordID = recordID {
            print("\\(message) - Record: \\(recordID)")
        } else {
            print(message)
        }
        
        // 本番環境では適切なログサービスに送信
        #if DEBUG
        // デバッグ情報の追加
        #endif
    }
}
```

### 2. パフォーマンス監視

```swift
class PerformanceMonitor {
    private var startTimes: [String: Date] = [:]
    
    func startMeasuring(_ operation: String) {
        startTimes[operation] = Date()
    }
    
    func endMeasuring(_ operation: String) {
        guard let startTime = startTimes[operation] else { return }
        let duration = Date().timeIntervalSince(startTime)
        
        print("⏱️ \\(operation) took \\(String(format: "%.3f", duration))s")
        
        // 閾値を超えた場合の警告
        if duration > 5.0 {
            print("⚠️ Slow operation detected: \\(operation)")
        }
        
        startTimes.removeValue(forKey: operation)
    }
}
```

これらのベストプラクティスに従うことで、安全で効率的なCloudKit共有機能を実装できます。