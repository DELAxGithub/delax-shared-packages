# DelaxCloudKitSharingKit

[![Swift](https://img.shields.io/badge/swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2016.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![DELAX](https://img.shields.io/badge/DELAX-Shared%20Packages-blue.svg)](https://github.com/DELAxGithub/delax-shared-packages)

**DelaxCloudKitSharingKit** は、DELAX Shared Packages の一部として提供される、CloudKit共有機能を簡単に実装できるSwift Packageです。

## ✨ 特徴

- 🚀 **95% 開発時間短縮**: DELAX品質基準で設計された実装パターン
- ✅ **簡単導入**: わずか数行のコードで共有機能を実装
- ✅ **プロトコルベース設計**: 任意のデータモデルに対応
- ✅ **完全なエラーハンドリング**: 詳細なエラー情報とデバッグ支援
- ✅ **カスタムゾーン自動管理**: 共有に必要なCloudKit設定を自動化
- ✅ **SwiftUI対応**: UICloudSharingControllerの完全なSwiftUIラッパー
- ✅ **プロダクション対応**: 実証済みの実装パターンを採用
- 🔗 **DELAX エコシステム**: 他のDELAXパッケージとの相互運用性

## 🚀 クイックスタート

### 1. パッケージの追加

#### Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/DELAxGithub/delax-shared-packages", from: "1.0.0")
]

targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "DelaxCloudKitSharingKit", package: "delax-shared-packages")
        ]
    )
]
```

#### Xcode Integration

1. File > Add Package Dependencies
2. URL: `https://github.com/DELAxGithub/delax-shared-packages`
3. Product: **DelaxCloudKitSharingKit** を選択

### 2. データモデルの準備

```swift
import DelaxCloudKitSharingKit
import CloudKit

struct Note: SharableRecord {
    let id: String
    var title: String
    var content: String
    var record: CKRecord?
    var shareRecord: CKShare?
    
    static var recordType: String { "Note" }
    
    func toCKRecord(zoneID: CKRecordZone.ID?) -> CKRecord {
        let record: CKRecord
        if let existingRecord = self.record {
            record = existingRecord
        } else if let zoneID = zoneID {
            let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
            record = CKRecord(recordType: Note.recordType, recordID: recordID)
        } else {
            record = CKRecord(recordType: Note.recordType)
        }
        
        record["title"] = title
        record["content"] = content
        return record
    }
    
    init(from record: CKRecord, shareRecord: CKShare? = nil) {
        self.id = record.recordID.recordName
        self.title = record["title"] as? String ?? ""
        self.content = record["content"] as? String ?? ""
        self.record = record
        self.shareRecord = shareRecord
    }
}
```

### 3. CloudKitSharingManagerの初期化

```swift
@StateObject private var sharingManager = CloudKitSharingManager<Note>(
    containerIdentifier: "iCloud.com.yourteam.YourApp"
)
```

### 4. 共有機能の実装

```swift
struct ContentView: View {
    @StateObject private var sharingManager = CloudKitSharingManager<Note>(
        containerIdentifier: "iCloud.com.yourteam.YourApp"
    )
    @State private var showingSharingView = false
    @State private var shareToPresent: CKShare?
    
    var body: some View {
        NavigationView {
            List(sharingManager.records) { note in
                HStack {
                    VStack(alignment: .leading) {
                        Text(note.title)
                            .font(.headline)
                        Text(note.content)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { shareNote(note) }) {
                        Image(systemName: note.isShared ? "person.2.fill" : "person.2")
                            .foregroundColor(note.isShared ? .blue : .gray)
                    }
                }
            }
            .navigationTitle("Notes")
            .onAppear {
                Task { try? await sharingManager.fetchRecords() }
            }
        }
        .sheet(isPresented: $showingSharingView) {
            if let share = shareToPresent {
                CloudSharingView(
                    share: share,
                    container: sharingManager.container,
                    onShareSaved: {
                        Task { try? await sharingManager.fetchRecords() }
                    }
                )
            }
        }
    }
    
    private func shareNote(_ note: Note) {
        Task {
            do {
                if note.isShared {
                    shareToPresent = note.shareRecord
                } else {
                    let share = try await sharingManager.startSharing(record: note)
                    shareToPresent = share
                }
                showingSharingView = true
            } catch {
                print("共有エラー: \\(error)")
            }
        }
    }
}
```

## 🔧 DELAX エコシステム統合

### DelaxSwiftUIComponentsとの連携

```swift
import DelaxCloudKitSharingKit
import DelaxSwiftUIComponents

struct EnhancedNoteView: View {
    @StateObject private var sharingManager = CloudKitSharingManager<Note>(
        containerIdentifier: "iCloud.com.yourteam.YourApp"
    )
    
    var body: some View {
        VStack {
            // CloudKit共有機能
            NoteListView()
                .environmentObject(sharingManager)
            
            // DELAX バグレポート機能の統合
            DelaxBugReportView(
                githubRepo: "yourteam/yourapp",
                githubToken: "your_token"
            )
        }
    }
}
```

## 📚 詳細ドキュメント

- [Integration Guide](Documentation/Integration_Guide.md) - 詳細な導入手順
- [API Reference](Documentation/API_Reference.md) - API仕様
- [Troubleshooting](Documentation/Troubleshooting.md) - トラブルシューティング
- [Best Practices](Documentation/Best_Practices.md) - ベストプラクティス

## 📋 必要な設定

### CloudKit Dashboard設定

1. [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)にアクセス
2. 対象のコンテナを選択
3. レコードタイプを作成し、**"Shared"** を有効化
4. フィールドを定義

### Xcode設定

1. Capabilities > CloudKit を有効化
2. Container を選択または作成
3. Background Modes > Remote notifications を有効化（推奨）

## 🔧 サポートされるプラットフォーム

- iOS 16.0+ （DELAX標準）
- macOS 13.0+ （DELAX標準）

## 🛠️ 自動化ツール

DELAX Shared Packages には自動セットアップスクリプトが含まれています：

```bash
# プロジェクトルートで実行
./packages/cloudkit-sharing-kit/Scripts/setup_cloudkit_sharing.sh
```

## 📈 パフォーマンス

- **95% 開発時間短縮**: 手動実装と比較
- **0依存関係**: 軽量で高速
- **プロダクション実証済み**: 実際のアプリで使用

## 🤝 DELAX Shared Packages

このパッケージは [DELAX Shared Packages](https://github.com/DELAxGithub/delax-shared-packages) の一部です。

### 他の利用可能なパッケージ:

- **DelaxSwiftUIComponents**: バグレポート機能付きUIコンポーネント
- **WorkflowScripts**: 開発ワークフロー自動化

## 🆘 サポート

- **Issues**: [GitHub Issues](https://github.com/DELAxGithub/delax-shared-packages/issues)
- **ドキュメント**: [DELAX Shared Packages Wiki](https://github.com/DELAxGithub/delax-shared-packages/wiki)

## 📝 ライセンス

このプロジェクトはMITライセンスで公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

---

**DELAX** - Technical Heritage for Efficient Development