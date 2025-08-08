# CloudKitSharingKit API Reference

CloudKitSharingKitの詳細なAPI仕様書です。

## 📚 Core Protocols

### SharableRecord

CloudKit共有機能を持つレコードが実装すべきプロトコル。

```swift
public protocol SharableRecord: Identifiable {
    var id: String { get }
    var record: CKRecord? { get set }
    var shareRecord: CKShare? { get set }
    
    func toCKRecord(zoneID: CKRecordZone.ID?) -> CKRecord
    init(from record: CKRecord, shareRecord: CKShare?)
    static var recordType: String { get }
}
```

#### Properties

- **id**: レコードの一意識別子
- **record**: CloudKitレコード（存在する場合）
- **shareRecord**: 共有レコード（共有されている場合）

#### Methods

- **toCKRecord(zoneID:)**: CloudKitレコードに変換
- **init(from:shareRecord:)**: CloudKitレコードから初期化

#### Static Properties

- **recordType**: CloudKitレコードタイプ名

### SharableRecord Default Implementation

プロトコルのデフォルト実装で提供される便利なプロパティ。

```swift
public extension SharableRecord {
    var isShared: Bool { get }
    var shareURL: URL? { get }
    var sharePermission: CKShare.ParticipantPermission? { get }
    var isOwner: Bool { get }
}
```

## 🏗️ Core Classes

### CloudKitSharingManager

CloudKit共有機能を管理するメインクラス。

```swift
@MainActor
public class CloudKitSharingManager<T: SharableRecord>: ObservableObject
```

#### Initialization

```swift
public init(
    containerIdentifier: String,
    customZoneName: String = "SharingZone"
)
```

**Parameters:**
- **containerIdentifier**: CloudKitコンテナ識別子
- **customZoneName**: カスタムゾーン名（デフォルト: "SharingZone"）

#### Published Properties

```swift
@Published public var records: [T] = []
@Published public var isLoading = false
@Published public var errorMessage: String?
@Published public var isCloudKitAvailable = false
```

#### Public Properties

```swift
public let container: CKContainer
public let customZoneID: CKRecordZone.ID
```

### Configuration Methods

#### validateCloudKitConfiguration()

CloudKit設定と可用性を検証します。

```swift
public func validateCloudKitConfiguration() async
```

**使用例:**
```swift
let manager = CloudKitSharingManager<Note>(containerIdentifier: "iCloud.com.example.MyApp")
await manager.validateCloudKitConfiguration()
```

### Record Operations

#### fetchRecords()

カスタムゾーンからレコードを取得します。

```swift
public func fetchRecords() async throws
```

**Throws:** CloudKit操作エラー

**使用例:**
```swift
do {
    try await manager.fetchRecords()
    // manager.records が更新される
} catch {
    print("Fetch error: \\(error)")
}
```

#### saveRecord(_:)

レコードを保存します。

```swift
public func saveRecord(_ record: T) async throws -> T
```

**Parameters:**
- **record**: 保存するレコード

**Returns:** 保存されたレコード

**Throws:** CloudKit操作エラー

**使用例:**
```swift
let note = Note(title: "My Note", content: "Content")
do {
    let savedNote = try await manager.saveRecord(note)
    print("Saved: \\(savedNote.id)")
} catch {
    print("Save error: \\(error)")
}
```

#### deleteRecord(_:)

レコードを削除します。

```swift
public func deleteRecord(_ record: T) async throws
```

**Parameters:**
- **record**: 削除するレコード

**Throws:** CloudKit操作エラー

**使用例:**
```swift
do {
    try await manager.deleteRecord(note)
    print("Deleted successfully")
} catch {
    print("Delete error: \\(error)")
}
```

### Sharing Operations

#### startSharing(record:)

レコードの共有を開始します。

```swift
public func startSharing(record: T) async throws -> CKShare
```

**Parameters:**
- **record**: 共有するレコード

**Returns:** 作成された共有レコード

**Throws:** 
- `CloudKitSharingError.noRecord`: レコードが見つからない
- `CloudKitSharingError.alreadyShared`: 既に共有されている
- CloudKit操作エラー

**使用例:**
```swift
do {
    let share = try await manager.startSharing(record: note)
    print("Share URL: \\(share.url?.absoluteString ?? "Pending")")
} catch CloudKitSharingError.alreadyShared(let existingShare) {
    print("Already shared: \\(existingShare.url?.absoluteString ?? "No URL")")
} catch {
    print("Sharing error: \\(error)")
}
```

#### stopSharing(record:)

共有を停止します。

```swift
public func stopSharing(record: T) async throws
```

**Parameters:**
- **record**: 共有を停止するレコード

**Throws:** 
- `CloudKitSharingError.noShareRecord`: 共有レコードが見つからない
- CloudKit操作エラー

**使用例:**
```swift
do {
    try await manager.stopSharing(record: note)
    print("Sharing stopped")
} catch {
    print("Stop sharing error: \\(error)")
}
```

## 🎨 UI Components

### CloudSharingView

