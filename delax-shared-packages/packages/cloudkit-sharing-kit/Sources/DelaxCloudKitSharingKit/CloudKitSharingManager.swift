import Foundation
import CloudKit
import SwiftUI

/// CloudKit共有機能のエラー定義
public enum CloudKitSharingError: Error, LocalizedError {
    case noRecord
    case noShareRecord
    case shareNotFound
    case alreadyShared(existingShare: CKShare)
    case participantMayNeedVerification
    case tooManyParticipants
    case customZoneNotCreated
    
    public var errorDescription: String? {
        switch self {
        case .noRecord:
            return "レコードが見つかりません"
        case .noShareRecord:
            return "共有レコードが見つかりません"
        case .shareNotFound:
            return "共有が見つかりません"
        case .alreadyShared:
            return "既に共有されています"
        case .participantMayNeedVerification:
            return "参加者の認証が必要です"
        case .tooManyParticipants:
            return "参加者数の上限に達しています"
        case .customZoneNotCreated:
            return "カスタムゾーンが作成されていません"
        }
    }
}

/// CloudKit共有機能を提供する汎用マネージャー
@MainActor
public class CloudKitSharingManager<T: SharableRecord>: ObservableObject {
    
    // MARK: - Properties
    
    public let container: CKContainer
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    
    /// カスタムゾーンID（共有機能に必要）
    public let customZoneID: CKRecordZone.ID
    private var customZoneCreated = false
    
    @Published public var records: [T] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var isCloudKitAvailable = false
    
    private var hasValidatedCloudKit = false
    
    // MARK: - Initialization
    
    /// CloudKitSharingManagerを初期化
    /// - Parameters:
    ///   - containerIdentifier: CloudKitコンテナ識別子
    ///   - customZoneName: カスタムゾーン名（デフォルト: "SharingZone"）
    public init(containerIdentifier: String, customZoneName: String = "SharingZone") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.privateDatabase = container.privateCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
        self.customZoneID = CKRecordZone.ID(zoneName: customZoneName, ownerName: CKCurrentUserDefaultName)
        
