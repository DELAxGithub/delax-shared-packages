import Foundation
import CloudKit
import SwiftUI

// 共有関連エラーの定義
enum CloudKitSharingError: Error, LocalizedError {
    case noRecord
    case noShareRecord
    case shareNotFound
    case alreadyShared(existingShare: CKShare)
    case participantMayNeedVerification
    case tooManyParticipants
    
    var errorDescription: String? {
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
        }
    }
}

// クエリを使わない代替実装
@MainActor
class CloudKitManagerAlternative: ObservableObject {
    let container: CKContainer
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    private let recordIDsKey = "SavedNoteRecordIDs"
    
    // カスタムゾーン管理（共有対応）
    private let customZoneID = CKRecordZone.ID(zoneName: "NotesZone", ownerName: CKCurrentUserDefaultName)
    private var customZoneCreated = false
    
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSetupGuide = false
    
    // CloudKit状態管理
    @Published var isCloudKitAvailable = false
    private var hasValidatedCloudKit = false
    
    init() {
        container = CKContainer(identifier: "iCloud.Delax.CloudKitStarter")
        privateDatabase = container.privateCloudDatabase
        sharedDatabase = container.sharedCloudDatabase
        
        // 初期化時にCloudKit状態を検証
        Task {
            await validateCloudKitConfiguration()
        }
    }
    
    // MARK: - CloudKit Configuration Validation
    
    /// CloudKit設定と可用性を検証
    func validateCloudKitConfiguration() async {
        print("🔍 CloudKit設定検証開始...")
        
        do {
            // Step 1: アカウント状態チェック
            let accountStatus = try await container.accountStatus()
            print("📱 iCloudアカウント状態: \(accountStatusDescription(accountStatus))")
            
            guard accountStatus == .available else {
                await MainActor.run {
                    self.isCloudKitAvailable = false
                    self.errorMessage = "iCloudアカウントが利用できません: \(accountStatusDescription(accountStatus))"
                    self.showSetupGuide = true
                }
                return
            }
            
            // Step 2: データベースアクセス権限チェック
            let permissions = try await container.requestApplicationPermission(.userDiscoverability)
            print("🔐 アプリケーション権限: \(permissionDescription(permissions))")
            
            // Step 3: 接続テスト（軽量なレコード操作）
            try await performConnectivityTest()
            
            // Step 4: コンテナ固有設定チェック
            try await validateContainerConfiguration()
            
            // Step 5: カスタムゾーン確認・作成
            try await ensureCustomZoneExists()
            
            await MainActor.run {
                self.isCloudKitAvailable = true
                self.hasValidatedCloudKit = true
                print("✅ CloudKit設定検証完了 - 利用可能")
            }
            
        } catch {
            print("❌ CloudKit設定検証失敗: \(error.localizedDescription)")
            await MainActor.run {
                self.isCloudKitAvailable = false
                self.errorMessage = "CloudKitの設定に問題があります: \(error.localizedDescription)"
                self.handleCloudKitError(error)
            }
        }
    }
    
    /// 接続テストを実行
    private func performConnectivityTest() async throws {
        // 軽量なテストレコードでデータベース接続を確認
        let testRecord = CKRecord(recordType: "TestConnection")
        testRecord["timestamp"] = Date() as CKRecordValue
        
        // テスト保存（すぐに削除）
        let savedRecord = try await privateDatabase.save(testRecord)
        print("🔄 接続テスト: レコード保存成功")
        
        // テストレコードを削除
        try await privateDatabase.deleteRecord(withID: savedRecord.recordID)
        print("🗑️ 接続テスト: テストレコード削除完了")
    }
    
    /// コンテナ設定の追加検証
    private func validateContainerConfiguration() async throws {
        // コンテナIDの確認
        let containerID = container.containerIdentifier
        print("📦 コンテナID確認: \(containerID ?? "Unknown")")
        
        // 基本的なスキーマ存在確認（Noteレコードタイプ）
        // Note: この段階では実際のスキーマチェックは行わず、基本的な接続確認のみ
        print("📋 基本設定確認完了")
    }
    
