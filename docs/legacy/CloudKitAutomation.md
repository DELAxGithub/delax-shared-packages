# CloudKit自動設定機能

このプロジェクトには、CloudKit Management APIとcktoolを使用してスキーマを自動設定する機能が含まれています。

## 機能概要

- **自動スキーマ設定**: 手動でCloudKit Dashboardを操作することなく、アプリからスキーマを設定
- **cktool統合**: Apple公式のCloudKitコマンドラインツールを使用
- **セキュアなトークン管理**: Management Tokenは環境変数で管理

## セットアップ方法

### 方法1: シェルスクリプトを使用（推奨）

1. **Management Tokenの取得**
   ```bash
   # CloudKit Dashboardにアクセス
   open https://icloud.developer.apple.com/dashboard
   ```
   - コンテナ（Delax.CloudKitStarter）を選択
   - Settings > API Tokens
   - 「Generate Management Token」をクリック
   - トークンをコピー

2. **スクリプトの実行**
   ```bash
   cd /path/to/delaxcloudkit
   ./setup_cloudkit.sh
   ```

3. **プロンプトに従って設定**
   - Management Tokenを入力
   - 開発環境への適用を確認
   - 本番環境への適用を選択（オプション）

### 方法2: アプリ内から自動設定

1. **環境変数の設定**
   - Xcodeのスキーム設定で環境変数を追加
   - Key: `CLOUDKIT_MANAGEMENT_TOKEN`
   - Value: 取得したトークン

2. **アプリを起動**
   - エラー画面で「設定ガイドを表示」をタップ
   - 「自動設定」ボタン（魔法の杖アイコン）をタップ
   - 「スキーマを設定」ボタンをクリック

## ファイル構成

### スキーマ定義
- `CloudKitStarter/CloudKitStarter/Resources/schema.json`
  - Memoレコードタイプの定義
  - フィールド: title, content, createdAt
  - インデックス設定

### 実装ファイル
- `CloudKitSchemaManager.swift`: スキーマ管理クラス
- `CloudKitAutoSetupView.swift`: 自動設定UI
- `setup_cloudkit.sh`: セットアップスクリプト

## トラブルシューティング

### cktoolが見つからない
```bash
# Xcodeがインストールされているか確認
xcode-select --print-path

# cktoolの存在確認
xcrun cktool --version
```

### Management Tokenエラー
- トークンが正しくコピーされているか確認
- トークンの有効期限を確認（CloudKit Dashboard）
- 環境変数が正しく設定されているか確認

### スキーマ適用エラー
- コンテナIDが正しいか確認
- Bundle IDとコンテナIDの対応を確認
- ネットワーク接続を確認

## セキュリティ考慮事項

1. **トークンの管理**
   - Management Tokenは機密情報です
   - `.env`ファイルに保存する場合は`.gitignore`に追加
   - 本番環境では環境変数やCI/CDのシークレットを使用

2. **アクセス制限**
   - Management Tokenは最小限の権限で作成
   - 定期的にトークンを更新
   - 不要になったトークンは削除

## 開発フロー

1. スキーマ変更時は`schema.json`を更新
2. 開発環境でテスト
3. 本番環境に適用前に十分なテストを実施
4. CI/CDパイプラインに組み込むことも可能

## 参考リンク

- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [cktool Reference](https://developer.apple.com/documentation/cloudkit/managing_icloud_containers_with_the_cloudkit_database_app)
- [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)