#!/usr/bin/env bash
#
# 新しいアプリの法的ページ(プライバシーポリシー・利用規約・お問い合わせ)を
# 中央リポジトリ app-legal のサブフォルダとして生成し、GitHub Pages で公開する。
#
# 運営者名・連絡先メール・GitHubアカウントは kit/config.json から自動で読み込むため、
# アプリごとに書く必要はない(共有される)。
#
# 使い方:
#   ./kit/new-app.sh <スラッグ> "<アプリ名>" "<説明文>" [アクセント色] [アクセント色(暗)]
# 例:
#   ./kit/new-app.sh myapp2 "マイアプリ2" "写真を整理するアプリ" "#3B82F6"
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

SLUG="${1:?使い方: new-app.sh <スラッグ> \"<アプリ名>\" \"<説明文>\" [アクセント色] [アクセント色(暗)]}"
NAME="${2:?アプリ名が必要です}"
DESC="${3:-}"
ACCENT="${4:-#FF6B1A}"
ACCENT_DARK="${5:-#FF7C33}"

if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
  echo "エラー: gh CLI にログインしていません。'gh auth login' を実行してください。" >&2
  exit 1
fi

CFG="$SCRIPT_DIR/config.json"
read -r OPERATOR EMAIL GH_USER REPO < <(python3 -c "import json;c=json.load(open('$CFG'));print(c['operator'],c['email'],c['githubUser'],c['repo'])")
DATE=$(date "+%Y年%-m月%-d日")

echo "アプリ    : $NAME ($SLUG)"
echo "運営者    : $OPERATOR <$EMAIL>"
echo "公開先    : $GH_USER/$REPO/$SLUG"

# テンプレートを流し込んで <slug>/ を生成(値の特殊文字に強いようPythonで置換)
python3 - "$SLUG" "$NAME" "$DESC" "$OPERATOR" "$EMAIL" "$DATE" "$ACCENT" "$ACCENT_DARK" "$SCRIPT_DIR" <<'PY'
import sys, os, pathlib
slug, name, desc, op, email, date, acc, accd, kitdir = sys.argv[1:10]
repl = {'__APP_NAME__':name, '__APP_DESC__':desc, '__OPERATOR__':op,
        '__EMAIL__':email, '__DATE__':date, '__ACCENT__':acc, '__ACCENT_DARK__':accd}
os.makedirs(slug, exist_ok=True)
for f in ['privacy.html','terms.html','index.html','style.css']:
    s = pathlib.Path(kitdir,'templates',f).read_text(encoding='utf-8')
    for k,v in repl.items():
        s = s.replace(k, v)
    pathlib.Path(slug, f).write_text(s, encoding='utf-8')
print("generated", slug)
PY

git add -A
git commit -q -m "Add legal pages for $SLUG ($NAME)" || echo "(変更なし)"

# 初回はリポジトリを作成、以降はpush
if git remote get-url origin >/dev/null 2>&1; then
  git push -q origin main
else
  gh repo create "$GH_USER/$REPO" --public --source=. --remote=origin --push
fi

# GitHub Pages を有効化(既に有効なら無視)
gh api -X POST "repos/$GH_USER/$REPO/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
  || true

BASE="https://$GH_USER.github.io/$REPO/$SLUG"
echo ""
echo "✅ 公開しました(反映まで1〜2分)"
echo "-------------------------------------------------------------"
echo "プライバシーポリシー: $BASE/privacy.html"
echo "利用規約            : $BASE/terms.html"
echo "トップ(お問い合わせ): $BASE/"
echo "-------------------------------------------------------------"
echo "アプリの AppConfig 等に上記URLを設定してください。"
echo "位置情報など個別機能の記載が必要なら $SLUG/privacy.html を編集し、"
echo "  git add -A && git commit -m 'edit' && git push で更新できます。"
