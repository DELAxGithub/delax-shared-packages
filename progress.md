# CloudKitStarter開発進捗

## プロジェクト概要
- **プロジェクト名**: CloudKitStarter
- **Bundle ID**: Delax.CloudKitStarter
- **GitHubリポジトリ**: https://github.com/DELAxGithub/delaxcloudkit.git
- **目的**: CloudKit対応の最小構成メモアプリ

## 開発フェーズ

### Phase 1: 基本セットアップ ✅
1. **Git/GitHub連携**
   - リポジトリ初期化
   - .gitignore作成（Xcode用）
   - GitHubへプッシュ完了

2. **プロジェクト構造**
   ```
   CloudKitStarter/
   ├── CloudKitStarter.xcodeproj
   ├── CloudKitStarter/
   │   ├── CloudKitStarterApp.swift
   │   ├── ContentView.swift
   │   ├── CloudKitStarter.entitlements
   │   ├── Models/
   │   │   └── Memo.swift
   │   ├── Services/
   │   │   ├── CloudKitManager.swift
   │   │   └── CloudKitSchemaManager.swift
   │   ├── Views/
   │   │   ├── MemoListView.swift
   │   │   ├── CreateMemoView.swift
   │   │   ├── EditMemoView.swift
   │   │   ├── CloudKitSetupGuideView.swift
   │   │   └── CloudKitAutoSetupView.swift
   │   └── Resources/
   │       └── schema.json
   ├── setup_cloudkit.sh
   ├── CLAUDE.md
   ├── CloudKitSetup.md
   └── CloudKitAutomation.md
   ```

### Phase 2: CloudKit基本実装 ✅
1. **データモデル**
   - Memoモデル（title, content, createdAt）
   - CloudKit CKRecord変換機能

2. **CloudKitManager**
   - CRUD操作（作成・読込・更新・削除）
   - エラーハンドリング
   - 日本語エラーメッセージ

3. **UI実装**
   - メモ一覧（MemoListView）
   - メモ作成（CreateMemoView）
   - メモ編集（EditMemoView）
   - プルトゥリフレッシュ

### Phase 3: エラー対応 ✅
1. **問題**: "Type is not marked indexable: Memo"エラー
2. **解決策**:
   - 詳細なエラーハンドリング追加
   - CloudKitSetupGuideView作成
   - ステップバイステップガイド
   - CloudKit Dashboard設定手順の文書化

### Phase 4: 自動化実装 ✅
1. **CloudKit Management Token対応**
   - schema.json作成（開発/本番環境）
   - CloudKitSchemaManager実装
   - cktool連携

2. **自動設定スクリプト**
   - setup_cloudkit.sh作成
   - 対話式セットアップ
   - トークン管理（.env対応）

3. **UI統合**
   - CloudKitAutoSetupView追加
   - 設定ガイドに自動設定ボタン追加

## 技術的な実装詳細

### CloudKitスキーマ
```json
{
  "recordType": "Memo",
  "fields": [
    {"fieldName": "title", "fieldType": "STRING", "isQueryable": true, "isSortable": true},
    {"fieldName": "content", "fieldType": "STRING", "isQueryable": true, "isSortable": false},
    {"fieldName": "createdAt", "fieldType": "TIMESTAMP", "isQueryable": true, "isSortable": true}
  ]
}
```

### エラーハンドリング
- CKError.unknownItem → スキーマ未設定
- CKError.notAuthenticated → iCloud未ログイン
- CKError.networkFailure → ネットワークエラー
- CKError.quotaExceeded → 容量不足

### セキュリティ
- Management Tokenは環境変数で管理
- .gitignoreで機密情報を除外
- トークンの安全な取り扱い方法を文書化

## 使用方法

### 手動設定
1. CloudKit Dashboardでレコードタイプ作成
2. フィールド追加（Queryable/Sortableを有効化）
3. アプリを実行

### 自動設定（ターミナル）
```bash
# Management Token取得後
./setup_cloudkit.sh
# または
export CLOUDKIT_MANAGEMENT_TOKEN="your-token"
./setup_cloudkit.sh
```

### 自動設定（アプリ内）
1. エラー画面で「設定ガイドを表示」
2. 「自動設定」ボタン（魔法の杖アイコン）
3. 環境変数設定後「スキーマを設定」

## 学習ポイント

1. **CloudKit基本**
   - CKContainer/CKDatabase/CKRecord
   - 非同期処理とエラーハンドリング
   - レコードタイプとインデックス