    /// カスタムゾーン存在確認・作成（共有対応）
    private func ensureCustomZoneExists() async throws {
        print("🏗️ カスタムゾーン確認: \(customZoneID.zoneName)")
        
        do {
            // 既存ゾーンを確認
            let existingZone = try await privateDatabase.recordZone(for: customZoneID)
            print("✅ カスタムゾーン存在確認: \(existingZone.zoneID.zoneName)")
            customZoneCreated = true
        } catch {
            let ckError = error as? CKError
            if ckError?.code == .zoneNotFound {
                print("🆕 カスタムゾーン未存在 - 新規作成")
                try await createCustomZone()
            } else {
                print("❌ カスタムゾーン確認エラー: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    /// カスタムゾーンを作成
    private func createCustomZone() async throws {
        let customZone = CKRecordZone(zoneID: customZoneID)
        
        let saveZoneOperation = CKModifyRecordZonesOperation(
            recordZonesToSave: [customZone],
            recordZoneIDsToDelete: nil
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            saveZoneOperation.modifyRecordZonesResultBlock = { result in
                switch result {
                case .success:
                    print("✅ カスタムゾーン作成成功: \(self.customZoneID.zoneName)")
                    self.customZoneCreated = true
                    continuation.resume()
                case .failure(let error):
                    print("❌ カスタムゾーン作成失敗: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
            
            saveZoneOperation.qualityOfService = .userInitiated
            privateDatabase.add(saveZoneOperation)
        }
    }
    
    /// アカウント状態の説明を取得
    private func accountStatusDescription(_ status: CKAccountStatus) -> String {
        switch status {
        case .available:
            return "利用可能"
        case .noAccount:
            return "iCloudアカウントなし"
        case .restricted:
            return "制限されています"
        case .couldNotDetermine:
            return "状態を確認できません"
        case .temporarilyUnavailable:
            return "一時的に利用できません"
        @unknown default:
            return "不明な状態"
        }
    }
    
    /// 権限状態の説明を取得
    private func permissionDescription(_ permission: CKContainer.ApplicationPermissionStatus) -> String {
        switch permission {
        case .initialState:
            return "初期状態"
        case .couldNotComplete:
            return "完了できませんでした"
        case .denied:
            return "拒否"
        case .granted:
            return "許可"
        @unknown default:
            return "不明"
        }
    }
    
    // レコードIDを使って個別に取得（クエリを回避）
    func fetchNotes() {
        // 統合データ取得を使用
        loadAllNotes()
    }
    
    func saveNote(_ note: Note, completion: @escaping (Result<Note, Error>) -> Void) {
        // CloudKit可用性チェック
        guard isCloudKitAvailable else {
            print("❌ CloudKit利用不可 - Note保存中止")
            completion(.failure(CloudKitSharingError.shareNotFound))
            return
        }
        
        let record = note.toCKRecord(zoneID: customZoneID)
        
        privateDatabase.save(record) { [weak self] savedRecord, error in
            Task { @MainActor [weak self] in
                if let error = error {
                    self?.handleCloudKitError(error)
                    completion(.failure(error))
                    return
                }
                
                if let savedRecord = savedRecord {
                    // レコードIDを保存
                    self?.saveRecordID(savedRecord.recordID.recordName)
                    
                    let savedNote = Note(from: savedRecord)
                    completion(.success(savedNote))
                    
                    // リストを更新
                    self?.loadAllNotes()
                }
            }
        }
    }
    
    func deleteNote(_ note: Note, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let record = note.record else {
            completion(.failure(NSError(domain: "CloudKitManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No record found"])))
            return
        }
        
        privateDatabase.delete(withRecordID: record.recordID) { [weak self] _, error in
            Task { @MainActor [weak self] in
                if let error = error {
                    completion(.failure(error))
                } else {
                    // レコードIDを削除
                    self?.removeRecordID(record.recordID.recordName)
                    completion(.success(()))
                    
                    // リストを更新
                    self?.loadAllNotes()
                }
            }
        }
    }
    
    func toggleFavorite(_ note: Note) {
        var updatedNote = note
        updatedNote.isFavorite.toggle()
        updatedNote.modifiedAt = Date()
        
        saveNote(updatedNote) { result in
            switch result {
            case .success:
                print("お気に入りを更新しました")
            case .failure(let error):
                print("お気に入り更新エラー: \(error)")
            }
        }
    }
    
    // MARK: - レコードID管理
    
    private func getSavedRecordIDs() -> [String] {
        UserDefaults.standard.stringArray(forKey: recordIDsKey) ?? []
    }
    
    private func saveRecordID(_ recordID: String) {
        var ids = getSavedRecordIDs()
        if !ids.contains(recordID) {
            ids.append(recordID)
            UserDefaults.standard.set(ids, forKey: recordIDsKey)
        }
    }
    
    private func removeRecordID(_ recordID: String) {
        var ids = getSavedRecordIDs()
        ids.removeAll { $0 == recordID }
        UserDefaults.standard.set(ids, forKey: recordIDsKey)
    }
    
    // MARK: - 共有機能
    
    /// Step 1: CKShareを作成してURL生成まで待機（UIは起動しない）
    func createShare(for note: Note, completion: @escaping (Result<CKShare, Error>) -> Void) {
        print("🔄 【Step 1】 CKShare作成開始 - ノート: \(note.title)")
        print("   Note ID: \(note.id)")
        
        // CloudKit可用性を事前チェック
        guard isCloudKitAvailable else {
            print("❌ CloudKit利用不可 - 設定検証を再実行")
            Task {
                await validateCloudKitConfiguration()
                if !isCloudKitAvailable {
                    completion(.failure(CloudKitSharingError.shareNotFound))
                    return
                }
                // 検証成功後に再試行
                self.createShare(for: note, completion: completion)
            }
            return
        }
        print("   既存ShareRecord: \(note.shareRecord != nil ? "あり" : "なし")")
        print("   Record Share参照: \(note.record?.share != nil ? "あり" : "なし")")
        
        // 既に共有済みチェック
        if let existingShare = note.shareRecord {
            if existingShare.url != nil {
                print("✅ 【Step 1】 既存CKShare（URL生成済み）を再利用")
                completion(.success(existingShare))
            } else {
                print("🔄 【Step 1】 既存CKShareのURL生成待機")
                waitForShareURL(share: existingShare) { finalShare in
                    completion(.success(finalShare))
                }
            }
            return
        }
        
        // recordのshare参照をチェック（既存共有の可能性）
        if note.record?.share != nil {
            print("🔍 既存の共有参照を発見 - 共有レコードを取得中")
            fetchExistingShare(for: note.record!) { result in
                switch result {
                case .success(let existingShare):
                    print("✅ 既存共有レコードを取得")
                    if existingShare.url != nil {
                        completion(.success(existingShare))
                    } else {
                        print("🔄 【Step 1】 既存共有のURL生成待機")
                        self.waitForShareURL(share: existingShare) { finalShare in
                            completion(.success(finalShare))
                        }
                    }
                case .failure:
                    print("⚠️ 既存共有参照があるが共有レコード取得失敗 - 新規作成")
                    self.createNewShareWithOperation(for: note, completion: completion)
                }
            }
            return
        }
        
        // 新規共有作成
        createNewShareWithOperation(for: note, completion: completion)
    }
    
    /// 新規CKShare作成（CloudKit要件準拠: rootRecord + CKShare 同時保存）
    private func createNewShareWithOperation(for note: Note, completion: @escaping (Result<CKShare, Error>) -> Void) {
        guard let originalRecord = note.record else {
            print("❌ CKRecordが存在しません")
            completion(.failure(CloudKitSharingError.noRecord))
            return
        }
        
        // デフォルトゾーンのレコードはカスタムゾーンに移行
        let record: CKRecord
        if originalRecord.recordID.zoneID.zoneName == CKRecordZone.default().zoneID.zoneName {
            print("🔄 デフォルトゾーンレコードをカスタムゾーンに移行")
            let newRecordID = CKRecord.ID(recordName: originalRecord.recordID.recordName, zoneID: customZoneID)
            record = CKRecord(recordType: "Note", recordID: newRecordID)
            // フィールドをコピー
            for (key, value) in originalRecord.allKeys().compactMap({ key in
                originalRecord[key].map { (key, $0) }
            }) {
                record[key] = value
            }
        } else {
            record = originalRecord
        }
        
        // カスタムゾーンが未作成の場合はエラー
        guard customZoneCreated else {
            print("❌ カスタムゾーンが未作成です")
            completion(.failure(CloudKitSharingError.shareNotFound))
            return
        }
        
        print("🔄 【正式実装】rootRecord + CKShare 同時保存開始")
        print("   Zone: \(record.recordID.zoneID.zoneName)")
        
        // CKShareを作成
        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = "共有ノート: \(note.title)" as CKRecordValue
        
        // 【重要】rootRecord と CKShare を同一オペレーションで保存
        // デフォルトゾーンから移行する場合は古いレコードを削除
        let recordIDsToDelete = (record.recordID != originalRecord.recordID) ? [originalRecord.recordID] : nil
        
        let modifyOperation = CKModifyRecordsOperation(
            recordsToSave: [record, share],  // 両方を同時保存
            recordIDsToDelete: recordIDsToDelete  // 移行時は古いレコード削除
        )
        
        modifyOperation.modifyRecordsResultBlock = { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success:
                    print("✅ 【同時保存成功】rootRecord + CKShare 保存完了")
                    print("🔄 共有URL生成待機...")
                    
                    // URL生成待機（改良版）
                    self?.waitForShareURLEnhanced(share: share) { finalShare in
                        if finalShare.url != nil {
                            print("🎉 【完全成功】共有URL生成完了")
                        } else {
                            print("⚠️ 【部分成功】CKShare作成完了・URL生成保留")
                        }
                        completion(.success(finalShare))
                    }
                    
                case .failure(let error):
                    print("❌ 【同時保存失敗】エラー: \(error.localizedDescription)")
                    
                    if let ckError = error as? CKError {
                        print("   CKError Code: \(ckError.code.rawValue)")
                        
                        if ckError.code == .alreadyShared {
                            print("🔄 既存共有検出 - 取得実行")
                            self?.fetchExistingShare(for: record) { shareResult in
                                completion(shareResult)
                            }
                        } else {
                            completion(.failure(error))
                        }
                    } else {
                        completion(.failure(error))
                    }
                }
            }
        }
        
        modifyOperation.qualityOfService = .userInitiated
        privateDatabase.add(modifyOperation)
    }
    
    
    /// 既存のCKShareを取得
    private func fetchExistingShare(for record: CKRecord, completion: @escaping (Result<CKShare, Error>) -> Void) {
        // レコードのshare referenceを使用してCKShareを取得
        guard let shareReference = record.share else {
            completion(.failure(CloudKitSharingError.shareNotFound))
            return
        }
        
        privateDatabase.fetch(withRecordID: shareReference.recordID) { shareRecord, error in
            Task { @MainActor in
                if let error = error {
                    completion(.failure(error))
                } else if let share = shareRecord as? CKShare {
                    completion(.success(share))
                } else {
                    completion(.failure(CloudKitSharingError.shareNotFound))
                }
            }
        }
    }
    
    /// 共有データの取得（sharedCloudDatabase対応）
    func fetchSharedNotes(completion: @escaping ([Note]) -> Void) {
        sharedDatabase.fetchAllRecordZones { zones, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("共有ゾーン取得エラー: \(error)")
                    completion([])
                    return
                }
                
                guard let zones = zones else {
                    completion([])
                    return
                }
                
                var allSharedNotes: [Note] = []
                let group = DispatchGroup()
                
                // 各 zone のレコード取得
                for zone in zones {
                    group.enter()
                    self.fetchRecordsFromZone(zone.zoneID, database: self.sharedDatabase) { notes in
                        allSharedNotes.append(contentsOf: notes)
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    completion(allSharedNotes)
                }
            }
        }
    }
    
    /// 指定されたゾーンからレコードを取得（共有情報も含む）
    private func fetchRecordsFromZone(_ zoneID: CKRecordZone.ID, database: CKDatabase, completion: @escaping ([Note]) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Note", predicate: predicate)
        
        database.fetch(withQuery: query, inZoneWith: zoneID, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (matchResults, _)):
                    let group = DispatchGroup()
                    var notesWithShares: [Note] = []
                    
                    for (_, recordResult) in matchResults {
                        switch recordResult {
                        case .success(let record):
                            group.enter()
                            // 共有データベースの場合は、レコードが共有状態として扱う
                            if database == self.sharedDatabase {
                                // 共有データベースのレコードは常に共有されているものとして扱う
                                let note = Note(from: record, shareRecord: nil) // 実際のshareRecordは後で設定可能
                                notesWithShares.append(note)
                                group.leave()
                            } else {
                                // プライベートデータベースの場合は共有情報をチェック
                                self.fetchShareForRecord(record) { shareRecord in
                                    let note = Note(from: record, shareRecord: shareRecord)
                                    notesWithShares.append(note)
                                    group.leave()
                                }
                            }
                        case .failure:
                            continue
                        }
                    }
                    
                    group.notify(queue: .main) {
                        completion(notesWithShares)
                    }
                case .failure(let error):
                    print("ゾーン内レコード取得エラー: \(error)")
                    completion([])
                }
            }
        }
    }
    
