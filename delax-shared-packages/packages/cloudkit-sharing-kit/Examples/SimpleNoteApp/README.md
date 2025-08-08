# Simple Note App - CloudKitSharingKit Example

CloudKitSharingKitを使用したシンプルなノートアプリのサンプル実装です。

## 📋 機能

- ✅ ノートの作成・編集・削除
- ✅ CloudKit同期
- ✅ ノート共有機能
- ✅ シンプルなSwiftUI UI

## 🚀 セットアップ

### 1. 前提条件

- Xcode 15.0以降
- iOS 15.0以降のデプロイメントターゲット
- Apple Developer Program登録済み

### 2. プロジェクト作成

1. Xcodeで新しいiOSプロジェクトを作成
2. プロジェクト名: "SimpleNoteApp"
3. Interface: SwiftUI
4. Language: Swift

### 3. CloudKitSharingKit の追加

1. File > Add Package Dependencies
2. URL: `https://github.com/example/CloudKitSharingKit`
3. Add Package

### 4. CloudKit設定

1. Signing & Capabilities > + Capability > CloudKit
2. Container: 新しいコンテナを作成または既存を選択

### 5. CloudKit Dashboard設定

1. [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard) にアクセス
2. コンテナを選択
3. Schema > Record Types > + で "Note" レコードタイプを作成

#### Noteレコードタイプの設定

| フィールド名 | タイプ | インデックス可能 | 必須 |
|-------------|--------|----------------|------|
| title | String | ✅ | ✅ |
| content | String | ❌ | ❌ |
| createdAt | Date/Time | ✅ | ❌ |
| modifiedAt | Date/Time | ✅ | ❌ |

⚠️ **重要**: Metadata セクションで "Shared" を有効化してください。

### 6. コードのコピー

以下のファイルをXcodeプロジェクトにコピーしてください：

- `Note.swift` - データモデル
- `ContentView.swift` - メインビュー
- `NoteDetailView.swift` - ノート詳細ビュー
- `SimpleNoteApp.swift` - アプリエントリーポイント

## 📱 使用方法

1. アプリを起動
2. "Add Note" ボタンでノート作成
3. ノート一覧で共有ボタン（👥）をタップ
4. UICloudSharingControllerで共有設定

## 🔧 カスタマイズ

Container IDの変更：
```swift
// SimpleNoteApp.swift
@StateObject private var sharingManager = CloudKitSharingManager<Note>(
    containerIdentifier: "iCloud.com.yourteam.YourApp" // ここを変更
)
```

## 📝 注意点

- CloudKit共有機能は実機でのみ動作します（シミュレーターでは不可）
- iCloudにサインインしている必要があります
- 初回起動時はCloudKitの初期化に時間がかかる場合があります

## 🐛 トラブルシューティング

### "Record not found" エラー
- CloudKit DashboardでRecord Typeの Shared が有効化されているか確認

### "Not authenticated" エラー
- デバイスの設定 > iCloud でサインインを確認

### 共有ボタンが動作しない
- 実機でテストしているか確認
- ネットワーク接続を確認