2. **SwiftUI統合**
   - @StateObject/@ObservedObject
   - シート表示とナビゲーション
   - エラーアラート表示

3. **自動化**
   - cktoolの使用方法
   - Management Token API
   - シェルスクリプトでの対話処理

## 今後の展開可能性

1. **CI/CD統合**
   - GitHub Actionsでの自動スキーマ更新
   - テスト環境の自動構築

2. **機能拡張**
   - 画像添付機能
   - 共有機能（Public Database）
   - リアルタイム同期（Subscriptions）

3. **パフォーマンス最適化**
   - オフライン対応
   - キャッシュ実装
   - バッチ処理

## Phase 5: Management Token実装の課題 🚧

### 発生した問題
1. **Management Token認証エラー**
   - エラー: "Session has expired or is invalid"
   - 2つのトークンを試行したが両方とも認証失敗
   - Token 1: a42cec27a5c31853a6d4f2f5450bb6130893a671f6c5510d8fe73ed31ebffc22
   - Token 2: 470a7652609a159e8c11ae13b19493f77a45565920f00574b111ac606ded0ee7

2. **cktoolの仕様変更**
   - `--token`オプションの直接使用は非推奨
   - `save-token`コマンドでトークンを事前保存する必要がある
   - トークンは`~/.config/cktool`に保存される

3. **試行した解決策**
   ```bash
   # トークンの保存
   xcrun cktool save-token "token" --type management --method file --force
   
   # スキーマのインポート
   xcrun cktool import-schema \
     --team-id "Z88477N5ZU" \
     --container-id "iCloud.Delax.CloudKitStarter" \
     --environment "development" \
     --file "schema.json"
   ```

### 根本原因の可能性
1. **コンテナの存在確認**
   - CloudKit Dashboardでコンテナが作成されていない可能性
   - Xcodeでプロジェクトをビルドして自動作成が必要

2. **トークンの権限不足**
   - Management Tokenに必要な権限が付与されていない
   - Schema Read/Write権限が必要

3. **Team ID/Container IDの不一致**
   - 実際のApple Developer設定と異なる可能性

### 作成したトラブルシューティング資料
- `CloudKitTokenSetup.md` - 新しいトークン取得手順
- `CloudKitTokenTroubleshooting.md` - 詳細なトラブルシューティング
- `test_cktool.sh` - cktoolのデバッグスクリプト

### 推奨される解決方法
現時点では、CloudKit Dashboardでの手動設定が最も確実：
1. [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)にアクセス
2. 手動でMemoレコードタイプを作成
3. フィールドとインデックスを設定

この経験から、cktoolによる自動化は理想的だが、実際の運用では手動設定との併用が現実的であることが判明。

## Phase 6: iOSビルドエラー修正 ✅

### 発生したエラーと修正
1. **Process API使用エラー**
   - `Process`クラスはmacOS専用でiOSでは使用不可
   - `#if os(macOS)`でプラットフォーム分岐を実装
   - iOSでは`cktoolNotAvailableOnIOS`エラーを返すように修正

2. **SwiftUI APIの非推奨警告**
   - `onChange(of:perform:)`をiOS 17以降の新しいAPIに更新
   - `perform(_:inZoneWith:)`を`fetch(withQuery:)`に更新

3. **UIコンポーネントのエラー**
   - `StatusRow`のBool型パラメータ処理を修正
   - CloudKitAutoSetupViewでiOS制限メッセージを表示

## Phase 7: CloudKit実行時エラー対応 ✅

### Field 'recordName' is not marked queryable エラー
- システムフィールド名の誤りを修正
- `modificationDate` → `createdAt`に変更
- CloudKitFieldReference.mdドキュメント作成

## Phase 8: cktoolによるターミナル操作 🚀

### User Token取得と保存 ✅
1. **User Token取得方法**
   ```bash
   xcrun cktool save-token --type user
   ```
   - ブラウザが自動的に開く
   - Apple IDでサインイン
   - 認証後、トークンが自動保存

2. **取得したUser Token**
   - 長いトークン文字列を正常に取得
   - `~/.config/cktool`に保存完了

### CloudKit操作スクリプト作成 ✅
- `cloudkit_operations.sh`作成
- list/create/delete機能実装
- 対話式インターフェース

### 発生した課題
1. **クエリエラー**
   - "Field 'recordName' is not marked queryable"
   - CloudKit側の設定確認が必要

