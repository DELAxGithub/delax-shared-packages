import Foundation
import CloudKit
import SwiftUI

class CloudKitManager: ObservableObject {
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSetupGuide = false
    
    init() {
        container = CKContainer(identifier: "iCloud.Delax.CloudKitStarter")
        privateDatabase = container.privateCloudDatabase
    }
    
    func fetchNotes() {
        isLoading = true
        errorMessage = nil
        
        // 最もシンプルなクエリ
        let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
        
        let operation = CKQueryOperation(query: query)
        var fetchedRecords: [CKRecord] = []
        
        operation.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                fetchedRecords.append(record)
            case .failure:
                break
            }
        }
        
        operation.queryResultBlock = { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success:
                    // CKRecordをNoteに変換
                    self?.notes = fetchedRecords.compactMap { Note(from: $0) }
                case .failure(let error):
                    self?.handleCloudKitError(error)
                }
            }
        }
        
        privateDatabase.add(operation)
    }
    
    private func handleCloudKitError(_ error: Error) {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .unknownItem:
                errorMessage = "CloudKitのレコードタイプが設定されていません。\nCloudKit Dashboardで「Note」レコードタイプを作成してください。"
                showSetupGuide = true
            case .notAuthenticated:
                errorMessage = "iCloudにサインインしてください。\n設定アプリ > [あなたの名前] > iCloudでサインインを確認してください。"
            case .networkFailure, .networkUnavailable:
                errorMessage = "ネットワーク接続を確認してください。"
            case .quotaExceeded:
                errorMessage = "iCloudストレージの容量が不足しています。"
            case .permissionFailure:
                errorMessage = "CloudKitへのアクセス権限がありません。"
            default:
                errorMessage = "エラーが発生しました: \(ckError.localizedDescription)"
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
    
    func saveNote(_ note: Note, completion: @escaping (Result<Note, Error>) -> Void) {
        let record = note.toCKRecord()
        
        privateDatabase.save(record) { [weak self] savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleCloudKitError(error)
                    completion(.failure(error))
                    return
                }
                
                if let savedRecord = savedRecord {
                    let savedNote = Note(from: savedRecord)
                    completion(.success(savedNote))
                }
            }
        }
    }
    
    func deleteNote(_ note: Note, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let record = note.record else {
            completion(.failure(NSError(domain: "CloudKitManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No record found"])))
            return
        }
        
        privateDatabase.delete(withRecordID: record.recordID) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
}