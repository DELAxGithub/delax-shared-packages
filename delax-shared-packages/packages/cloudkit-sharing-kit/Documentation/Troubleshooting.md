# CloudKitSharingKit トラブルシューティング

CloudKitSharingKitの使用時に発生する可能性のある問題と解決方法を説明します。

## 🚨 よくある問題と解決方法

### 1. 共有機能が動作しない

#### 症状
- 共有ボタンをタップしてもUICloudSharingControllerが表示されない
- 「Record not found」エラーが発生する

#### 原因と解決方法

**原因1: レコードタイプでSharedが有効化されていない**

```bash
# 解決方法: CloudKit Dashboardで設定確認
```

1. [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard) にアクセス
2. 対象のコンテナを選択
3. Schema > Record Types から該当のレコードタイプを選択
4. Metadata セクションで「Shared」にチェックが入っているか確認
5. チェックが入っていない場合は有効化
6. 「Save」→「Deploy Schema Changes」をクリック

**原因2: カスタムゾーンが作成されていない**

```swift
// 解決方法: マネージャーの初期化を確認
let manager = CloudKitSharingManager<Note>(
    containerIdentifier: "iCloud.com.yourteam.YourApp",
    customZoneName: "NotesZone" // カスタムゾーン名を指定
)

// 初期化後に検証実行
await manager.validateCloudKitConfiguration()
```

**原因3: シミュレーターで実行している**

```swift
// 解決方法: 実機でテスト
#if targetEnvironment(simulator)
print("⚠️ CloudKit sharing does not work in simulator")
print("Please test on a physical device")
#endif
```

### 2. 認証エラー

#### 症状
- "Not authenticated" エラー
- "Please sign in to iCloud" メッセージ

#### 解決方法

```swift
// デバッグ用: アカウント状態を確認
func checkAccountStatus() async {
    do {
        let status = try await manager.container.accountStatus()
        switch status {
        case .available:
            print("✅ iCloud account is available")
        case .noAccount:
            print("❌ No iCloud account configured")
        case .restricted:
            print("❌ iCloud account is restricted")
        case .couldNotDetermine:
            print("❌ Could not determine account status")
        case .temporarilyUnavailable:
            print("⏳ iCloud account temporarily unavailable")
        @unknown default:
            print("❓ Unknown account status")
        }
    } catch {
        print("Account status check failed: \\(error)")
    }
}
```

**手動での解決手順:**
1. 設定 > [ユーザー名] > iCloud でサインイン状態を確認
2. iCloud Drive が有効になっているか確認
3. 対象アプリのiCloud設定が有効になっているか確認

### 3. ネットワークエラー

#### 症状
- "Network failure" エラー
- 断続的な同期の失敗

#### 解決方法

```swift
func handleNetworkError(_ error: CKError) {
    switch error.code {
    case .networkFailure:
        // 再試行ロジックの実装
        scheduleRetry()
    case .networkUnavailable:
        // オフライン状態の通知
        showOfflineMessage()
    case .requestRateLimited:
        // レート制限の処理
        scheduleRetryAfterDelay()
    default:
        break
    }
}

private func scheduleRetry() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        Task {
            try? await self.manager.fetchRecords()
        }
    }
}
```

### 4. 共有URLが生成されない

#### 症状
- `share.url` が `nil`
- 共有リンクを取得できない

#### 原因と解決方法

**原因: 共有作成直後はURLが未生成**

```swift
func waitForShareURL(_ share: CKShare, maxRetries: Int = 5) async -> URL? {
    for attempt in 1...maxRetries {
        if let url = share.url {
            return url
        }
        
        print("Waiting for share URL... (attempt \\(attempt)/\\(maxRetries))")
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
        
        // 共有レコードを再取得
        do {
            try await manager.fetchRecords()
            if let updatedShare = manager.records.first(where: { $0.id == share.recordID.recordName })?.shareRecord {
                if let url = updatedShare.url {
                    return url
                }
            }
        } catch {
            print("Failed to refresh records: \\(error)")
        }
    }
    
    return nil
}
```

### 5. 権限エラー

#### 症状
- "Permission failure" エラー
- CloudKitコンテナにアクセスできない

#### 解決方法

```swift
// Entitlementsファイルの確認
```

`YourApp.entitlements` ファイルが正しく設定されているか確認:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.yourteam.YourApp</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
</dict>
</plist>
```

### 6. ストレージ容量エラー

#### 症状
- "Quota exceeded" エラー
- データの保存に失敗

#### 解決方法

```swift
func handleQuotaExceeded() {
    // ユーザーに容量不足を通知
    let alert = UIAlertController(
        title: "iCloud Storage Full",
        message: "Your iCloud storage is full. Please free up space or upgrade your storage plan.",
        preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    })
    
    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
    
    // 適切なViewControllerから表示
    present(alert, animated: true)
}
```

## 🛠️ デバッグツール

### 1. CloudKit Console

CloudKit Dashboardの「Logs」セクションでリアルタイムでログを確認:

```bash
# cktoolでのログ確認
xcrun cktool logs --team-id YOUR_TEAM_ID --container-id YOUR_CONTAINER_ID
```

### 2. 詳細ログ出力の有効化

```swift
// デバッグビルドでの詳細ログ
extension CloudKitSharingManager {
    private func enableDetailedLogging() {
        #if DEBUG
        // CloudKitの詳細ログを有効化
        UserDefaults.standard.set(true, forKey: "CKDebugLogging")
        UserDefaults.standard.set(true, forKey: "CKSQLiteDebugLogging")
        #endif
    }
}
```

### 3. 設定検証スクリプト

```bash
#!/bin/bash
# validate_cloudkit_setup.sh

echo "🔍 CloudKit Setup Validation"
echo "============================"

