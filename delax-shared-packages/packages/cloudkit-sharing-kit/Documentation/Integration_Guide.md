# CloudKitSharingKit 導入手順書

このガイドでは、既存のiOSプロジェクトにCloudKitSharingKitを導入する詳細な手順を説明します。

## 📋 前提条件

- Xcode 15.0以降
- iOS 15.0以降のデプロイメントターゲット  
- Apple Developer Program登録済み
- CloudKitコンテナの設定権限

## 🚀 Step 1: Swift Packageの追加

### Xcodeでの追加方法

1. Xcodeでプロジェクトを開く
2. `File` > `Add Package Dependencies...` を選択
3. 以下のURLを入力:
   ```
   https://github.com/example/CloudKitSharingKit
   ```
4. `Add Package` をクリック
5. ターゲットに `CloudKitSharingKit` を追加

### Package.swiftでの追加方法

```swift
// Package.swift
let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/example/CloudKitSharingKit", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: ["CloudKitSharingKit"]
        )
    ]
)
```

## ⚙️ Step 2: Xcodeプロジェクト設定

### 2.1 CloudKit Capability の有効化

1. プロジェクト設定を開く
2. `Signing & Capabilities` タブを選択
3. `+ Capability` をクリック
4. `CloudKit` を検索して追加
5. コンテナを選択または新規作成

### 2.2 Entitlements の確認

`YourApp.entitlements` ファイルが以下の内容を含むことを確認:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.yourteam.YourApp</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
</dict>
</plist>
```

## 🗄️ Step 3: CloudKit Dashboard設定

### 3.1 レコードタイプの作成

1. [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard) にアクセス
2. 対象のコンテナを選択
3. `Schema` > `Record Types` に移動
4. `+` ボタンをクリックして新しいレコードタイプを作成

#### サンプル: Noteレコードタイプ

| フィールド名 | タイプ | インデックス可能 | 必須 |
|-------------|--------|----------------|------|
| title | String | ✅ | ✅ |
| content | String | ❌ | ❌ |
| createdAt | Date/Time | ✅ | ❌ |
| modifiedAt | Date/Time | ✅ | ❌ |

### 3.2 共有機能の有効化

⚠️ **重要**: レコードタイプの設定で `Shared` を **必ず有効化** してください。

1. 作成したレコードタイプを選択
2. `Metadata` セクションで `Shared` にチェックを入れる
3. `Save` をクリック

### 3.3 スキーマの本番環境への反映

1. `Deploy Schema Changes` をクリック
2. 変更内容を確認
3. `Deploy` をクリックして本番環境に反映

## 💻 Step 4: データモデルの実装

### 4.1 基本的なデータモデル

```swift
import CloudKitSharingKit
import CloudKit
import Foundation

struct Note: SharableRecord {
    // MARK: - Properties
    let id: String
    var title: String
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    
    // MARK: - SharableRecord Protocol
    var record: CKRecord?
    var shareRecord: CKShare?
    
    static var recordType: String { "Note" }
    
    // MARK: - Initializers
    init(id: String = UUID().uuidString, title: String, content: String = "") {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.record = nil
        self.shareRecord = nil
    }
    
    init(from record: CKRecord, shareRecord: CKShare? = nil) {
        self.id = record.recordID.recordName
        self.title = record["title"] as? String ?? ""
        self.content = record["content"] as? String ?? ""
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.modifiedAt = record["modifiedAt"] as? Date ?? Date()
        self.record = record
        self.shareRecord = shareRecord
    }
    
    func toCKRecord(zoneID: CKRecordZone.ID?) -> CKRecord {
        let record: CKRecord
        
        if let existingRecord = self.record {
            record = existingRecord
        } else {
            if let zoneID = zoneID {
                let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
                record = CKRecord(recordType: Note.recordType, recordID: recordID)
            } else {
                record = CKRecord(recordType: Note.recordType)
            }
        }
        
        record["title"] = title
        record["content"] = content
        record["createdAt"] = createdAt
        record["modifiedAt"] = Date() // 保存時に更新
        
        return record
    }
}
```

## 🏗️ Step 5: CloudKitSharingManagerの設定

### 5.1 基本的な設定

```swift
import CloudKitSharingKit
import SwiftUI

@main
struct YourApp: App {
    // CloudKitSharingManagerをアプリレベルで初期化
    @StateObject private var sharingManager = CloudKitSharingManager<Note>(
        containerIdentifier: "iCloud.com.yourteam.YourApp",
        customZoneName: "NotesZone"  // オプション: カスタムゾーン名
    )
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharingManager)
        }
    }
}
```

### 5.2 ViewModelでの使用

```swift
import CloudKitSharingKit
import SwiftUI

class NoteViewModel: ObservableObject {
    private let sharingManager: CloudKitSharingManager<Note>
    
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(containerIdentifier: String) {
        self.sharingManager = CloudKitSharingManager<Note>(
            containerIdentifier: containerIdentifier
        )
    }
    
