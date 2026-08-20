# スクロール・レイアウト統一 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 全ページのスクロールをブラウザスクロールに統一し、テーブルページのみ内側スクロールを維持する。

**Architecture:** `<main>` のデフォルトを高さ制約なしに変更し、`content_for :fixed_main` を宣言したページだけ固定高さ（テーブル内スクロール用）を付与する。`content_for :body_scroll` は不要になるため削除する。

**Tech Stack:** Ruby on Rails 7, ERB, インラインスタイル

---

### Task 1: application.html.erb のスクロールロジックを反転

**Files:**
- Modify: `app/views/layouts/application.html.erb`

省略条件に該当（UIクラス変更のみ・ロジック・DB・認証に影響しない）のため TDD スキップ。ただし RuboCop は必ず実行。

- [ ] **Step 1: `<main>` スタイルを変更する**

`app/views/layouts/application.html.erb` の `<main>` タグの style 属性を以下のように変更する：

変更前：
```erb
style="<%= content_for?(:landing) ? '' : "margin-top: 7rem; position: relative; display: flex; flex-direction: column; #{content_for?(:body_scroll) ? '' : 'height: calc(100vh - 7rem); overflow-y: auto;'}" %>"
```

変更後：
```erb
style="<%= content_for?(:landing) ? '' : "margin-top: 7rem; position: relative; display: flex; flex-direction: column; #{content_for?(:fixed_main) ? 'height: calc(100vh - 7rem); overflow-y: hidden;' : ''}" %>"
```

- [ ] **Step 2: RuboCop を実行**

```bash
docker compose exec web bundle exec rubocop app/views/layouts/application.html.erb
```

Expected: no offenses

- [ ] **Step 3: ブラウザで動作確認**

以下のページでブラウザスクロールが動作することを確認：
- ホームページ（`/`）
- プロフィール編集（`/my/profile/edit`）
- 利用規約（`/terms`）

ナビバーが固定表示のままであること。

- [ ] **Step 4: コミット**

```bash
git add app/views/layouts/application.html.erb
git commit -m "refactor: デフォルトをブラウザスクロールに変更、fixed_mainフラグを追加"
```

---

### Task 2: テーブルページに content_for :fixed_main を追加

**Files:**
- Modify: `app/views/mypage/rooms/index.html.erb`
- Modify: `app/views/rooms/index.html.erb`

- [ ] **Step 1: mypage/rooms/index.html.erb に追加**

ファイル先頭を以下のように変更する：

変更前：
```erb
<% content_for :no_center, true %>

<div style="max-width: 72rem; ...
```

変更後：
```erb
<% content_for :no_center, true %>
<% content_for :fixed_main, true %>

<div style="max-width: 72rem; ...
```

- [ ] **Step 2: rooms/index.html.erb に追加**

ファイル先頭を以下のように変更する：

変更前：
```erb
<% content_for :no_center, true %>

<div style="max-width: 72rem; ...
```

変更後：
```erb
<% content_for :no_center, true %>
<% content_for :fixed_main, true %>

<div style="max-width: 72rem; ...
```

- [ ] **Step 3: ブラウザで動作確認**

以下のページでテーブル横にスクロールバーが表示されることを確認：
- 部屋管理（`/mypage/rooms`）
- 公開部屋一覧（`/rooms`）

- [ ] **Step 4: コミット**

```bash
git add app/views/mypage/rooms/index.html.erb app/views/rooms/index.html.erb
git commit -m "refactor: テーブルページにcontent_for :fixed_mainを追加"
```

---

### Task 3: guide.html.erb から不要な content_for :body_scroll を削除

**Files:**
- Modify: `app/views/pages/guide.html.erb`

- [ ] **Step 1: content_for :body_scroll を削除**

変更前：
```erb
<% content_for :no_center, "true" %>
<% content_for :full_width, true %>
<% content_for :body_scroll, true %>
```

変更後：
```erb
<% content_for :no_center, "true" %>
<% content_for :full_width, true %>
```

- [ ] **Step 2: ブラウザで動作確認**

使い方ガイド（`/guide`）でブラウザスクロールが動作することを確認。全 4 ステップとCTAが見えること。

- [ ] **Step 3: コミット**

```bash
git add app/views/pages/guide.html.erb
git commit -m "refactor: body_scrollフラグを削除（デフォルトがブラウザスクロールになったため不要）"
```

---

## 完了チェックリスト

- [ ] ホーム・プロフィール・ガイド等でブラウザスクロールが動作する
- [ ] 部屋管理・公開部屋一覧でテーブル内スクロールバーが表示される
- [ ] ナビバーが全ページで固定表示される
- [ ] プロフィール編集の「更新する」ボタンが切れずに表示される
- [ ] RuboCop がすべて通過する
