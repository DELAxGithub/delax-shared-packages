import Foundation
import CloudKit
import DelaxCloudKitSharingKit

struct Note: SharableRecord {
    // MARK: - SharableRecord Protocol
    let id: String
    var record: CKRecord?
    var shareRecord: CKShare?
    
    static var recordType: String { "Note" }
    
    // MARK: - Note Properties
    var title: String
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    
    // MARK: - Initializers
    
    /// 新しいノートを作成
    init(title: String, content: String = "") {
        self.id = UUID().uuidString
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.record = nil
        self.shareRecord = nil
    }
    
    /// CloudKitレコードからノートを作成
    init(from record: CKRecord, shareRecord: CKShare? = nil) {
        self.id = record.recordID.recordName
        self.title = record["title"] as? String ?? "Untitled"
        self.content = record["content"] as? String ?? ""
        self.createdAt = record["createdAt"] as? Date ?? record.creationDate ?? Date()
        self.modifiedAt = record["modifiedAt"] as? Date ?? record.modificationDate ?? Date()
        self.record = record
        self.shareRecord = shareRecord
    }
    
    // MARK: - CloudKit Conversion
    
    func toCKRecord(zoneID: CKRecordZone.ID?) -> CKRecord {
        let record: CKRecord
        
        if let existingRecord = self.record {
            // 既存のレコードを更新
            record = existingRecord
        } else {
            // 新しいレコードを作成
            if let zoneID = zoneID {
                // カスタムゾーンでレコードを作成（共有機能用）
                let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
                record = CKRecord(recordType: Note.recordType, recordID: recordID)
            } else {
                // デフォルトゾーンでレコードを作成
                record = CKRecord(recordType: Note.recordType)
            }
        }
        
        // フィールドの設定
        record["title"] = title
        record["content"] = content
        record["createdAt"] = createdAt
        record["modifiedAt"] = Date() // 保存時に更新
        
        return record
    }
}

// MARK: - Computed Properties

extension Note {
    /// ノートが空かどうか
    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 表示用のプレビューテキスト
    var preview: String {
        let preview = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if preview.isEmpty {
            return "No content"
        }
        return String(preview.prefix(100))
    }
    
    /// 最後の更新からの経過時間表示
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: modifiedAt, relativeTo: Date())
    }
}