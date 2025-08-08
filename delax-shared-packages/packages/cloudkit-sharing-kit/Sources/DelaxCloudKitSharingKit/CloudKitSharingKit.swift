// DelaxCloudKitSharingKit - Public Interface

/// DelaxCloudKitSharingKit フレームワーク
/// DELAX Shared Packages の一部として提供される CloudKit共有機能パッケージ
/// 
/// ## 主要コンポーネント
/// - `SharableRecord`: 共有可能レコードのプロトコル
/// - `CloudKitSharingManager`: CloudKit共有機能の管理
/// - `CloudSharingView`: UICloudSharingControllerのSwiftUIラッパー
/// - `CloudKitSharingError`: 共有関連エラーの定義
///
/// ## 基本的な使用方法
/// ```swift
/// import DelaxCloudKitSharingKit
///
/// // 1. データモデルをSharableRecordに準拠
/// struct MyRecord: SharableRecord {
///     let id: String
///     var record: CKRecord?
///     var shareRecord: CKShare?
///     
///     static var recordType: String { "MyRecord" }
///     
///     func toCKRecord(zoneID: CKRecordZone.ID?) -> CKRecord {
///         // 実装
///     }
///     
///     init(from record: CKRecord, shareRecord: CKShare?) {
///         // 実装
///     }
/// }
///
/// // 2. CloudKitSharingManagerを初期化
/// let manager = CloudKitSharingManager<MyRecord>(
///     containerIdentifier: "iCloud.com.example.MyApp"
/// )
///
/// // 3. 共有機能を使用
/// let share = try await manager.startSharing(record: myRecord)
/// ```

import Foundation

/// DelaxCloudKitSharingKitのバージョン情報
public struct DelaxCloudKitSharingKitInfo {
    /// ライブラリバージョン
    public static let version = "1.0.0"
    
    /// サポートするiOSの最小バージョン
    public static let minimumIOSVersion = "16.0"
    
    /// 作成者情報
    public static let author = "DELAX - Claude Code"
    
    /// ライセンス情報
    public static let license = "MIT"
    
    /// リポジトリURL
    public static let repositoryURL = "https://github.com/DELAxGithub/delax-shared-packages"
}