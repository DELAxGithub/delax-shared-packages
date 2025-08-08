// CloudKitSharingKit - Minimal Implementation Template
// 最小限のコードでCloudKit共有機能を実装するテンプレート

import SwiftUI
import DelaxCloudKitSharingKit
import CloudKit

// MARK: - Data Model

struct MyRecord: SharableRecord {
    // 必須プロパティ
    let id: String
    var record: CKRecord?
    var shareRecord: CKShare?
    
    // あなたのデータプロパティ
    var title: String
    var content: String
    
    // レコードタイプ名（CloudKit Dashboardで設定したもの）
    static var recordType: String { "MyRecord" }
    
    // 初期化（新規作成用）
    init(title: String, content: String = "") {
        self.id = UUID().uuidString
        self.title = title
        self.content = content
        self.record = nil
        self.shareRecord = nil
    }
    
    // 初期化（CloudKitレコードから）
    init(from record: CKRecord, shareRecord: CKShare? = nil) {
        self.id = record.recordID.recordName
        self.title = record["title"] as? String ?? ""
        self.content = record["content"] as? String ?? ""
        self.record = record
        self.shareRecord = shareRecord
    }
    
    // CloudKitレコードに変換
    func toCKRecord(zoneID: CKRecordZone.ID?) -> CKRecord {
        let record: CKRecord
        
        if let existingRecord = self.record {
            record = existingRecord
        } else if let zoneID = zoneID {
            let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
            record = CKRecord(recordType: MyRecord.recordType, recordID: recordID)
        } else {
            record = CKRecord(recordType: MyRecord.recordType)
        }
        
        record["title"] = title
        record["content"] = content
        
        return record
    }
}

// MARK: - Main App

@main
struct MinimalSharingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    // CloudKitSharingManagerを初期化
    // ⚠️ "iCloud.com.yourteam.YourApp" を実際のContainer IDに変更してください
    @StateObject private var sharingManager = CloudKitSharingManager<MyRecord>(
        containerIdentifier: "iCloud.com.yourteam.YourApp"
    )
    
    @State private var showingSharingView = false
    @State private var shareToPresent: CKShare?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sharingManager.records) { record in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(record.title)
                                .font(.headline)
                            Text(record.content)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // 共有ボタン
                        Button(action: {
                            shareRecord(record)
                        }) {
                            Image(systemName: record.isShared ? "person.2.fill" : "person.2")
                                .foregroundColor(record.isShared ? .blue : .gray)
                        }
                    }
                }
            }
            .navigationTitle("My Records")
            .onAppear {
                loadRecords()
            }
        }
        .sheet(isPresented: $showingSharingView) {
            if let share = shareToPresent {
                CloudSharingView(
                    share: share,
                    container: sharingManager.container
                )
            }
        }
    }
    
    // レコード読み込み
    private func loadRecords() {
        Task {
            try? await sharingManager.fetchRecords()
        }
    }
    
    // 共有機能
    private func shareRecord(_ record: MyRecord) {
        Task {
            do {
                if let existingShare = record.shareRecord {
                    shareToPresent = existingShare
                } else {
                    let share = try await sharingManager.startSharing(record: record)
                    shareToPresent = share
                }
                showingSharingView = true
            } catch {
                print("共有エラー: \\(error)")
            }
        }
    }
}

// MARK: - Setup Instructions

/*
 
 📋 セットアップ手順:

 1. CloudKit Dashboard設定:
    - icloud.developer.apple.com にアクセス
    - MyRecord レコードタイプを作成
    - title (String) と content (String) フィールドを追加
    - Shared を有効化
 
 2. Xcode設定:
    - Capabilities > CloudKit を有効化
    - Container ID を設定
 
 3. Container ID変更:
    - 上記の "iCloud.com.yourteam.YourApp" を実際のIDに変更
 
 4. 実行:
    - ビルド & 実行
    - 共有ボタンをタップして動作確認
 
 */