UICloudSharingControllerをSwiftUIで使用するためのラッパー。

```swift
public struct CloudSharingView: UIViewControllerRepresentable
```

#### Initialization

```swift
public init(
    share: CKShare,
    container: CKContainer,
    onShareSaved: (() -> Void)? = nil,
    onShareStopped: (() -> Void)? = nil
)
```

**Parameters:**
- **share**: 共有するCKShareオブジェクト
- **container**: CloudKitコンテナ
- **onShareSaved**: 共有保存時のコールバック
- **onShareStopped**: 共有停止時のコールバック

**使用例:**
```swift
.sheet(isPresented: $showingSharingView) {
    if let share = shareToPresent {
        CloudSharingView(
            share: share,
            container: manager.container,
            onShareSaved: {
                Task {
                    try? await manager.fetchRecords()
                }
            }
        )
    }
}
```

### CloudSharingView.Coordinator

UICloudSharingControllerのデリゲート実装。

```swift
@MainActor
public class Coordinator: NSObject, UICloudSharingControllerDelegate
```

#### Delegate Methods

主要なデリゲートメソッド：

- `cloudSharingController(_:failedToSaveShareWithError:)`
- `cloudSharingControllerDidSaveShare(_:)`
- `cloudSharingControllerDidStopSharing(_:)`
- `itemTitle(for:)` - 共有アイテムのタイトル
- `itemType(for:)` - 共有アイテムのタイプ

## ❌ Error Handling

### CloudKitSharingError

CloudKit共有機能固有のエラー。

```swift
public enum CloudKitSharingError: Error, LocalizedError {
    case noRecord
    case noShareRecord
    case shareNotFound
    case alreadyShared(existingShare: CKShare)
    case participantMayNeedVerification
    case tooManyParticipants
    case customZoneNotCreated
}
```

#### Error Cases

- **noRecord**: レコードが見つからない
- **noShareRecord**: 共有レコードが見つからない
- **shareNotFound**: 共有が見つからない
- **alreadyShared**: 既に共有されている（既存の共有を含む）
- **participantMayNeedVerification**: 参加者の認証が必要
- **tooManyParticipants**: 参加者数の上限に達している
- **customZoneNotCreated**: カスタムゾーンが作成されていない

### Error Handling Best Practices

```swift
do {
    let share = try await manager.startSharing(record: note)
    // 成功処理
} catch CloudKitSharingError.alreadyShared(let existingShare) {
    // 既に共有されている場合の処理
    presentExistingShare(existingShare)
} catch let ckError as CKError {
    // CloudKitエラーの処理
    switch ckError.code {
    case .notAuthenticated:
        showSignInPrompt()
    case .networkFailure:
        showNetworkError()
    default:
        showGenericError(ckError)
    }
} catch {
    // その他のエラー
    showGenericError(error)
}
```

## 📊 Information Classes

### CloudKitSharingKitInfo

ライブラリの情報を提供する静的クラス。

```swift
public struct CloudKitSharingKitInfo {
    public static let version: String
    public static let minimumIOSVersion: String
    public static let author: String
    public static let license: String
    public static let repositoryURL: String
}
```

## 🔧 Integration Patterns

### ViewModel Pattern

```swift
@MainActor
class MyViewModel: ObservableObject {
    private let sharingManager: CloudKitSharingManager<MyRecord>
    @Published var records: [MyRecord] = []
    
    init() {
        sharingManager = CloudKitSharingManager<MyRecord>(
            containerIdentifier: "iCloud.com.example.MyApp"
        )
    }
    
    func loadData() async {
        do {
            try await sharingManager.fetchRecords()
            records = sharingManager.records
        } catch {
            // Handle error
        }
    }
}
```

### Environment Object Pattern

```swift
@main
struct MyApp: App {
    @StateObject private var sharingManager = CloudKitSharingManager<MyRecord>(
        containerIdentifier: "iCloud.com.example.MyApp"
    )
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharingManager)
        }
    }
}
```

## ⚡ Performance Considerations

### Batching Operations

```swift
// 複数レコードの効率的な保存
for record in records {
    do {
        _ = try await manager.saveRecord(record)
    } catch {
        // 個別のエラーハンドリング
    }
}

// 最後に一括取得
try await manager.fetchRecords()
```

### Memory Management

- `CloudKitSharingManager` は `@StateObject` または `@ObservedObject` として使用
- 大量のレコードを扱う場合は適切なページング実装を検討
- 不要になったレコードは適切にクリーンアップ

## 🔒 Security Considerations

### Data Privacy

- 共有されたレコードは他のユーザーからアクセス可能
- 機密情報は共有レコードに含めないよう注意
- ユーザーの同意なしに共有を開始しない

### Permission Management

```swift
// 現在のユーザーの権限確認
if record.isOwner {
    // オーナーのみの操作
} else {
    // 参加者の操作
}

// 読み書き権限の確認
switch record.sharePermission {
case .readWrite:
    // 編集可能
case .readOnly:
    // 読み取り専用
case .none:
    // 権限なしまたは未共有
}
```