2. **レコード作成時のJSONフォーマット**
   - cktoolが期待する特定の構造が必要
   - フィールドタイプの指定方法が不明確

## 学習ポイント（追加）

### iOS開発の制約
- macOS専用APIの存在（Process等）
- プラットフォーム条件付きコンパイル
- CloudKit APIの進化と非推奨

### cktoolの活用
- Management Token（スキーマ管理）
- User Token（レコード操作）
- ターミナルからのCloudKit操作

### トラブルシューティングスキル
- エラーメッセージの解析
- API仕様の調査
- 段階的な問題解決

## 現在の状態

### 完成した機能
- ✅ Git/GitHub連携
- ✅ CloudKit基本実装
- ✅ エラーハンドリング
- ✅ 自動設定機能（macOS）
- ✅ iOSビルド対応
- ✅ User Token認証
- ✅ ターミナル操作スクリプト

### 未解決の課題
- CloudKitクエリ設定の調整
- cktoolのレコード作成フォーマット
- recordNameフィールドのインデックス設定

## 今後の作業
1. CloudKit Dashboardでフィールド設定を確認
2. アプリ経由でテストレコードを作成
3. cktoolでのレコード操作を完成

## Phase 9: recordNameエラーの徹底調査と解決 🔍

### 繰り返し発生した問題
1. **"Field 'recordName' is not marked queryable"エラー**
   - アプリ実行時に継続的に発生
   - cloudkit_operations.shでも同様のエラー

2. **調査結果**
   - CloudKitManager.swiftはrecordNameを直接使用していない
   - sortDescriptorsで`createdAt`や`creationDate`を使用
   - 問題はCloudKit側の内部処理の可能性

3. **実装した解決策**
   ```swift
   // 最もシンプルなクエリに変更
   let query = CKQuery(recordType: "Memo", predicate: NSPredicate(value: true))
   // sortDescriptorsを完全に削除
   
   // CKQueryOperationを使用
   let operation = CKQueryOperation(query: query)
   
   // クライアント側でソート
   memos.sort { $0.createdAt > $1.createdAt }
   ```

## Phase 10: CloudKit完全リセット（Memo → Note）🔄

### リセットの理由
- recordNameエラーが解決しない
- CloudKit側の設定をクリーンにする必要性
- 最小限の実装で基本動作を確認

### 実装内容
1. **新しいNoteモデル**
   ```swift
   struct Note: Identifiable, Hashable {
       let id: String
       var title: String
       var record: CKRecord?
   }
   ```
   - 最小限のフィールド（titleのみ）
   - recordNameはIDの取得にのみ使用

2. **CloudKitManager更新**
   - memos → notesに変更
   - 最もシンプルなクエリ実装
   - ソート機能なし

3. **View層の刷新**
   - NoteListView.swift（新規作成）
   - CreateNoteView.swift（新規作成）
   - EditNoteView.swift（新規作成）
   - ContentView.swift（更新）

4. **ファイルの削除**
   - Memo.swift
   - MemoListView.swift
   - CreateMemoView.swift
   - EditMemoView.swift

5. **schema.json更新**
   ```json
   {
     "recordType": "Note",
     "fields": [
       {
         "fieldName": "title",
         "fieldType": "STRING",
         "isQueryable": true,
         "isSortable": true,
         "isSearchable": true
       }
     ]
   }
   ```

### CloudKit Dashboard手動作業
1. 「Memo」レコードタイプを削除
2. 「Note」レコードタイプを新規作成
3. titleフィールドのみ追加（Queryable/Sortable有効）

## Phase 11: Management Token成功とcktoolアクセス確認 ✅

### Management Token接続成功
1. **新しいManagement Token取得**
   ```
   eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9...（省略）
   ```

2. **トークン保存と動作確認**
   ```bash
   xcrun cktool save-token "token" --type management --method file --force
   ```

3. **スキーマエクスポート成功**
   ```bash
   xcrun cktool export-schema --team-id "Z88477N5ZU" --container-id "iCloud.Delax.CloudKitStarter" --environment "development"
   ```
   - Memoレコードタイプが存在（古い設定）
   - Noteレコードタイプは未作成

4. **チーム情報取得成功**
   ```
   Z88477N5ZU: HIROSHI KODERA
   ```