    /// 共有解除（注意: 全参加者から削除される）
    func stopSharing(for note: Note, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let shareRecord = note.shareRecord else {
            completion(.failure(CloudKitSharingError.noShareRecord))
            return
        }
        
        // CKShare を削除すると全参加者から共有解除
        let operation = CKModifyRecordsOperation(recordIDsToDelete: [shareRecord.recordID])
        operation.modifyRecordsResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        privateDatabase.add(operation)
    }
    
    /// 統合データ取得（Private + Shared）- 状態管理強化版
    func loadAllNotes() {
        isLoading = true
        errorMessage = nil
        
        // CloudKit可用性チェック（バックグラウンドで再検証）
        if !isCloudKitAvailable && hasValidatedCloudKit {
            print("⚠️ CloudKit利用不可 - バックグラウンドで再検証中")
            Task {
                await validateCloudKitConfiguration()
                if isCloudKitAvailable {
                    print("✅ CloudKit復旧 - データ取得再開")
                    self.loadAllNotes()
                }
            }
            return
        }
        
        let group = DispatchGroup()
        var privateNotes: [Note] = []
        var sharedNotes: [Note] = []
        
        // Private notes
        group.enter()
        fetchPrivateNotes { notes in
            privateNotes = notes
            group.leave()
        }
        
        // Shared notes
        group.enter()
        fetchSharedNotes { notes in
            sharedNotes = notes
            group.leave()
        }
        
        group.notify(queue: .main) {
            // 重複を避けるため、IDをキーとした辞書を使用
            var notesDict: [String: Note] = [:]
            
            // プライベートノートを追加（より優先される）
            for note in privateNotes {
                notesDict[note.id] = note
            }
            
            // 共有ノートを追加（プライベートに存在しない場合のみ）
            for note in sharedNotes {
                if notesDict[note.id] == nil {
                    notesDict[note.id] = note
                }
            }
            
            let allNotes = Array(notesDict.values)
            
            print("📊 統合結果:")
            print("   プライベートノート: \(privateNotes.count)個")
            print("   共有ノート: \(sharedNotes.count)個")  
            print("   統合後ノート: \(allNotes.count)個")
            print("   共有状態のノート: \(allNotes.filter(\.isShared).count)個")
            
            // お気に入りを上部に表示し、それぞれのグループ内で更新日時でソート
            self.notes = allNotes.sorted { note1, note2 in
                if note1.isFavorite != note2.isFavorite {
                    return note1.isFavorite
                }
                return note1.modifiedAt > note2.modifiedAt
            }
            self.isLoading = false
        }
    }
    
