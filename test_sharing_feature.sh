#!/bin/bash

# CloudKitStarter 共有機能テストスクリプト
# Usage: ./test_sharing_feature.sh

echo "🧪 CloudKitStarter 共有機能テストスクリプト"
echo "============================================="

# 環境チェック
if ! command -v xcrun &> /dev/null; then
    echo "❌ Xcode Command Line Tools がインストールされていません"
    exit 1
fi

# cktoolの存在確認
if ! xcrun cktool --help &> /dev/null; then
    echo "❌ cktool が利用できません"
    exit 1
fi

# 基本設定
TEAM_ID="Z88477N5ZU"
CONTAINER_ID="iCloud.Delax.CloudKitStarter"
ENVIRONMENT="development"

echo "📋 テスト設定:"
echo "  Team ID: $TEAM_ID"
echo "  Container ID: $CONTAINER_ID"
echo "  Environment: $ENVIRONMENT"
echo ""

# 1. スキーマ確認テスト
echo "🔍 1. CloudKitスキーマ確認テスト"
echo "--------------------------------"

echo "現在のスキーマを確認中..."
schema_result=$(xcrun cktool export-schema --team-id "$TEAM_ID" --container-id "$CONTAINER_ID" --environment "$ENVIRONMENT" 2>&1)

if [[ $schema_result == *"Note"* ]]; then
    echo "✅ Noteレコードタイプが存在します"
    
    # isShareableチェック
    if [[ $schema_result == *"isShareable"* ]]; then
        echo "✅ NoteレコードタイプでisShareableが有効です"
    else
        echo "⚠️  NoteレコードタイプでisShareableが無効です - CloudKit Dashboardで有効にしてください"
    fi
else
    echo "❌ Noteレコードタイプが見つかりません"
    echo "   CloudKit Dashboardまたはcktoolでスキーマをインポートしてください"
fi
echo ""

# 2. レコード作成テスト
echo "📝 2. テストノート作成"
echo "--------------------"

# テスト用レコードJSONを作成
cat > test_note_record.json << EOF
{
  "recordType": "Note",
  "fields": {
    "title": {
      "fieldType": "STRING",
      "value": "共有テスト用ノート - $(date '+%Y-%m-%d %H:%M:%S')"
    },
    "content": {
      "fieldType": "STRING", 
      "value": "このノートは共有機能のテスト用です。\\n複数行のコンテンツも正常に表示されるかを確認します。"
    },
    "isFavorite": {
      "fieldType": "INT64",
      "value": 1
    }
  }
}
EOF

echo "テスト用ノートを作成中..."
create_result=$(xcrun cktool create-record --team-id "$TEAM_ID" --container-id "$CONTAINER_ID" --environment "$ENVIRONMENT" --file test_note_record.json 2>&1)

if [[ $create_result == *"recordName"* ]]; then
    echo "✅ テストノートを作成しました"
    record_name=$(echo "$create_result" | grep -o '"recordName":"[^"]*"' | cut -d'"' -f4)
    echo "   Record Name: $record_name"
else
    echo "❌ テストノート作成に失敗しました"
    echo "   エラー: $create_result"
fi
echo ""

# 3. レコード一覧確認
echo "📋 3. ノート一覧確認"
echo "------------------"

echo "作成されたノートを確認中..."
list_result=$(xcrun cktool list --team-id "$TEAM_ID" --container-id "$CONTAINER_ID" --environment "$ENVIRONMENT" --record-type "Note" 2>&1)

if [[ $list_result == *"共有テスト用ノート"* ]]; then
    echo "✅ テストノートが一覧に表示されています"
else
    echo "⚠️  テストノートが一覧に見つかりません"
    echo "   結果: $list_result"
fi
echo ""

# 4. 共有機能ガイダンス
echo "🔗 4. 共有機能テストガイダンス"
echo "-----------------------------"

echo "以下の手順でアプリの共有機能をテストしてください:"
echo ""
echo "📱 アプリ内テスト手順:"
echo "  1. CloudKitStarterアプリを起動"
echo "  2. ノート一覧で共有ボタン(👥)をタップ"
echo "  3. UICloudSharingControllerが表示されることを確認"
echo "  4. 共有リンクを作成して他のデバイス/ユーザーに送信"
echo "  5. 受信側で共有リンクをタップして受諾"
echo ""
echo "🔍 確認ポイント:"
echo "  ✓ 共有ボタンがグレー(👥)から青(👥)に変化"
echo "  ✓ 共有ノートが両方のデバイスで編集可能"
echo "  ✓ 編集内容が即座に同期される"
echo "  ✓ 共有解除で参加者からノートが消える"
echo ""
echo "⚠️  注意事項:"
echo "  • 共有機能テストには2台以上のデバイスが必要"
echo "  • 各デバイスで異なるApple IDでiCloudにサインイン"
echo "  • インターネット接続が必要"
echo ""

# 5. クリーンアップ
echo "🧹 5. テストクリーンアップ"
echo "------------------------"

read -p "テスト用レコードを削除しますか? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ -n $record_name ]]; then
        echo "テスト用レコードを削除中..."
        delete_result=$(xcrun cktool delete-record --team-id "$TEAM_ID" --container-id "$CONTAINER_ID" --environment "$ENVIRONMENT" --record-name "$record_name" 2>&1)
        
        if [[ $? -eq 0 ]]; then
            echo "✅ テスト用レコードを削除しました"
        else
            echo "❌ テスト用レコード削除に失敗しました"
            echo "   エラー: $delete_result"
        fi
    fi
fi

# 一時ファイルクリーンアップ
rm -f test_note_record.json

echo ""
echo "🎉 共有機能テストスクリプト完了！"
echo ""
echo "📚 追加情報:"
echo "  • CloudKit Dashboard: https://icloud.developer.apple.com/dashboard"
echo "  • 共有機能ドキュメント: PROJECT_INDEX.md"
echo "  • 詳細ログ: progress.md"