### トークンの使い分け理解
- **User Token**: レコード操作（query/create/delete）
- **Management Token**: スキーマ操作（export/import）、チーム情報取得
- 両方のトークンが必要な理由が明確に

### 現在の状況
- Management Tokenが正常に動作
- CloudKitへの接続確認完了
- スキーマ管理がcktoolで可能
- 次はNoteレコードタイプの作成が必要

## Phase 12: recordNameエラーの完全回避実装 ✅

### 問題
- 「Field 'recordName' is not marked queryable」エラーが継続的に発生
- CKQueryが内部的にrecordNameを使用している可能性

### 実装した解決策
1. **CloudKitManagerAlternative.swift作成**
   - CKQueryを一切使用しない実装
   - レコードIDをUserDefaultsに保存
   - `fetch(withRecordIDs:)`で個別にレコード取得
   - クエリエラーを完全に回避

2. **NoteListViewAlternative.swift作成**
   - 代替CloudKitManagerを使用
   - 空状態の表示改善
   - リスト内で内容のプレビュー表示

3. **ContentView.swift更新**
   - 代替実装を使用するように変更

### 成果
- ✅ recordNameエラーを完全に回避
- ✅ アプリが正常に動作
- ✅ ノートの作成・編集・削除が可能

## Phase 13: 複数行メモ対応実装 ✅

### 機能拡張
1. **Noteモデルの拡張**
   - contentフィールド追加（メモの内容）
   - createdAt/modifiedAt追加（作成・更新日時）

2. **CloudKitスキーマ更新**
   - contentフィールドをスキーマに追加
   - cktoolでスキーマをインポート成功

3. **UI機能の拡張**
   - **CreateNoteView**: TextEditorで複数行入力対応
   - **EditNoteView**: 
     - TextEditorで内容編集
     - 作成日時・更新日時の表示
   - **NoteListView**: 
     - 内容のプレビュー表示（最大2行）
     - 更新日時の表示

### ビルドエラー修正
1. **型チェックエラー**
   - NoteListViewAlternativeが複雑すぎる問題
   - ビューコンポーネントを分割して解決
   - EmptyNoteView、NoteListContent、NoteRowViewに分離

2. **Color APIエラー**
   - `.tertiary`がShapeStyleになった問題
   - `Color.secondary.opacity(0.6)`で代替

### 最終成果
- ✅ CloudKit連携成功（クエリエラー回避）
- ✅ 複数行メモの作成・編集が可能
- ✅ 作成・更新日時の自動記録
- ✅ メモ内容のプレビュー表示
- ✅ アプリが正常に動作

## 学習ポイント（最終）

### CloudKitの制約と回避策
- システムフィールドのクエリ制限
- 代替実装でのエラー回避方法
- レコードIDによる個別取得

### SwiftUIの最適化
- 複雑なビューの分割
- 型チェックエラーの解決
- iOS APIの変更への対応

### 実装の工夫
- UserDefaultsを使ったレコードID管理
- エラーを回避する設計パターン
- ユーザー体験を損なわない代替実装

## 今後の拡張可能性
1. 画像添付機能
2. 検索機能（ローカル検索）
3. タグ機能
4. 共有機能
5. iCloud同期の改善

## Phase 14: お気に入り機能実装 ✅

### 実装内容
1. **データモデルの拡張**
   - NoteモデルにisFavoriteフィールド追加
   - CloudKit INT64型との相互変換実装
   
2. **CloudKitスキーマ更新**
   - isFavoriteフィールド追加（INT64型、Queryable）
   - update_note_schema_favorite.ckdbファイル作成
   
3. **UI機能追加**
   - NoteRowViewにハートアイコン追加
   - タップでお気に入り切り替え可能
   - お気に入り状態は赤色のハートで表示
   
4. **ビジネスロジック**
   - CloudKitManagerAlternativeにtoggleFavorite機能実装
   - お気に入りノートを上部に表示するソート機能
   - グループ内では更新日時でソート

### 技術的詳細
```swift
// CloudKitのINT64型対応
// 保存時
record["isFavorite"] = isFavorite ? 1 : 0

// 読み込み時
if let favoriteValue = record["isFavorite"] as? Int64 {
    self.isFavorite = favoriteValue != 0
}
```

### 成果
- ✅ お気に入り機能が完全に動作
- ✅ CloudKitとの同期も正常
- ✅ 既存のコードを壊さずに段階的に実装完了

## Phase 15: 共有機能実装（CKShare導入）🔗