# Team IDとContainer IDを設定
TEAM_ID="YOUR_TEAM_ID"
CONTAINER_ID="iCloud.com.yourteam.YourApp"
ENVIRONMENT="development"

echo "📋 Configuration:"
echo "  Team ID: $TEAM_ID"
echo "  Container ID: $CONTAINER_ID"
echo "  Environment: $ENVIRONMENT"
echo ""

# スキーマの確認
echo "🔍 Checking schema..."
schema_result=$(xcrun cktool export-schema --team-id "$TEAM_ID" --container-id "$CONTAINER_ID" --environment "$ENVIRONMENT" 2>&1)

if [[ $? -eq 0 ]]; then
    echo "✅ Schema accessible"
    
    # レコードタイプの確認
    if [[ $schema_result == *"Note"* ]]; then
        echo "✅ Note record type exists"
        
        if [[ $schema_result == *"isShareable"* ]]; then
            echo "✅ Sharing is enabled"
        else
            echo "❌ Sharing is NOT enabled"
        fi
    else
        echo "❌ Note record type not found"
    fi
else
    echo "❌ Cannot access schema"
    echo "Error: $schema_result"
fi
```

## 🔍 パフォーマンス問題

### 1. 遅い同期

#### 症状
- レコードの取得に時間がかかる
- アプリの起動が遅い

#### 解決方法

```swift
// バックグラウンドでの初期化
class AppDelegate: UIResponder, UIApplicationDelegate {
    func applicationDidFinishLaunching(_ application: UIApplication) {
        // CloudKitの初期化をバックグラウンドで実行
        Task.detached(priority: .background) {
            await CloudKitSharingManager.shared.validateCloudKitConfiguration()
        }
    }
}

// 段階的なデータ読み込み
func loadDataInStages() async {
    // 1. キャッシュされたデータを先に表示
    loadCachedData()
    
    // 2. CloudKitから最新データを取得
    do {
        try await manager.fetchRecords()
    } catch {
        // エラー処理
    }
}
```

### 2. メモリ使用量の増加

#### 解決方法

```swift
// 大量データ処理時のメモリ管理
func processLargeDataSet() async {
    autoreleasepool {
        // CloudKitデータの処理
    }
}

// 不要なキャッシュのクリア
func clearCache() {
    manager.records.removeAll()
    // その他のキャッシュクリア処理
}
```

## 📱 プラットフォーム固有の問題

### macOS での問題

```swift
#if os(macOS)
// macOSでは一部の機能が制限される場合
func showSharingOnMac() {
    // NSSharingServicePicker の使用を検討
    let sharingPicker = NSSharingServicePicker(items: [shareURL])
    sharingPicker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
}
#endif
```

### watchOS での制限

```swift
#if os(watchOS)
// watchOSでは共有UIが制限される
func showSharingOnWatch() {
    // 代替手段: 共有URLをクリップボードにコピー
    UIPasteboard.general.url = shareURL
    
    // または、iPhone側アプリに通知
    WCSession.default.sendMessage(["action": "share", "url": shareURL.absoluteString]) { _ in
        // 成功処理
    } errorHandler: { error in
        // エラー処理
    }
}
#endif
```

## 🆘 緊急時の対処法

### 1. 完全リセット

```swift
// アプリの CloudKit データを完全リセット
func performCompleteReset() async {
    do {
        // 1. 全てのローカル共有を停止
        for record in manager.records where record.isShared {
            try? await manager.stopSharing(record: record)
        }
        
        // 2. 全てのレコードを削除
        for record in manager.records {
            try? await manager.deleteRecord(record)
        }
        
        // 3. キャッシュクリア
        manager.records.removeAll()
        
        print("✅ Complete reset successful")
    } catch {
        print("❌ Reset failed: \\(error)")
    }
}
```

### 2. データ復旧

```swift
// CloudKit Dashboard からのデータエクスポート
func exportDataForBackup() {
    // cktool を使用してデータをエクスポート
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = [
        "cktool", "export-data",
        "--team-id", "YOUR_TEAM_ID",
        "--container-id", "YOUR_CONTAINER_ID",
        "--environment", "development",
        "--output-file", "backup.json"
    ]
    
    do {
        try process.run()
        print("✅ Data exported to backup.json")
    } catch {
        print("❌ Export failed: \\(error)")
    }
}
```

## 📞 サポートとコミュニティ

### 1. 問題報告時の情報収集

```swift
func generateDiagnosticInfo() -> String {
    var info = "CloudKitSharingKit Diagnostic Info\\n"
    info += "=====================================\\n"
    info += "Version: \\(CloudKitSharingKitInfo.version)\\n"
    info += "iOS Version: \\(UIDevice.current.systemVersion)\\n"
    info += "Device: \\(UIDevice.current.model)\\n"
    info += "Container: \\(manager.container.containerIdentifier ?? "Unknown")\\n"
    info += "Records Count: \\(manager.records.count)\\n"
    info += "CloudKit Available: \\(manager.isCloudKitAvailable)\\n"
    
    if let errorMessage = manager.errorMessage {
        info += "Last Error: \\(errorMessage)\\n"
    }
    
    return info
}
```

### 2. コミュニティリソース

- **GitHub Issues**: バグ報告と機能リクエスト
- **Stack Overflow**: `cloudkit-sharing-kit` タグ
- **Apple Developer Forums**: CloudKit関連の問題

### 3. 追加リソース

- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [CloudKit Best Practices](https://developer.apple.com/videos/play/wwdc2021/10086/)
- [CloudKit Sharing and Collaboration](https://developer.apple.com/videos/play/wwdc2021/10015/)

問題が解決しない場合は、診断情報と詳細な問題の説明を含めてIssueを作成してください。