    func loadNotes() async {
        isLoading = true
        do {
            try await sharingManager.fetchRecords()
            await MainActor.run {
                self.notes = sharingManager.records
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func saveNote(_ note: Note) async throws {
        _ = try await sharingManager.saveRecord(note)
        try await sharingManager.fetchRecords()
        await MainActor.run {
            self.notes = sharingManager.records
        }
    }
    
    func shareNote(_ note: Note) async throws -> CKShare {
        return try await sharingManager.startSharing(record: note)
    }
}
```

## 🎨 Step 6: UI実装

### 6.1 基本的なリストビュー

```swift
import SwiftUI
import CloudKitSharingKit

struct NoteListView: View {
    @EnvironmentObject private var sharingManager: CloudKitSharingManager<Note>
    
    @State private var showingSharingView = false
    @State private var shareToPresent: CKShare?
    @State private var showingNewNoteSheet = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sharingManager.records) { note in
                    NoteRowView(
                        note: note,
                        onShareTapped: { shareNote(note) }
                    )
                }
                .onDelete(perform: deleteNotes)
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingNewNoteSheet = true
                    }
                }
            }
            .onAppear {
                Task {
                    try? await sharingManager.fetchRecords()
                }
            }
        }
        .sheet(isPresented: $showingNewNoteSheet) {
            NewNoteView()
        }
        .sheet(isPresented: $showingSharingView) {
            if let share = shareToPresent {
                CloudSharingView(
                    share: share,
                    container: sharingManager.container,
                    onShareSaved: {
                        Task {
                            try? await sharingManager.fetchRecords()
                        }
                    },
                    onShareStopped: {
                        Task {
                            try? await sharingManager.fetchRecords()
                        }
                    }
                )
            }
        }
    }
    
    private func shareNote(_ note: Note) {
        Task {
            do {
                if let existingShare = note.shareRecord {
                    // 既に共有済み - 共有設定を表示
                    shareToPresent = existingShare
                } else {
                    // 新規共有作成
                    let share = try await sharingManager.startSharing(record: note)
                    shareToPresent = share
                }
                showingSharingView = true
            } catch {
                print("共有エラー: \\(error)")
            }
        }
    }
    
    private func deleteNotes(offsets: IndexSet) {
        for index in offsets {
            let note = sharingManager.records[index]
            Task {
                try? await sharingManager.deleteRecord(note)
                try? await sharingManager.fetchRecords()
            }
        }
    }
}

struct NoteRowView: View {
    let note: Note
    let onShareTapped: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(note.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // 共有状態の表示
                if note.isShared {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("共有中")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            // 共有ボタン
            Button(action: onShareTapped) {
                Image(systemName: note.isShared ? "person.2.fill" : "person.2")
                    .foregroundColor(note.isShared ? .blue : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 2)
    }
}
```

### 6.2 新規ノート作成ビュー

```swift
struct NewNoteView: View {
    @EnvironmentObject private var sharingManager: CloudKitSharingManager<Note>
    @Environment(\\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var content = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("タイトル") {
                    TextField("タイトルを入力", text: $title)
                }
                
                Section("内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("新しいノート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
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
                print("保存エラー: \\(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}
```

## ⚡ Step 7: 動作確認

### 7.1 基本動作テスト

1. アプリを実行
2. 新しいノートを作成
3. 共有ボタンをタップ
4. UICloudSharingControllerが表示されることを確認

### 7.2 共有テスト

1. 共有URLを生成
2. 別のApple IDでサインインした端末でURLにアクセス
3. 共有ノートが表示されることを確認
4. 編集内容が同期されることを確認

## 🔧 Step 8: トラブルシューティング

### よくある問題と解決方法

#### 問題1: "Record not found" エラー
**原因**: レコードタイプでSharedが有効化されていない

**解決方法**:
1. CloudKit Dashboardでレコードタイプを確認
2. Shared設定を有効化
3. スキーマを本番環境に反映

#### 問題2: 共有URLが生成されない
**原因**: カスタムゾーンが作成されていない

**解決方法**:
CloudKitSharingManagerが自動的にカスタムゾーンを作成するまで待つ

#### 問題3: "Not authenticated" エラー
**原因**: iCloudにサインインしていない

**解決方法**:
設定 > [ユーザー名] > iCloud でサインインを確認

## 🎯 Step 9: 本番環境への準備

### 9.1 パフォーマンス最適化

```swift
// バックグラウンド更新の設定
private func setupBackgroundRefresh() {
    NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
    ) { _ in
        Task {
            try? await sharingManager.fetchRecords()
        }
    }
}
```

### 9.2 エラーハンドリングの強化

```swift
class ErrorHandler: ObservableObject {
    @Published var showingAlert = false
    @Published var alertMessage = ""
    
    func handle(_ error: Error) {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated:
                alertMessage = "iCloudにサインインしてください"
            case .networkFailure:
                alertMessage = "ネットワーク接続を確認してください"
            case .quotaExceeded:
                alertMessage = "iCloudストレージが不足しています"
            default:
                alertMessage = "エラーが発生しました: \\(ckError.localizedDescription)"
            }
        } else {
            alertMessage = error.localizedDescription
        }
        showingAlert = true
    }
}
```

## 🏁 完了！

これで CloudKitSharingKit の導入が完了しました。

さらなるカスタマイゼーションについては、以下のドキュメントを参照してください：

- [API Reference](API_Reference.md) - 詳細なAPI仕様
- [Best Practices](Best_Practices.md) - 実装のベストプラクティス
- [Troubleshooting](Troubleshooting.md) - 詳細なトラブルシューティング

## 📞 サポート

質問や問題がある場合は、GitHubのIssuesにお気軽に投稿してください。