### 実装内容
1. **CloudKitスキーマ拡張**
   - schema.json完全更新（全フィールド定義＋isShareable: true）
   - 現在の実装（title, content, createdAt, modifiedAt, isFavorite）に完全対応
   
2. **Noteモデル拡張**
   ```swift
   struct Note {
       // 既存フィールド...
       var shareRecord: CKShare?
       
       // 共有状態判定
       var isShared: Bool { return shareRecord != nil }
       var shareURL: URL? { return shareRecord?.url }
       
       // 共有レコード対応初期化
       init(from record: CKRecord, shareRecord: CKShare? = nil)
   }
   ```

3. **UICloudSharingController SwiftUIラッパー**
   - CloudSharingView.swift新規作成
   - UIViewControllerRepresentable実装
   - .sheet()でのモーダル表示対応（.fullScreenCover不可の制約対応）
   - Coordinator でのデリゲート処理
   - CKShareのIdentifiable拡張

4. **CloudKitManagerAlternative大幅拡張**
   ```swift
   // 共有機能メソッド群
   func createShare(for:completion:) // 既存共有の再利用対応
   func fetchSharedNotes(completion:) // sharedCloudDatabase対応
   func stopSharing(for:completion:) // 全参加者削除の注意点対応
   func loadAllNotes() // Private+Shared統合取得
   
   // 共有エラー処理
   enum CloudKitSharingError: Error, LocalizedError
   ```

5. **UI統合**
   - NoteRowView に共有ボタン（person.2 アイコン）追加
   - 共有状態の視覚的フィードバック（グレー→青）
   - お気に入りボタンとの横並び配置
   - CloudSharingView のsheet表示統合

6. **統合データ管理**
   - Private Database + Shared Database の同時取得
   - お気に入り＞更新日時の統合ソート
   - fetchNotes() → loadAllNotes() への移行

### 技術的実装ポイント

#### ワンポイント補足対応
1. **createShare時のエラー処理**
   ```swift
   if let ckError = error as? CKError, ckError.code == .alreadyShared {
       // 既存のCKShareを取得して再利用
       self.fetchExistingShare(for: record) { shareResult in
           completion(shareResult)
       }
   }
   ```

2. **共有データのfetch**
   ```swift
   // sharedCloudDatabase から fetchAllRecordZones → 各 zone のレコード取得
   sharedDatabase.fetchAllRecordZones { result in
       // 各zoneからレコード取得
   }
   ```

3. **UICloudSharingController表示位置**
   - SwiftUI では必ず .sheet で表示（.fullScreenCover は不可）
   - UIViewControllerRepresentable での適切なラッピング

4. **共有解除の注意点**
   - CKModifyRecordsOperation で CKShare を削除
   - 全参加者からノートが削除される（意図的な動作）

### エラーハンドリング強化
```swift
// CloudKit共有関連エラーの完全対応
case .alreadyShared: "このアイテムは既に共有されています。"
case .participantMayNeedVerification: "参加者の確認が必要です。"  
case .tooManyParticipants: "参加者数が上限に達しています。"
```

### 成果
- ✅ ノート毎の共有機能が完全に動作
- ✅ Private/Shared notes の統合表示
- ✅ 既存機能（お気に入り等）への影響なし  
- ✅ エラーハンドリングの堅牢性確保
- ✅ 共有状態の視覚的フィードバック
- ✅ .sheet() での適切なモーダル表示

### テスト環境
- test_sharing_feature.sh作成（共有機能テストスクリプト）
- cktool連携によるレコード作成・削除テスト
- 共有テスト用ガイダンス自動生成

### 実装上の学び
1. **UICloudSharingController制約**: SwiftUIでは.sheetでの表示が必須
2. **CKShare再利用**: alreadySharedエラー時の既存共有取得パターン
3. **Database分離**: Private/Sharedの適切な使い分けと統合表示
4. **共有解除リスク**: 全参加者への影響を考慮した実装

### 今後の展開可能性
1. **権限管理**: 読み取り専用共有の実装
2. **通知機能**: CKSubscriptionによるリアルタイム同期
3. **共有管理UI**: 参加者一覧・権限変更画面
4. **共有履歴**: 共有イベントのログ機能

## 参考リンク
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
- [GitHub Repository](https://github.com/DELAxGithub/delaxcloudkit)
- [CKShare Documentation](https://developer.apple.com/documentation/cloudkit/ckshare)