    /// Private notes のみ取得（デフォルトゾーン + カスタムゾーン）
    private func fetchPrivateNotes(completion: @escaping ([Note]) -> Void) {
        let group = DispatchGroup()
        var allNotes: [Note] = []
        
        // デフォルトゾーンの既存ノート（レコードIDベース取得）
        group.enter()
        fetchNotesFromDefaultZone { defaultNotes in
            allNotes.append(contentsOf: defaultNotes)
            group.leave()
        }
        
        // カスタムゾーンのノート（クエリベース取得）
        if customZoneCreated {
            group.enter()
            fetchNotesFromCustomZone { customNotes in
                allNotes.append(contentsOf: customNotes)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(allNotes)
        }
    }
    
    /// デフォルトゾーンからノート取得（既存方式）
    private func fetchNotesFromDefaultZone(completion: @escaping ([Note]) -> Void) {
        // 保存されたレコードIDを取得
        let savedIDs = getSavedRecordIDs()
        
        if savedIDs.isEmpty {
            completion([])
            return
        }
        
        // レコードIDを使って個別に取得
        let recordIDs = savedIDs.compactMap { CKRecord.ID(recordName: $0) }
        
        privateDatabase.fetch(withRecordIDs: recordIDs) { [weak self] result in
            switch result {
            case .success(let recordsByID):
                let group = DispatchGroup()
                var notesWithShares: [Note] = []
                
                for (_, recordResult) in recordsByID {
                    switch recordResult {
                    case .success(let record):
                        group.enter()
                        Task { @MainActor [weak self] in
                            self?.fetchShareForRecord(record) { shareRecord in
                                let note = Note(from: record, shareRecord: shareRecord)
                                notesWithShares.append(note)
                                group.leave()
                            }
                        }
                    case .failure:
                        continue
                    }
                }
                
                group.notify(queue: .main) {
                    completion(notesWithShares)
                }
            case .failure(let error):
                print("デフォルトゾーンノート取得エラー: \(error)")
                completion([])
            }
        }
    }
    
    /// カスタムゾーンからノート取得（修正版：直接クエリではなくレコード取得を使用）
    private func fetchNotesFromCustomZone(completion: @escaping ([Note]) -> Void) {
        // カスタムゾーンの全レコードをrecordZoneChangesで取得
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [customZoneID], optionsByRecordZoneID: nil)
        var fetchedRecords: [CKRecord] = []
        
        operation.recordWasChangedBlock = { recordID, result in
            switch result {
            case .success(let record):
                if record.recordType == "Note" {
                    fetchedRecords.append(record)
                }
            case .failure(let error):
                print("レコード取得エラー: \(error)")
            }
        }
        
        operation.recordZoneFetchResultBlock = { zoneID, result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    let group = DispatchGroup()
                    var notesWithShares: [Note] = []
                    
                    for record in fetchedRecords {
                        group.enter()
                        self.fetchShareForRecord(record) { shareRecord in
                            let note = Note(from: record, shareRecord: shareRecord)
                            notesWithShares.append(note)
                            group.leave()
                        }
                    }
                    
                    group.notify(queue: .main) {
                        print("📋 カスタムゾーンから\(notesWithShares.count)件のノートを取得")
                        completion(notesWithShares)
                    }
                case .failure(let error):
                    print("カスタムゾーン変更取得エラー: \(error)")
                    completion([])
                }
            }
        }
        
        operation.fetchRecordZoneChangesResultBlock = { result in
            switch result {
            case .success:
                break // 各ゾーンの結果は上記で処理済み
            case .failure(let error):
                DispatchQueue.main.async {
                    print("カスタムゾーン取得操作エラー: \(error)")
                    completion([])
                }
            }
        }
        
        privateDatabase.add(operation)
    }
    
    /// 共有URL生成待機（CloudKit同時保存後のサーバー反映対応）
    private func waitForShareURL(share: CKShare, completion: @escaping (CKShare) -> Void) {
        print("🔄 CKShare URL生成待機開始（ID: \(share.recordID.recordName)）")
        
        // 段階的な待機戦略: 短い間隔から始めて徐々に間隔を延ばす
        let intervals: [TimeInterval] = [2.0, 3.0, 3.0, 4.0, 5.0] // 2,3,3,4,5秒 = 計17秒
        var currentAttempt = 0
        
        func checkShareExistenceAndURL() {
            currentAttempt += 1
            
            print("🔍 CKShare確認中（\(currentAttempt)/\(intervals.count)回目）...")
            
            // まずは保存されたCKShare自体をチェック
            if currentAttempt == 1 {
                // 1回目は直接URLをチェック
                if let url = share.url {
                    print("✅ 即座URL確認: \(url.absoluteString)")
                    completion(share)
                    return
                }
            }
            
            // サーバーから最新の状態を取得
            privateDatabase.fetch(withRecordID: share.recordID) { fetchedRecord, error in
                Task { @MainActor in
                    if let error = error {
                        let ckError = error as? CKError
                        print("⚠️ CKShare取得エラー: \(error.localizedDescription)")
                        
                        if ckError?.code == .unknownItem {
                            // Record not foundの場合、まだサーバー反映されていない
                            if currentAttempt < intervals.count {
                                let nextInterval = intervals[currentAttempt - 1]
                                print("⏳ サーバー反映待機... \(nextInterval)秒後に再試行")
                                DispatchQueue.main.asyncAfter(deadline: .now() + nextInterval) {
                                    checkShareExistenceAndURL()
                                }
                            } else {
                                print("⏰ サーバー反映タイムアウト - 元のCKShareで継続")
                                completion(share)
                            }
                            return
                        } else {
                            // その他のエラー
                            print("❌ 予期しないエラー - 元のCKShareで継続")
                            completion(share)
                            return
                        }
                    }
                    
                    // CKShareが見つかった場合
                    if let fetchedShare = fetchedRecord as? CKShare {
                        if let url = fetchedShare.url {
                            print("✅ 共有URL生成完了（\(currentAttempt)回目, \(self.calculateElapsedTime(currentAttempt, intervals))秒経過）")
                            print("   URL: \(url.absoluteString)")
                            completion(fetchedShare)
                        } else {
                            // CKShareは存在するがURLがまだ生成されていない
                            if currentAttempt < intervals.count {
                                let nextInterval = intervals[currentAttempt - 1]
                                print("⏳ URL生成待機中（CKShare存在、URL未生成）... \(nextInterval)秒後に再試行")
                                DispatchQueue.main.asyncAfter(deadline: .now() + nextInterval) {
                                    checkShareExistenceAndURL()
                                }
                            } else {
                                print("⏰ URL生成タイムアウト - CKShareは存在するがURL未生成で継続")
                                completion(fetchedShare)
                            }
                        }
                    } else {
                        // レコードは取得できたがCKShareではない（あり得ないケース）
                        print("❌ 予期しない状況: レコードはCKShareではありません")
                        completion(share)
                    }
                }
            }
        }
        
        // 最初のチェックを即座に実行
        checkShareExistenceAndURL()
    }
    
    /// 経過時間計算ヘルパー
    private func calculateElapsedTime(_ currentAttempt: Int, _ intervals: [TimeInterval]) -> Int {
        let elapsed = intervals.prefix(currentAttempt - 1).reduce(0, +)
        return Int(elapsed)
    }
    
    /// 【改良版】共有URL生成待機（拡張リトライ戦略）
    private func waitForShareURLEnhanced(share: CKShare, completion: @escaping (CKShare) -> Void) {
        print("🔄 【改良版】CKShare URL生成待機開始（ID: \(share.recordID.recordName)）")
        
        // 拡張されたリトライ戦略: 指数バックオフ + 長時間待機対応
        let intervals: [TimeInterval] = [2.0, 5.0, 10.0, 15.0, 20.0] // 2,5,10,15,20秒 = 計52秒
        var currentAttempt = 0
        
        func checkShareWithEnhancedStrategy() {
            currentAttempt += 1
            let maxAttempts = intervals.count
            
            print("🔍 【\(currentAttempt)/\(maxAttempts)】CKShare確認中... (拡張戦略)")
            
            // Step 1: 初回は即座にURLチェック
            if currentAttempt == 1 {
                if let url = share.url {
                    print("⚡ 即座URL確認成功: \(url.absoluteString)")
                    completion(share)
                    return
                }
                print("ℹ️ 初回URL未生成 - サーバー確認へ")
            }
            
            // Step 2: サーバーから最新状態を取得（拡張エラーハンドリング）
            fetchShareFromServerWithRetry(share: share, attempt: currentAttempt) { [weak self] result in
                switch result {
                case .success(let fetchedShare):
                    print("✅ CKShare取得成功")
                    
                    if let url = fetchedShare.url {
                        let totalTime = self?.calculateElapsedTime(currentAttempt, intervals) ?? 0
                        print("🎉 【URL生成成功】\(currentAttempt)回目で完了 (\(totalTime)秒経過)")
                        print("   URL: \(url.absoluteString)")
                        completion(fetchedShare)
                    } else if currentAttempt < maxAttempts {
                        // CKShareは存在するがURL未生成 - 継続
                        let nextInterval = intervals[currentAttempt - 1]
                        print("⏳ URL生成待機中... \(Int(nextInterval))秒後に再試行 (\(currentAttempt)/\(maxAttempts))")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + nextInterval) {
                            checkShareWithEnhancedStrategy()
                        }
                    } else {
                        // 最大試行回数到達 - CKShareは存在するが URL未生成で完了
                        let totalTime = self?.calculateElapsedTime(maxAttempts, intervals) ?? 0
                        print("⏰ 【URL生成タイムアウト】\(totalTime)秒経過 - CKShare存在・URL未生成で完了")
                        completion(fetchedShare)
                    }
                    
                case .failure(let error):
                    print("⚠️ CKShare取得失敗: \(error.localizedDescription)")
                    
                    if currentAttempt < maxAttempts {
                        // サーバー反映待機（指数バックオフ）
                        let nextInterval = intervals[currentAttempt - 1]
                        print("🔄 サーバー反映待機... \(Int(nextInterval))秒後に再試行")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + nextInterval) {
                            checkShareWithEnhancedStrategy()
                        }
                    } else {
                        // 最大試行回数到達 - 元のCKShareで完了
                        let totalTime = self?.calculateElapsedTime(maxAttempts, intervals) ?? 0
                        print("⏰ 【サーバー反映タイムアウト】\(totalTime)秒経過 - 元のCKShareで完了")
                        completion(share)
                    }
                }
            }
        }
        
        // 最初のチェックを即座に開始
        checkShareWithEnhancedStrategy()
    }
    
    /// CKShareのサーバー取得（リトライ対応）
    private func fetchShareFromServerWithRetry(share: CKShare, attempt: Int, completion: @escaping (Result<CKShare, Error>) -> Void) {
        privateDatabase.fetch(withRecordID: share.recordID) { fetchedRecord, error in
            Task { @MainActor in
                if let error = error {
                    let ckError = error as? CKError
                    
                    // エラー分析とロギング
                    if ckError?.code == .unknownItem {
                        print("📝 分析: Record not found (attempt \(attempt)) - サーバー反映遅延")
                    } else if ckError?.code == .networkFailure || ckError?.code == .networkUnavailable {
                        print("📝 分析: ネットワークエラー (attempt \(attempt)) - 接続問題")
                    } else {
                        print("📝 分析: その他エラー (attempt \(attempt)): \(error.localizedDescription)")
                    }
                    
                    completion(.failure(error))
                } else if let fetchedShare = fetchedRecord as? CKShare {
                    print("📝 分析: CKShare取得成功 - URL状態: \(fetchedShare.url != nil ? "生成済み" : "未生成")")
                    completion(.success(fetchedShare))
                } else {
                    // レコードは取得できたがCKShareではない
                    let unexpectedError = NSError(
                        domain: "CloudKitManager",
                        code: 999,
                        userInfo: [NSLocalizedDescriptionKey: "取得したレコードがCKShareではありません"]
                    )
                    print("❌ 予期しない状況: 取得レコードはCKShareではない")
                    completion(.failure(unexpectedError))
                }
            }
        }
    }
    
    /// レコードの共有情報を取得
    private func fetchShareForRecord(_ record: CKRecord, completion: @escaping (CKShare?) -> Void) {
        // レコードに共有参照があるかチェック
        guard let shareReference = record.share else {
            completion(nil)
            return
        }
        
        // 共有レコードを取得
        privateDatabase.fetch(withRecordID: shareReference.recordID) { shareRecord, error in
            if let error = error {
                print("共有レコード取得エラー: \(error)")
                completion(nil)
                return
            }
            
            completion(shareRecord as? CKShare)
        }
    }
    
    // MARK: - エラーハンドリング（状態管理強化版）
    
    private func handleCloudKitError(_ error: Error) {
        print("🚨 CloudKitエラー発生: \(error.localizedDescription)")
        
        if let ckError = error as? CKError {
            print("   CKError Code: \(ckError.code.rawValue)")
            
            switch ckError.code {
            case .unknownItem:
                errorMessage = "レコードが見つかりません。"
            case .notAuthenticated:
                errorMessage = "iCloudにサインインしてください。"
                // 認証状態が変更された可能性 - 再検証をトリガー
                Task {
                    await validateCloudKitConfiguration()
                }
            case .networkFailure, .networkUnavailable:
                errorMessage = "ネットワーク接続を確認してください。"
                print("📡 ネットワークエラー - 自動復旧を試行します")
                scheduleNetworkRecovery()
            case .quotaExceeded:
                errorMessage = "iCloudストレージの容量が不足しています。"
            case .permissionFailure:
                errorMessage = "CloudKitへのアクセス権限がありません。"
                // 権限状態変更の可能性 - 再検証
                Task {
                    await validateCloudKitConfiguration()
                }
            case .alreadyShared:
                errorMessage = "このアイテムは既に共有されています。"
            case .participantMayNeedVerification:
                errorMessage = "参加者の確認が必要です。"
            case .tooManyParticipants:
                errorMessage = "参加者数が上限に達しています。"
            case .serverRejectedRequest:
                errorMessage = "サーバーがリクエストを拒否しました。"
                print("🔄 サーバーエラー - CloudKit設定を再検証")
                Task {
                    await validateCloudKitConfiguration()
                }
            case .serviceUnavailable, .requestRateLimited:
                errorMessage = "CloudKitサービスが一時的に利用できません。しばらくしてから再試行してください。"
                print("⏰ サービス制限 - 遅延リトライをスケジュール")
                scheduleDelayedRetry()
            default:
                errorMessage = "エラーが発生しました: \(ckError.localizedDescription)"
                print("❓ 未知のCKError - 状況調査が必要")
            }
        } else {
            errorMessage = error.localizedDescription
            print("❗ 非CloudKitエラー: \(type(of: error))")
        }
        
        // エラー発生時のCloudKit状態を無効化（次回操作で再検証）
        if shouldInvalidateCloudKitState(for: error) {
            print("🔄 CloudKit状態を無効化 - 次回操作で再検証")
            isCloudKitAvailable = false
        }
    }
    
    /// エラーに基づいてCloudKit状態の無効化が必要か判定
    private func shouldInvalidateCloudKitState(for error: Error) -> Bool {
        guard let ckError = error as? CKError else { return false }
        
        switch ckError.code {
        case .notAuthenticated, .permissionFailure, .serverRejectedRequest:
            return true
        default:
            return false
        }
    }
    
    /// ネットワーク復旧を試行
    private func scheduleNetworkRecovery() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            print("🔄 ネットワーク復旧チェック実行")
            Task {
                await self.validateCloudKitConfiguration()
                if self.isCloudKitAvailable {
                    print("✅ ネットワーク復旧確認 - データ更新")
                    self.loadAllNotes()
                }
            }
        }
    }
    
    /// 遅延リトライをスケジュール
    private func scheduleDelayedRetry() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            print("🔄 遅延リトライ実行")
            Task {
                await self.validateCloudKitConfiguration()
            }
        }
    }
    
    /// CloudKit状態の手動リセット（デバッグ用）
    func resetCloudKitState() {
        print("🔄 CloudKit状態の手動リセット")
        isCloudKitAvailable = false
        hasValidatedCloudKit = false
        Task {
            await validateCloudKitConfiguration()
        }
    }
}