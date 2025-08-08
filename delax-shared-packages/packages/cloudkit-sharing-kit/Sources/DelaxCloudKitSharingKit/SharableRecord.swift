import Foundation
import CloudKit

/// CloudKit共有機能を持つレコードが実装すべきプロトコル
public protocol SharableRecord: Identifiable {
    /// レコードの一意識別子
    var id: String { get }
    
    /// CloudKitレコード（存在する場合）
    var record: CKRecord? { get set }
    
    /// 共有レコード（共有されている場合）
    var shareRecord: CKShare? { get set }
    
    /// CloudKitレコードに変換
    /// - Parameter zoneID: カスタムゾーンID（共有機能を使用する場合は必須）
    /// - Returns: CloudKitレコード
    func toCKRecord(zoneID: CKRecordZone.ID?) -> CKRecord
    
    /// CloudKitレコードから初期化
    /// - Parameters:
    ///   - record: CloudKitレコード
    ///   - shareRecord: 共有レコード（オプション）
    init(from record: CKRecord, shareRecord: CKShare?)
    
    /// レコードタイプ名
    static var recordType: String { get }
}

/// SharableRecordの基本実装を提供
public extension SharableRecord {
    /// 共有状態を判定
    var isShared: Bool {
        return shareRecord != nil || record?.share != nil
    }
    
    /// 共有URLを取得
    var shareURL: URL? {
        return shareRecord?.url
    }
    
    /// 共有権限を取得
    var sharePermission: CKShare.ParticipantPermission? {
        return shareRecord?.currentUserParticipant?.permission
    }
    
    /// 現在のユーザーが所有者かどうかを判定
    var isOwner: Bool {
        guard let shareRecord = shareRecord else { return true } // 共有されていない場合は所有者
        return shareRecord.currentUserParticipant?.role == .owner
    }
}