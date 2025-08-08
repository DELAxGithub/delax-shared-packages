# CloudKit Management Token トラブルシューティング

## 問題: "Session has expired or is invalid"

cktoolでManagement Tokenを使用しても認証エラーが発生する場合の対処法。

## 確認事項

### 1. トークン生成時の設定
CloudKit Dashboardでトークンを生成する際に、以下を確認してください：

1. **正しいコンテナを選択しているか**
   - CloudKit Dashboardで「Delax.CloudKitStarter」コンテナを選択
   - コンテナが存在しない場合は、Xcodeでプロジェクトをビルドして自動作成

2. **トークンタイプ**
   - 「Management Token」を選択（User Tokenではない）
   - Management APIアクセス権限が有効

3. **権限設定**
   - Schema Read/Write権限
   - Record Type Management権限
   - Container Management権限

### 2. Team IDの確認
```bash
# Apple Developer Centerで確認
open https://developer.apple.com/account
```
- Membership > Team ID を確認
- 現在の設定: Z88477N5ZU

### 3. Container IDの形式
- 正しい形式: `iCloud.Delax.CloudKitStarter`
- Bundle IDの前に「iCloud.」を付ける

## 代替方法

### 方法1: CloudKit Dashboardで手動設定
最も確実な方法は、CloudKit Dashboardで直接設定することです：

1. [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)にアクセス
2. 「Delax.CloudKitStarter」コンテナを選択
3. Schema > Record Types > 「+」
4. Record Type: 「Memo」
5. フィールドを追加：
   - title (String) - Queryable ✓, Sortable ✓
   - content (String) - Queryable ✓
   - createdAt (Date/Time) - Queryable ✓, Sortable ✓
6. 「Save」をクリック

### 方法2: Xcode Cloud経由での設定
Xcode Cloudを使用している場合は、CI/CDパイプラインでスキーマを設定できます。

### 方法3: CloudKit Web APIの直接使用
```bash
# CloudKit Web APIを使用した例
curl -X POST https://api.apple-cloudkit.com/database/1/iCloud.Delax.CloudKitStarter/development/public/records/modify \
  -H "X-Apple-CloudKit-Request-KeyID: your-key-id" \
  -H "X-Apple-CloudKit-Request-ISO8601Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  -H "X-Apple-CloudKit-Request-SignatureV1: your-signature"
```

## トークン生成の詳細手順

1. **CloudKit Dashboardにログイン**
   - Apple Developer アカウントでログイン
   - 2ファクタ認証を完了

2. **コンテナの確認**
   - コンテナリストに「Delax.CloudKitStarter」が表示されるか確認
   - 表示されない場合は、Xcodeでプロジェクトをビルド

3. **新しいManagement Tokenの生成**
   - Settings > API Tokens
   - Management Tokens セクション
   - 「+」をクリック
   - Token Name: 「Schema Setup Token」など
   - 「Generate」をクリック
   - **重要**: 生成されたトークンを安全な場所にコピー

4. **トークンの検証**
   ```bash
   # トークンを保存
   xcrun cktool save-token "your-token" --type management --method file --force
   
   # チームリストを取得してテスト
   xcrun cktool get-teams
   ```

## よくある問題

1. **トークンタイプの間違い**
   - User TokenではなくManagement Tokenが必要

2. **コンテナが存在しない**
   - Xcodeでプロジェクトをビルドして自動作成

3. **権限不足**
   - トークンにSchema管理権限がない

4. **Team IDの不一致**
   - Apple Developer CenterのTeam IDと一致しているか確認

5. **有効期限切れ**
   - トークンには有効期限があり、期限切れの可能性