        Task {
            await validateCloudKitConfiguration()
        }
    }
    
    // MARK: - CloudKit Configuration Validation
    
    /// CloudKit設定と可用性を検証
    public func validateCloudKitConfiguration() async {
        print("🔍 CloudKit設定検証開始...")
        
        do {
            // Step 1: アカウント状態チェック
            let accountStatus = try await container.accountStatus()
            print("📱 iCloudアカウント状態: \\(accountStatusDescription(accountStatus))")
            
            guard accountStatus == .available else {
                await MainActor.run {
                    self.isCloudKitAvailable = false
                    self.errorMessage = "iCloudアカウントが利用できません: \\(accountStatusDescription(accountStatus))"
                }
                return
            }
            
            // Step 2: データベースアクセス権限チェック
            let permissions = try await container.requestApplicationPermission(.userDiscoverability)
            print("🔐 アプリケーション権限: \\(permissionDescription(permissions))")
            
            // Step 3: 接続テスト
            try await performConnectivityTest()
            
            // Step 4: カスタムゾーン確認・作成
            try await ensureCustomZoneExists()
            
            await MainActor.run {
                self.isCloudKitAvailable = true
                self.hasValidatedCloudKit = true
                print("✅ CloudKit設定検証完了 - 利用可能")
            }
            
        } catch {
            print("❌ CloudKit設定検証失敗: \\(error)")
            await MainActor.run {
                self.isCloudKitAvailable = false
                self.errorMessage = "CloudKit設定検証エラー: \\(error.localizedDescription)"
            }
        }
    }
    
    /// カスタムゾーンの存在確認・作成
    private func ensureCustomZoneExists() async throws {
        guard !customZoneCreated else { return }
        
        print("🏗️ カスタムゾーン確認・作成...")
        
        do {
            // 既存ゾーンの確認
            let zones = try await privateDatabase.allRecordZones()
            let existingZone = zones.first { $0.zoneID == customZoneID }
            
            if existingZone != nil {
                print("✅ カスタムゾーン「\\(customZoneID.zoneName)」が既に存在します")
            } else {
                // カスタムゾーンを作成
                let customZone = CKRecordZone(zoneID: customZoneID)
                let savedZones = try await privateDatabase.modifyRecordZones(saving: [customZone], deleting: [])
                
                if savedZones.count > 0 {
                    print("✅ カスタムゾーン「\\(customZoneID.zoneName)」を作成しました")
                } else {
                    throw CloudKitSharingError.customZoneNotCreated
                }
            }
            
            customZoneCreated = true
            
        } catch {
            print("❌ カスタムゾーン作成失敗: \\(error)")
            throw error
        }
    }
    
    // MARK: - Record Operations
    
    /// レコードを保存
    /// - Parameter record: 保存するレコード
    /// - Returns: 保存されたレコード
    public func saveRecord(_ record: T) async throws -> T {
        guard customZoneCreated else {
            try await ensureCustomZoneExists()
        }
        
        let ckRecord = record.toCKRecord(zoneID: customZoneID)
        let savedRecord = try await privateDatabase.save(ckRecord)
        
        return T(from: savedRecord, shareRecord: record.shareRecord)
    }
    
    /// レコードを削除
    /// - Parameter record: 削除するレコード
    public func deleteRecord(_ record: T) async throws {
        guard let ckRecord = record.record else {
            throw CloudKitSharingError.noRecord
        }
        
        _ = try await privateDatabase.deleteRecord(withID: ckRecord.recordID)
    }
    
    /// カスタムゾーンからレコードを取得
    public func fetchRecords() async throws {
        guard customZoneCreated else {
            try await ensureCustomZoneExists()
        }
        
        await MainActor.run { self.isLoading = true }
        
        do {
            let changesOperation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [customZoneID])
            var fetchedRecords: [CKRecord] = []
            var fetchedShares: [CKShare] = []
            
            changesOperation.recordChangedBlock = { record in
                if record is CKShare {
                    fetchedShares.append(record as! CKShare)
                } else {
                    fetchedRecords.append(record)
                }
            }
            
            changesOperation.recordZoneChangeTokensUpdatedBlock = { _, _, _ in }
            changesOperation.recordZoneFetchCompletionBlock = { _, _, _, _, error in
                if let error = error {
                    print("❌ レコードゾーン取得エラー: \\(error)")
                }
            }
            
            let (_, error) = try await privateDatabase.add(changesOperation)
            if let error = error {
                throw error
            }
            
            // レコードと共有の関連付け
            let records = fetchedRecords.compactMap { record -> T? in
                let relatedShare = fetchedShares.first { share in
                    share.rootRecord?.recordID == record.recordID
                }
                return T(from: record, shareRecord: relatedShare)
            }
            
            await MainActor.run {
                self.records = records
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
    
    // MARK: - Sharing Operations
    
    /// レコードの共有を開始
    /// - Parameter record: 共有するレコード
    /// - Returns: 作成された共有レコード
    public func startSharing(record: T) async throws -> CKShare {
        guard let rootRecord = record.record else {
            throw CloudKitSharingError.noRecord
        }
        
        // 既に共有されているかチェック
        if let existingShare = record.shareRecord {
            throw CloudKitSharingError.alreadyShared(existingShare: existingShare)
        }
        
        print("🔗 共有作成開始 - レコード: \\(rootRecord.recordID.recordName)")
        
        // 新しい共有レコードを作成
        let share = CKShare(rootRecord: rootRecord)
        share.publicPermission = .readWrite
        
        print("📝 共有レコード作成完了")
        print("   Root Record: \\(share.rootRecord?.recordID.recordName ?? "なし")")
        print("   Zone ID: \\(share.recordID.zoneID)")
        
        // rootRecordとshareを同時に保存（CloudKitの要件）
        let modifyOperation = CKModifyRecordsOperation(
            recordsToSave: [rootRecord, share],
            recordIDsToDelete: []
        )
        
        modifyOperation.savePolicy = .changedKeys
        modifyOperation.configuration.isLongLived = true
        
        print("🔄 CKModifyRecordsOperation 実行中...")
        
        let (savedRecords, _) = try await privateDatabase.add(modifyOperation)
        
        guard let savedShare = savedRecords.first(where: { $0 is CKShare }) as? CKShare else {
            throw CloudKitSharingError.shareNotFound
        }
        
        print("✅ 共有レコード保存成功")
        print("   共有ID: \\(savedShare.recordID.recordName)")
        print("   参加者数: \\(savedShare.participants.count)")
        
        return savedShare
    }
    
    /// 共有を停止
    /// - Parameter record: 共有を停止するレコード
    public func stopSharing(record: T) async throws {
        guard let share = record.shareRecord else {
            throw CloudKitSharingError.noShareRecord
        }
        
        _ = try await privateDatabase.deleteRecord(withID: share.recordID)
        print("⏹️ 共有を停止しました")
    }
    
    // MARK: - Helper Methods
    
    private func performConnectivityTest() async throws {
        let testRecordID = CKRecord.ID(recordName: "connectivityTest")
        let testRecord = CKRecord(recordType: "ConnectivityTest", recordID: testRecordID)
        testRecord["timestamp"] = Date()
        
        do {
            _ = try await privateDatabase.save(testRecord)
            _ = try await privateDatabase.deleteRecord(withID: testRecordID)
            print("✅ CloudKit接続テスト成功")
        } catch {
            print("⚠️ CloudKit接続テストで問題が発生: \\(error)")
            // 接続テストの失敗は警告とするが、処理は継続
        }
    }
    
    private func accountStatusDescription(_ status: CKAccountStatus) -> String {
        switch status {
        case .available: return "利用可能"
        case .noAccount: return "iCloudアカウントなし"
        case .restricted: return "制限あり"
        case .couldNotDetermine: return "判定不可能"
        case .temporarilyUnavailable: return "一時的に利用不可"
        @unknown default: return "不明な状態"
        }
    }
    
    private func permissionDescription(_ permission: CKContainer.ApplicationPermissionStatus) -> String {
        switch permission {
        case .initialState: return "初期状態"
        case .couldNotComplete: return "完了不可"
        case .denied: return "拒否"
        case .granted: return "許可"
        @unknown default: return "不明な権限状態"
        }
    }
}