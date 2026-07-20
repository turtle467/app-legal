#!/usr/bin/env python3
"""ルート index.html の「アプリ一覧」へアプリを1行追記する（既にあれば名前・説明を更新）。

new-app.sh から呼ばれる。ここを忘れると
https://turtle467.github.io/app-legal/ の一覧からたどれないアプリになるため、
ページ生成と同時に自動実行している。

使い方: update-index.py <スラッグ> <アプリ名> <説明文> <index.htmlのパス>
"""
import html
import pathlib
import re
import sys


def build_entry(slug: str, name: str, desc: str) -> str:
    entry = f'    <li><a href="{slug}/">{html.escape(name)}</a>'
    if desc:
        entry += f' — {html.escape(desc)}'
    return entry + '</li>'


def update(slug: str, name: str, desc: str, path: pathlib.Path) -> str:
    """追記または更新して、行った操作を返す。失敗時は例外を投げる。"""
    entry = build_entry(slug, name, desc)
    source = path.read_text(encoding='utf-8')

    # 同じスラッグの行が既にあれば置き換える（説明文の変更に追従するため）
    existing = re.compile(
        r'^[ \t]*<li><a href="' + re.escape(slug) + r'/">.*?</li>[ \t]*$', re.M
    )
    if existing.search(source):
        # 置換文字列中のバックスラッシュが後方参照と誤解されないようエスケープ
        updated = existing.sub(entry.replace('\\', '\\\\'), source, count=1)
        action = '更新'
    else:
        block = re.search(r'(<h2>アプリ一覧</h2>\s*<ul>)(.*?)(\s*</ul>)', source, re.S)
        if not block:
            raise LookupError('アプリ一覧の <ul> が見つかりません')
        end_of_items = block.end(2)
        updated = source[:end_of_items] + '\n' + entry + source[end_of_items:]
        action = '追記'

    path.write_text(updated, encoding='utf-8')
    return action


def main() -> int:
    if len(sys.argv) < 5:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    slug, name, desc, path_str = sys.argv[1:5]
    path = pathlib.Path(path_str)
    entry = build_entry(slug, name, desc)

    if not path.exists():
        print(f'!! {path} が見つかりません。次の行を手動で追記してください:')
        print(entry)
        return 1
    try:
        action = update(slug, name, desc, path)
    except LookupError as e:
        print(f'!! {e}。次の行を手動で追記してください:')
        print(entry)
        return 1
    print(f'index.html のアプリ一覧を{action}しました')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
