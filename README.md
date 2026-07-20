# app-legal

自作iPhoneアプリの**プライバシーポリシー・利用規約・お問い合わせ**ページをまとめてGitHub Pagesで公開する中央リポジトリ。

- 公開URL: `https://turtle467.github.io/app-legal/<アプリ>/privacy.html`
- 運営者名・連絡先メールは `kit/config.json` に一度だけ書けば、全アプリで共有される。

## 新しいアプリのページを追加する

```bash
cd ~/app_develop/app-legal
./kit/new-app.sh <スラッグ> "<アプリ名>" "<説明文>" [アクセント色]
```

例:
```bash
./kit/new-app.sh myapp2 "マイアプリ2" "写真を整理するアプリ" "#3B82F6"
```

実行すると `myapp2/` フォルダにページが生成され、GitHubへpush・Pages公開まで自動で行われる。
完了後に表示されるURLを、アプリの `AppConfig` や App Store Connect に設定する。

### ルートのアプリ一覧について

ルート `index.html` の**アプリ一覧への追記は `new-app.sh` が自動で行う**(`kit/update-index.py`)。
手で足す必要はない。ここに載らないと
`https://turtle467.github.io/app-legal/` の一覧からたどれないアプリになるため、生成と同時に処理している。

- 同じスラッグで再実行すると、行が重複せずアプリ名・説明文が**更新**される。
- 一覧の `<ul>` が見つからない等で追記できなかった場合は、貼り付ける用の1行を表示して続行する。
  その場合だけ `index.html` に手で足して `git add -A && git commit && git push`。

一覧だけ直したいときは、単体でも実行できる:

```bash
python3 kit/update-index.py <スラッグ> "<アプリ名>" "<説明文>" index.html
```

## 運営者名・メールを変更する

`kit/config.json` を編集して、各アプリのページを再生成(`new-app.sh` を再実行)するか、
`<アプリ>/*.html` を直接編集して `git add -A && git commit && git push`。

## 位置情報など個別機能の記載

テンプレートは汎用の雛形。位置情報・写真・ヘルスケア等を扱うアプリは、
生成後の `<アプリ>/privacy.html` にその用途と停止方法を追記すること
(雛形内にコメントで追記位置を示してある)。

## 構成

```
app-legal/
├── kit/
│   ├── config.json        ← 共有の運営者情報(name/email/githubUser/repo)
│   ├── new-app.sh         ← 新アプリ生成＋公開コマンド
│   ├── update-index.py    ← ルートのアプリ一覧へ追記(new-app.shが自動で呼ぶ)
│   └── templates/         ← privacy/terms/index/style の雛形
├── delilog/               ← 各アプリのページ(公開される)
│   ├── privacy.html
│   ├── terms.html
│   ├── index.html
│   └── style.css
├── index.html             ← ルート(アプリ一覧)
└── .nojekyll
```
