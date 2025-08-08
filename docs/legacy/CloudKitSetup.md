# CloudKit Setup Instructions

## Xcodeでの設定手順

### 1. CloudKit機能の有効化
1. Xcodeでプロジェクトを開く
2. プロジェクトナビゲータで「CloudKitStarter」プロジェクトを選択
3. 「CloudKitStarter」ターゲットを選択
4. 「Signing & Capabilities」タブを開く
5. 「+ Capability」ボタンをクリック
6. 「CloudKit」を検索して追加

### 2. エンタイトルメントファイルの確認
1. プロジェクトに `CloudKitStarter.entitlements` が追加されていることを確認
2. Build Settingsで `CODE_SIGN_ENTITLEMENTS` が正しく設定されていることを確認

### 3. CloudKit Dashboardでの設定（重要）

#### 手順1: CloudKit Dashboardにアクセス
1. [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)にアクセス
2. Apple Developer アカウントでサインイン

#### 手順2: コンテナを選択
1. 「Delax.CloudKitStarter」コンテナを選択
2. もしコンテナが表示されない場合は、Xcodeでプロジェクトを一度ビルドしてください

#### 手順3: レコードタイプを作成
1. 左側メニューの「Schema」をクリック
2. 「Record Types」を選択
3. 「+」ボタンをクリックして新規レコードタイプを作成
4. Record Type名に「Memo」と入力

#### 手順4: フィールドを追加
以下のフィールドを追加してください：

| Field Name | Field Type | 設定 |
|------------|------------|------|
| title | String | Queryable ✓, Sortable ✓ |
| content | String | Queryable ✓, Sortable ✓ |
| createdAt | Date/Time | Queryable ✓, Sortable ✓ |

**重要**: 各フィールドの「Queryable」と「Sortable」のチェックボックスを必ずオンにしてください。

#### 手順5: 保存
1. 画面右上の「Save」ボタンをクリック
2. 変更が反映されるまで数秒待つ

### 4. プロジェクトのビルドと実行
1. 実機またはシミュレータを選択
2. Cmd+R でビルドして実行
3. iCloudアカウントにサインインしていることを確認

## トラブルシューティング

### "Type is not marked indexable: Memo" エラーが出る場合
これは最も一般的なエラーです。以下を確認してください：
1. CloudKit Dashboardで「Memo」レコードタイプが作成されているか
2. 各フィールドの「Queryable」にチェックが入っているか
3. 「Save」ボタンをクリックして変更を保存したか
4. アプリ内で「設定ガイドを表示」ボタンをタップして手順を確認

### "Failed to fetch" エラーが出る場合
- シミュレータ/実機でiCloudにサインインしているか確認
- 設定アプリ > [あなたの名前] > iCloud > iCloud Driveがオンになっているか確認
- ネットワーク接続を確認

### ビルドエラーが出る場合
- Team IDが正しく設定されているか確認（Z88477N5ZU）
- Bundle IDが正しいか確認（Delax.CloudKitStarter）
- Provisioning Profileが有効か確認
- CloudKit機能が有効になっているか確認

### アプリ内設定ガイド
アプリ内でエラーが発生した場合、「設定ガイドを表示」ボタンが表示されます。
このガイドに従って、ステップバイステップでCloudKitの設定を行うことができます。