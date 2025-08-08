import Foundation
import CloudKit

struct Note: Identifiable, Hashable {
    let id: String
    var title: String
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    var isFavorite: Bool
    var record: CKRecord?
    var shareRecord: CKShare?
    
    // 共有状態を判定
    var isShared: Bool {
        // shareRecordが存在する、またはrecordに共有参照がある場合は共有状態
        return shareRecord != nil || record?.share != nil
    }
    
    // 共有URLを取得
    var shareURL: URL? {
        return shareRecord?.url
    }
    
    init(id: String = UUID().uuidString, title: String, content: String = "", createdAt: Date = Date(), modifiedAt: Date = Date(), isFavorite: Bool = false, shareRecord: CKShare? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isFavorite = isFavorite
        self.record = nil // 新規作成時はnilで開始
        self.shareRecord = shareRecord
    }
    
    init(from record: CKRecord, shareRecord: CKShare? = nil) {
        self.id = record.recordID.recordName
        self.title = record["title"] as? String ?? ""
        self.content = record["content"] as? String ?? ""
        self.createdAt = record["createdAt"] as? Date ?? record.creationDate ?? Date()
        self.modifiedAt = record["modifiedAt"] as? Date ?? record.modificationDate ?? Date()
        // CloudKitではINT64として保存されるため、数値から変換
        if let favoriteValue = record["isFavorite"] as? Int64 {
            self.isFavorite = favoriteValue != 0
        } else {
            self.isFavorite = false
        }
        self.record = record
        self.shareRecord = shareRecord
        
        // デバッグ情報の出力
        let hasShareReference = record.share != nil
        let hasShareRecord = shareRecord != nil
        print("📋 Note作成 - ID: \(id), タイトル: \(title)")
        print("   共有参照: \(hasShareReference ? "あり" : "なし")")
        print("   共有レコード: \(hasShareRecord ? "あり" : "なし")")
        print("   最終共有状態: \(self.isShared)")
    }
    
    func toCKRecord(zoneID: CKRecordZone.ID? = nil) -> CKRecord {
        let record: CKRecord
        if let existingRecord = self.record {
            record = existingRecord
        } else {
            // 新規作成時はカスタムゾーンを指定
            if let zoneID = zoneID {
                let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
                record = CKRecord(recordType: "Note", recordID: recordID)
            } else {
                record = CKRecord(recordType: "Note")
            }
        }
        
        record["title"] = title
        record["content"] = content
        record["createdAt"] = createdAt
        record["modifiedAt"] = Date() // 保存時に更新
        // CloudKitではINT64として保存
        record["isFavorite"] = isFavorite ? 1 : 0
        return record
    }
}