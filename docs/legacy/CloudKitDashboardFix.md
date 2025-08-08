# CloudKit Dashboard手動修正手順

## 「Field 'recordName' is not marked queryable」エラーの解決方法

### 手順1: CloudKit Dashboardにアクセス
1. [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)を開く
2. Apple IDでサインイン
3. 「CloudKit Database」を選択

### 手順2: コンテナを選択
1. 「iCloud.Delax.CloudKitStarter」を選択
2. 「Development」環境を選択

### 手順3: Indexesタブを確認
1. 左側のメニューから「Indexes」を選択
2. 「Note」レコードタイプを選択

### 手順4: インデックスの追加（重要）
1. 「Add Index」ボタンをクリック
2. 以下の設定でインデックスを作成：
   - **Index Type**: QUERYABLE
   - **Field**: recordID（またはsystemフィールド）
   
### 手順5: 既存のインデックス確認
1. 既に存在するインデックスを確認
2. 「title」フィールドがQueryableになっているか確認

### 手順6: 保存
1. 「Save」をクリック
2. 変更が反映されるまで数分待つ

### 代替案: カスタムインデックスの作成
もし上記がうまくいかない場合：
1. 「Custom Indexes」セクションで新規作成
2. 複合インデックスを作成（recordID + 他のフィールド）

### 注意事項
- システムフィールド（recordID、recordName）は通常自動的にインデックスされているはずですが、何らかの理由で無効になっている可能性があります
- Development環境で変更した後、Production環境にも同じ変更を適用する必要があります

## それでも解決しない場合
下記の代替実装を使用してください。