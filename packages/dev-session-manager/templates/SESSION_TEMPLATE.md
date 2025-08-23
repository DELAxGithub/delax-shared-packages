# 📋 {{PROJECT_NAME}} セッションテンプレート

**Date**: {{CURRENT_DATE}}  
**Project**: {{PROJECT_NAME}} ({{PROJECT_TYPE}})

---

## 🚀 **セッション開始チェックリスト**

### **1. 現状把握 (3分)**
```bash
# クイックステータス確認
./scripts/quick-status.sh

# 詳細分析が必要な場合
./scripts/quick-status.sh --full
```

### **2. セッション初期化**
```bash
# セッション開始記録
./scripts/progress-tracker.sh session-start
```

### **3. 今回のフォーカス決定**
- [ ] PROGRESS_UNIFIED.md の「NEXT SESSION 推奨優先順序」を確認
- [ ] 選択したタスクを記録: **Task - [タイトル]**
- [ ] 予想時間: **XX分**

---

## 🎯 **セッション中の記録**

### **選択したタスク**
**Task**: 
**タイトル**: 
**予想時間**: 
**開始時刻**: 

### **作業ログ**
- [ ] **分析・調査フェーズ** (XX:XX - XX:XX)
  - 
  - 
  
- [ ] **実装フェーズ** (XX:XX - XX:XX)
  - 
  - 
  
- [ ] **テスト・検証フェーズ** (XX:XX - XX:XX)
  - 
  - 

### **技術スタック別チェックポイント**

#### iOS/Swift プロジェクト
- [ ] ビルドが通ることを確認
- [ ] Xcode警告の確認・修正
- [ ] SwiftUI Previewsが正常動作
- [ ] 実機またはシミュレータでの動作確認

#### Web プロジェクト  
- [ ] `npm run build` または `yarn build` が成功
- [ ] `npm test` または `yarn test` が通過
- [ ] ブラウザでの動作確認
- [ ] レスポンシブデザインの確認

#### Python プロジェクト
- [ ] `python -m pytest` が通過
- [ ] lintチェック (`flake8`, `black` など)
- [ ] 型チェック (`mypy` など)
- [ ] 依存関係の整合性確認

### **発見した問題・課題**
- 
- 
- 

### **次セッションへの引き継ぎ事項**
- 
- 
- 

---

## 🏁 **セッション終了チェックリスト**

### **1. 実装完了確認**
- [ ] 選択したタスクが完全に完了している
- [ ] ビルド/テストが成功することを確認
- [ ] 関連機能が正常に動作することを確認

### **2. ドキュメント更新**
- [ ] PROGRESS_UNIFIED.md に完了実績を追加
- [ ] 新しい課題や気づきがあれば記録

### **3. セッション終了処理**
```bash
# セッション終了記録
./scripts/progress-tracker.sh session-end

# 最終ステータス確認
./scripts/quick-status.sh
```

### **4. コミット・プッシュ**
```bash
# 変更をコミット
git add .
git commit -m "🎯 {{PROJECT_NAME}}: [作業概要]

✅ [主要な成果1]
✅ [主要な成果2]  
✅ [主要な成果3]

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# リモートにプッシュ
git push
```

---

## 📊 **セッション結果サマリー**

### **成果**
- ✅ 
- ✅ 
- ✅ 

### **メトリクス**
- **実時間**: XX分 (予想: XX分)
- **効率**: XX% (実時間/予想時間)
- **コミット数**: XX個
- **変更ファイル数**: XX個

### **技術統計** ({{PROJECT_TYPE}})
#### iOS/Swift
- **Swift ファイル**: XX個
- **SwiftUI Views**: XX個
- **Models**: XX個

#### Web/JavaScript
- **JS/TS ファイル**: XX個
- **Components**: XX個
- **Tests**: XX個

#### Python
- **Python ファイル**: XX個
- **Classes**: XX個
- **Functions**: XX個

### **学んだこと**
- 
- 
- 

### **次回への改善点**
- 
- 
- 

---

## 🎯 **次セッション準備**

### **推奨する次のタスク**
**Task**: 
**理由**: 
**予想時間**: 

### **事前準備が必要なもの**
- [ ] 
- [ ] 
- [ ] 

---

## 💡 **プロジェクト固有メモ**

### **{{PROJECT_TYPE}} 固有の考慮事項**
- 
- 

### **開発環境メモ**
- **ビルドコマンド**: {{BUILD_COMMAND}}
- **テストコマンド**: {{TEST_COMMAND}}
- **主要ディレクトリ**: [設定から自動取得]

### **外部サービス・API**
- 
- 

---

*DELAx Dev Session Manager - Session Template v1.0*  
*Template for: {{PROJECT_NAME}} ({{PROJECT_TYPE}})*  
*Generated: {{CURRENT_DATE}}*