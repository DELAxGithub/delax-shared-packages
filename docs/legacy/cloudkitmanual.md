# CloudKit開発環境構築マニュアル

このマニュアルは、CloudKitStarterアプリの開発環境を新規に構築する、または既存のプロジェクトにCloudKit機能を統合する際の完全ガイドです。

## プロジェクト情報

### 基本設定
- **Bundle Identifier**: `Delax.CloudKitStarter`
- **Container Identifier**: `iCloud.Delax.CloudKitStarter`
- **Team ID**: `Z88477N5ZU`
- **開発者**: HIROSHI KODERA
- **最小iOS**: iOS 15.0+

### 必要な環境
- Xcode 14.0以降
- macOS 12.0以降
- Apple Developer アカウント（CloudKit Dashboard アクセス用）
- cktool（Xcodeに付属）

## CloudKitスキーマ定義

### Noteレコードタイプ（最新版）

```
RECORD TYPE Note (
    title           STRING QUERYABLE SORTABLE,
    content         STRING QUERYABLE,
    createdAt       TIMESTAMP QUERYABLE SORTABLE,
    modifiedAt      TIMESTAMP QUERYABLE SORTABLE,
    isFavorite      INT64 QUERYABLE,
    GRANT WRITE TO "_creator",
    GRANT CREATE TO "_icloud",
    GRANT READ TO "_world"
);
```

### フィールド詳細

| フィールド名 | 型 | Queryable | Sortable | 説明 |
|-------------|---|-----------|----------|------|
| title | STRING | ✓ | ✓ | ノートのタイトル |
| content | STRING | ✓ | - | ノートの内容（複数行対応） |
| createdAt | TIMESTAMP | ✓ | ✓ | 作成日時 |
| modifiedAt | TIMESTAMP | ✓ | ✓ | 更新日時 |
| isFavorite | INT64 | ✓ | - | お気に入りフラグ（0/1） |

**重要**: CloudKitではBOOL型が存在しないため、isFavoriteはINT64型として実装しています。

## Xcodeプロジェクト設定

### 1. CloudKit機能の有効化

1. Xcodeでプロジェクトを開く
2. プロジェクトナビゲータでプロジェクトを選択
3. ターゲットを選択
4. 「Signing & Capabilities」タブを開く
5. 「+ Capability」をクリック
6. 「CloudKit」を追加

### 2. エンタイトルメントファイル

`CloudKitStarter.entitlements`ファイルに以下の内容が必要：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.aps-environment</key>
    <string>development</string>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.Delax.CloudKitStarter</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
</dict>
</plist>
```

## CloudKit Dashboard設定

### 手動設定手順

1. [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)にアクセス
2. Apple Developer アカウントでサインイン
3. コンテナ「iCloud.Delax.CloudKitStarter」を選択
4. 左メニューから「Schema」→「Record Types」を選択
5. 「+」ボタンで新規レコードタイプ「Note」を作成
6. 各フィールドを追加（上記のフィールド詳細を参照）
7. 各フィールドの「Indexes」タブで必要な属性を有効化
8. 「Save」をクリック

## cktoolによる自動設定

### 1. Management Token取得

```bash
# CloudKit Dashboardで取得
# Settings → Tokens → Generate Management Token
# 必要な権限: Schema Read/Write
```

### 2. User Token取得

```bash
xcrun cktool save-token --type user
# ブラウザが開くのでApple IDでサインイン
```

### 3. スキーマインポート

```bash
# Management Tokenを保存
xcrun cktool save-token "YOUR_MANAGEMENT_TOKEN" --type management --method file --force

# スキーマをインポート
xcrun cktool import-schema \
  --team-id "Z88477N5ZU" \
  --container-id "iCloud.Delax.CloudKitStarter" \
  --environment "development" \
  --file "update_note_schema_favorite.ckdb"
```

## 実装上の重要ポイント

### 1. recordNameエラーの回避

CloudKitの「Field 'recordName' is not marked queryable」エラーを回避するため、CloudKitManagerAlternativeを使用：

```swift
// CKQueryを使用しない実装
// レコードIDをUserDefaultsに保存
// fetch(withRecordIDs:)で個別取得
```

### 2. Bool型の扱い

CloudKitにはBool型がないため、INT64として保存：

```swift
// 保存時
record["isFavorite"] = isFavorite ? 1 : 0

// 読み込み時
if let favoriteValue = record["isFavorite"] as? Int64 {
    self.isFavorite = favoriteValue != 0
}
```

### 3. プラットフォーム分岐

iOS/macOSで異なるAPIを使用：

```swift
#if os(macOS)
// macOS専用コード（Process等）
#else
// iOS用コード
#endif
```

## 既存プロジェクトへの統合

### 必要なファイル

1. **Models/**
   - `Note.swift`

2. **Services/**
   - `CloudKitManagerAlternative.swift`（推奨）
   - `CloudKitManager.swift`（参考実装）
   - `CloudKitSchemaManager.swift`（macOS用）

3. **Views/**
   - `NoteListViewAlternative.swift`
   - `CreateNoteViewAlternative.swift`
   - `EditNoteViewAlternative.swift`

### 統合手順

1. 上記ファイルをプロジェクトにコピー
2. CloudKit機能を有効化
3. エンタイトルメントを設定
4. CloudKit Dashboardでスキーマを設定
5. ContentViewで`NoteListViewAlternative`を表示

```swift
struct ContentView: View {
    var body: some View {
        NoteListViewAlternative()
    }
}
```

## トラブルシューティング

### よくある問題

1. **"Field 'recordName' is not marked queryable"エラー**
   - 解決策: CloudKitManagerAlternativeを使用
   - CKQueryを避けて個別レコード取得を実装

2. **iCloudサインインエラー**
   - シミュレータでiCloudにサインイン
   - 設定 → Apple ID → iCloudを確認

3. **スキーマが反映されない**
   - CloudKit Dashboardで手動保存
   - Development環境で作業していることを確認

4. **Management Token認証エラー**
   - トークンの有効期限を確認
   - 必要な権限（Schema Read/Write）を確認

### デバッグ方法

```bash
# スキーマエクスポートで現在の設定確認
xcrun cktool export-schema \
  --team-id "Z88477N5ZU" \
  --container-id "iCloud.Delax.CloudKitStarter" \
  --environment "development"

# レコード一覧取得（User Token必要）
xcrun cktool query-records \
  --team-id "Z88477N5ZU" \
  --container-id "iCloud.Delax.CloudKitStarter" \
  --database-type "private" \
  --zone-name "_defaultZone" \
  --record-type "Note"
```

## 開発のベストプラクティス

1. **エラーハンドリング**
   - CloudKitエラーを適切にキャッチ
   - ユーザーにわかりやすいメッセージを表示

2. **非同期処理**
   - @MainActorやDispatchQueue.mainを適切に使用
   - ローディング状態を表示

3. **データ同期**
   - オフライン対応を考慮
   - 楽観的更新の実装

4. **セキュリティ**
   - Management Tokenは環境変数で管理
   - .gitignoreに機密情報を追加

## 参考リンク

- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
- [cktool Documentation](https://developer.apple.com/documentation/cloudkit/cktool)
- [GitHub Repository](https://github.com/DELAxGithub/delaxcloudkit)

---

このマニュアルに従って設定すれば、CloudKitStarterと同じ開発環境を構築できます。問題が発生した場合は、トラブルシューティングセクションを参照してください。