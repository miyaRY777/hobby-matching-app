# スクロール・レイアウト統一設計

## 目的

全ページのスクロール方式を「ブラウザスクロール（body scroll）」に統一する。
テーブル一覧ページのみ、テーブル内スクロール（内側スクロールバー）を維持する。

## 背景

現状は `<main>` に `height: calc(100vh - 7rem); overflow-y: auto` が付いており、
`<main>` 内スクロールがデフォルトになっている。
これにより一部のページでコンテンツが切れたり、二重スクロールが発生していた。

## 設計方針

- **デフォルト：ブラウザスクロール**（`<main>` に高さ制約なし、body がスクロール）
- **例外：テーブルページ**は `content_for :fixed_main` で `<main>` に固定高さを付与し、テーブル内スクロールを維持

ナビバーは `position: fixed` のため、どのスクロール方式でも常に上部に固定される。

## 変更ファイル

| ファイル | 変更内容 |
|---|---|
| `app/views/layouts/application.html.erb` | `<main>` スタイルのロジックを反転。デフォルト＝body scroll、`content_for?(:fixed_main)` のときだけ固定高さ |
| `app/views/mypage/rooms/index.html.erb` | `<% content_for :fixed_main, true %>` を追加 |
| `app/views/rooms/index.html.erb` | `<% content_for :fixed_main, true %>` を追加 |
| `app/views/pages/guide.html.erb` | `<% content_for :body_scroll, true %>` を削除（不要） |

## 変更後の挙動

| ページ | スクロール方式 |
|---|---|
| ホーム・マイページ・プロフィール一覧・ガイド・利用規約・お問い合わせ等 | ブラウザスクロール |
| 部屋管理（`mypage/rooms/index`） | テーブル内スクロール |
| 公開部屋一覧（`rooms/index`） | テーブル内スクロール |

## `<main>` スタイルの変更イメージ

```diff
- "...#{content_for?(:body_scroll) ? '' : 'height: calc(100vh - 7rem); overflow-y: auto;'}"
+ "...#{content_for?(:fixed_main) ? 'height: calc(100vh - 7rem); overflow-y: hidden;' : ''}"
```

## テスト観点

- ホームページ・プロフィール編集・ガイド等でブラウザスクロールが動作すること
- 部屋管理・公開部屋一覧でテーブル横にスクロールバーが表示されること
- ナビバーが全ページで固定表示されること
- コンテンツが切れないこと（プロフィール編集の「更新する」ボタンが見えること）
