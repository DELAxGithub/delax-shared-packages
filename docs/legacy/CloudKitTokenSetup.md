# CloudKit Management Token設定ガイド

## エラー: "Session has expired or is invalid"

このエラーは、Management Tokenが無効または期限切れの場合に発生します。

## 新しいManagement Tokenの取得手順

### 1. CloudKit Dashboardにアクセス
```bash
open https://icloud.developer.apple.com/dashboard
```

### 2. コンテナの選択
- 「Delax.CloudKitStarter」コンテナを選択
- もし表示されない場合は、Xcodeでプロジェクトを一度ビルドしてください

### 3. Management Tokenの生成
1. 左側メニューから「Settings」を選択
2. 「API Tokens」セクションを開く
3. 「Management Tokens」の「+」ボタンをクリック
4. トークン名を入力（例: "Schema Setup Token"）
5. 「Generate」をクリック
6. **生成されたトークンをコピー**（この画面を離れると二度と表示されません）

### 4. トークンの権限確認
生成されたトークンには以下の権限が必要です：
- Schema Management (Read/Write)
- Record Type Management
- Index Management

### 5. トークンの使用
```bash
# 環境変数として設定
export CLOUDKIT_MANAGEMENT_TOKEN="your-new-token-here"

# スクリプトを実行
./setup_cloudkit.sh
```

## トラブルシューティング

### トークンが機能しない場合
1. **コンテナIDの確認**
   - Bundle ID: `Delax.CloudKitStarter`
   - Container ID: `iCloud.Delax.CloudKitStarter`

2. **Team IDの確認**
   - Team ID: `Z88477N5ZU`
   - Apple Developer Centerで確認可能

3. **トークンの有効期限**
   - Management Tokenには有効期限があります
   - 期限切れの場合は新しいトークンを生成

4. **権限の確認**
   - トークン生成時に適切な権限が付与されているか確認
   - Schema管理権限が必要

## セキュリティ注意事項

1. **トークンの保管**
   - トークンは機密情報です
   - 安全な場所に保管してください
   - Gitにコミットしないでください

2. **トークンの共有**
   - トークンを他人と共有しないでください
   - 必要最小限の権限で生成してください

3. **トークンの無効化**
   - 使用後は必要に応じてトークンを無効化
   - CloudKit Dashboard > Settings > API Tokensから削除可能

## 代替手段

自動設定がうまくいかない場合は、CloudKit Dashboardで手動設定も可能です：
1. Schema > Record Types > 「+」
2. 「Memo」レコードタイプを作成
3. フィールドを追加（title, content, createdAt）
4. 各フィールドのQueryableとSortableを有効化
5. Saveをクリック