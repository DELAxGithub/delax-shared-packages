//
//  CloudSharingView.swift
//  CloudKitStarter
//
//  Created by Claude Code on 2025-08-07.
//

import SwiftUI
import CloudKit

struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    var onShareSaved: (() -> Void)?
    var onShareStopped: (() -> Void)?
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        print("🔧 UICloudSharingController を初期化")
        print("   Share ID: \(share.recordID.recordName)")
        print("   Share URL: \(share.url?.absoluteString ?? "なし")")
        print("   Container ID: \(container.containerIdentifier ?? "なし")")
        print("   現在の参加者数: \(share.participants.count)")
        
        // 参加者の詳細情報を出力
        for (index, participant) in share.participants.enumerated() {
            print("   参加者\(index + 1): \(participant.userIdentity.userRecordID?.recordName ?? "不明")")
            print("     権限: \(participant.permission == .readWrite ? "読み書き" : "読み取り専用")")
            print("     承認状態: \(participantAcceptanceStatus(participant.acceptanceStatus))")
            print("     役割: \(participantRole(participant.role))")
        }
        
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowReadWrite]
        controller.modalPresentationStyle = .formSheet
        
        print("✅ UICloudSharingController 初期化完了")
        return controller
    }
    
    private func participantAcceptanceStatus(_ status: CKShare.ParticipantAcceptanceStatus) -> String {
        switch status {
        case .unknown: return "不明"
        case .pending: return "招待待ち"
        case .accepted: return "承認済み"
        case .removed: return "削除済み"
        @unknown default: return "未対応状態"
        }
    }
    
    private func participantRole(_ role: CKShare.ParticipantRole) -> String {
        switch role {
        case .owner: return "オーナー"
        case .privateUser: return "プライベートユーザー"
        case .publicUser: return "パブリックユーザー"
        case .unknown: return "不明"
        @unknown default: return "未対応タイプ"
        }
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
        // 更新処理は特に必要なし
    }
    
    @MainActor
    func makeCoordinator() -> Coordinator {
        Coordinator(
            onShareSaved: onShareSaved,
            onShareStopped: onShareStopped
        )
    }
    
    @MainActor
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        private let onShareSaved: (() -> Void)?
        private let onShareStopped: (() -> Void)?
        
        init(onShareSaved: (() -> Void)? = nil, onShareStopped: (() -> Void)? = nil) {
            self.onShareSaved = onShareSaved
            self.onShareStopped = onShareStopped
        }
        
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("❌ UICloudSharingController: 共有保存エラー")
            print("   エラー: \(error.localizedDescription)")
            if let ckError = error as? CKError {
                print("   CKError Code: \(ckError.code.rawValue)")
                print("   CKError Description: \(ckError.localizedDescription)")
            }
        }
        
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("✅ UICloudSharingController: 共有を保存しました")
            if let share = csc.share {
                print("   参加者数: \(share.participants.count)")
                print("   共有URL: \(share.url?.absoluteString ?? "URLなし")")
                
                // 新しく追加された参加者をチェック
                let pendingParticipants = share.participants.filter { $0.acceptanceStatus == .pending }
                let acceptedParticipants = share.participants.filter { $0.acceptanceStatus == .accepted }
                
                print("   招待待ち: \(pendingParticipants.count)人")
                print("   承認済み: \(acceptedParticipants.count)人")
                
                if pendingParticipants.count > 0 {
                    print("📧 招待を送信しました:")
                    for participant in pendingParticipants {
                        print("   → \(participant.userIdentity.userRecordID?.recordName ?? "不明なユーザー")")
                    }
                } else if acceptedParticipants.count == 1 {
                    print("🔍 共有レコードが作成されました（招待送信前の状態）")
                    print("💡 UICloudSharingControllerで連絡先を選択して実際の招待を送信してください")
                }
                
                // 共有URL確認のためのPoC情報
                if let url = share.url {
                    print("🎯 PoC検証: この共有URLを別のApple IDデバイスでテストできます")
                    print("   共有URL: \(url.absoluteString)")
                } else {
                    print("⏳ 共有URL生成中... しばらく待ってから「PoC情報」ボタンで確認してください")
                }
            }
            onShareSaved?()
        }
        
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            print("⏹️ UICloudSharingController: 共有を停止しました")
            onShareStopped?()
        }
        
        func itemTitle(for csc: UICloudSharingController) -> String? {
            return "共有ノート"
        }
        
        func itemType(for csc: UICloudSharingController) -> String? {
            return "Note"
        }
        
        func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
            // サムネイル画像のデータを返す（オプション）
            return nil
        }
        
        // MARK: - PoC検証用のadditional methods  
        func cloudSharingController(_ csc: UICloudSharingController, didPrepareShareMetadata metadata: CKShare.Metadata) {
            print("🔍 PoC: Share Metadata準備完了")
            print("   Metadataオブジェクト: \(metadata)")
            // iOS 18.5でのMetadata構造変更に対応
        }
        
        func cloudSharingController(_ csc: UICloudSharingController, didUpdateShare share: CKShare) {
            print("🔄 PoC: Share更新イベント")
            print("   更新後参加者数: \(share.participants.count)")
            print("   URL: \(share.url?.absoluteString ?? "URLなし")")
            
            // Apple IDユーザーの詳細確認
            for participant in share.participants {
                print("   参加者詳細:")
                print("     ID: \(participant.userIdentity.userRecordID?.recordName ?? "不明")")
                print("     承認状態: \(participant.acceptanceStatus.rawValue)")
                print("     権限: \(participant.permission.rawValue)")
            }
        }
    }
}

