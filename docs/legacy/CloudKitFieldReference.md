# CloudKit フィールド名リファレンス

## システムフィールド（自動的に管理される）

CloudKitには、システムが自動的に管理する特別なフィールドがあります。これらは直接クエリできない場合があります。

### 使用可能なシステムフィールド
- `recordID` - レコードの一意識別子
- `recordType` - レコードタイプ名
- `creationDate` - レコード作成日時（クエリ可能）
- `modificationDate` - レコード更新日時（クエリ可能）
- `creatorUserRecordID` - レコード作成者
- `modifiedByUserRecordID` - 最終更新者

### 注意事項
- `recordName`は`recordID`の一部であり、直接クエリすることはできません
- ソート用のフィールドは、CloudKit Dashboardで「Sortable」に設定する必要があります

## カスタムフィールド（今回のアプリ）

### Memoレコードタイプ
- `title` (String) - タイトル
- `content` (String) - 内容
- `createdAt` (Date/Time) - 作成日時（カスタムフィールド）

## ソートの実装

### 正しい実装
```swift
// カスタムフィールドでソート
query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

// システムフィールドでソート（CloudKitが自動管理）
query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
```

### 間違った実装
```swift
// recordNameは直接クエリできない
query.sortDescriptors = [NSSortDescriptor(key: "recordName", ascending: false)]

// フィールド名の間違い
query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
```

## トラブルシューティング

### "Field 'xxx' is not marked queryable"エラー
- CloudKit Dashboardでフィールドの「Queryable」を有効にする
- システムフィールド名を正しく使用しているか確認

### "Field 'xxx' is not marked sortable"エラー
- CloudKit Dashboardでフィールドの「Sortable」を有効にする
- ソート可能なフィールドを使用しているか確認