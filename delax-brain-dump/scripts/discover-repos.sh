#!/bin/bash

# DELAX Repository Discovery Script
# GitHub APIから最新のリポジトリ情報を取得して分類情報を生成

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAIN_DUMP_DIR="$(dirname "$SCRIPT_DIR")"
REPOS_CONFIG="$BRAIN_DUMP_DIR/repos-config.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 DELAX Repository Discovery${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
    echo "Install with: brew install gh"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI is not authenticated${NC}"
    echo "Run: gh auth login"
    exit 1
fi

echo -e "${GREEN}📡 Fetching repository information...${NC}"

# Get repository list from GitHub
repos_json=$(gh repo list DELAxGithub --limit 30 --json name,description,primaryLanguage,updatedAt,owner 2>/dev/null)

if [ -z "$repos_json" ] || [ "$repos_json" = "[]" ]; then
    echo -e "${RED}❌ No repositories found or API error${NC}"
    exit 1
fi

echo -e "${GREEN}📊 Processing repository data...${NC}"

# Create temporary file for processing
temp_file=$(mktemp)

# Process repositories and categorize them
echo "$repos_json" | jq '
def classify_by_description(desc; name):
  if (desc | test("プロジェクトマネジメント|プロジェクト管理|進捗管理|TODO|todo")) or 
     (name | test("PM|myprojects|DELAxPM")) then "project-management"
  elif (desc | test("ワークアウト|フィットネス|100日|FTP")) or 
       (name | test("workout|delax100days")) then "fitness"
  elif (desc | test("カロリー|食事|meal")) or 
       (name | test("tonton")) then "nutrition"
  elif (desc | test("共有|shared|component")) or 
       (name | test("shared|delax-shared")) then "shared"
  elif name | test("claude-code|issue-router|slackissue") then "automation"
  else "app"
  end;

def is_active(updated):
  now as $now |
  (updated | fromdateiso8601) as $update_time |
  ($now - $update_time) < (30 * 24 * 3600);

map(select(.name != null)) | 
map({
  name: .name,
  description: (.description // ""),
  language: (.primaryLanguage.name // "Unknown"),
  updated: .updatedAt,
  owner: .owner.login,
  active: is_active(.updatedAt),
  category: classify_by_description(.description // ""; .name),
  repo_url: "DELAxGithub/\(.name)"
}) | 
group_by(.category) | 
map({
  category: .[0].category,
  repos: map(select(.active == true)) | sort_by(.updated) | reverse
})' > "$temp_file"

# Create the configuration file
cat > "$REPOS_CONFIG" << 'EOF'
{
  "generated_at": "",
  "source": "GitHub API",
  "categories": {},
  "classification_rules": {
    "project-management": {
      "keywords": ["プロジェクト", "管理", "TODO", "タスク", "進捗", "PM"],
      "languages": ["TypeScript", "HTML", "Swift"],
      "repos": []
    },
    "fitness": {
      "keywords": ["ワークアウト", "フィットネス", "100日", "FTP", "運動", "トレーニング"],
      "languages": ["Swift", "Dart"],
      "repos": []
    },
    "nutrition": {
      "keywords": ["カロリー", "食事", "meal", "栄養", "レシピ"],
      "languages": ["Dart", "Swift"],
      "repos": []
    },
    "shared": {
      "keywords": ["共有", "shared", "component", "ライブラリ", "パッケージ"],
      "languages": ["Swift", "TypeScript"],
      "repos": []
    },
    "automation": {
      "keywords": ["automation", "claude", "issue", "slack", "bot"],
      "languages": ["TypeScript", "Python"],
      "repos": []
    },
    "app": {
      "keywords": ["アプリ", "app", "mobile"],
      "languages": ["Swift", "Dart"],
      "repos": []
    }
  }
}
EOF

# Update the configuration with current timestamp and processed data
timestamp=$(date -Iseconds)
categories_data=$(cat "$temp_file")

# Create final configuration
jq --arg timestamp "$timestamp" \
   --argjson categories "$categories_data" \
   '.generated_at = $timestamp | 
    .categories = ($categories | reduce .[] as $item ({}; .[$item.category] = $item.repos))' \
   "$REPOS_CONFIG" > "${REPOS_CONFIG}.tmp" && mv "${REPOS_CONFIG}.tmp" "$REPOS_CONFIG"

# Clean up
rm "$temp_file"

echo -e "${GREEN}✅ Repository discovery complete!${NC}"
echo -e "${BLUE}📁 Configuration saved to: $(basename "$REPOS_CONFIG")${NC}"

# Display summary
echo -e "\n${BLUE}📊 Repository Summary:${NC}"
jq -r '
.categories | to_entries | 
map(select(.value | length > 0)) |
sort_by(.key) |
.[] | 
"  \u001b[32m\(.key)\u001b[0m: \(.value | length) repositories" +
if (.value | length > 0) then
  "\n" + (.value[0:3] | map("    - \(.name) (\(.language))") | join("\n")) +
  if (.value | length > 3) then "\n    - ... and \(.value | length - 3) more" else "" end
else ""
end
' "$REPOS_CONFIG"

echo -e "\n${YELLOW}💡 Next steps:${NC}"
echo -e "  1. Review generated configuration: ${BLUE}$REPOS_CONFIG${NC}"
echo -e "  2. Classification system updated with dynamic repositories"
echo -e "  3. Run ${BLUE}./scripts/classify-issues.sh${NC} to test new classification"