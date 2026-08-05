# タグカード復元system spec修正 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** バリデーションエラー後のタグカード復元を、画面サイズやスクロール位置に依存せず検証できるsystem specへ修正する。

**Architecture:** アプリケーションの復元処理は正常なため、本番コードは変更しない。既存system specの可視テキスト判定を、`data-testid='tag-card'`に対する画面外を含むDOM判定へ置き換える。

**Tech Stack:** Ruby on Rails、RSpec、Capybara、Selenium、Docker Compose

## Global Constraints

- 変更対象は `spec/system/my/profile_tag_autocomplete_spec.rb` の復元テストだけとする。
- アプリケーションコード、DB、公開APIは変更しない。
- 既存の未追跡ファイルや無関係なテストは変更・コミットしない。
- 確認コマンドは `docker compose exec web` 経由で実行する。

---

### Task 1: 画面外の復元タグカードをDOM上で検証する

**Files:**
- Modify: `spec/system/my/profile_tag_autocomplete_spec.rb:100-113`
- Test: `spec/system/my/profile_tag_autocomplete_spec.rb`

**Interfaces:**
- Consumes: `data-testid='tag-card'`を持つ復元済みタグカードのDOM
- Produces: タグ名「ゲーム」を含む復元カードを、可視領域外でも検証するsystem spec

- [ ] **Step 1: 現在のテストでREDを再確認する**

変更前の次の検証が、タグ名を可視テキストとして探すため失敗することを確認する。

```ruby
expect(page).to have_text("ゲーム")
```

Run:

```bash
docker compose exec web bundle exec rspec spec/system/my/profile_tag_autocomplete_spec.rb:100
```

Expected: FAIL。エラーに `However, it was found 1 time including non-visible text.` が含まれる。

- [ ] **Step 2: DOM上の復元カードを確認する最小修正を行う**

`spec/system/my/profile_tag_autocomplete_spec.rb` のタグ名確認を次へ置き換える。

```ruby
expect(page).to have_css(
  "[data-testid='tag-card']",
  text: "ゲーム",
  visible: :all
)
```

既存の説明開閉ボタン確認は、DOM上に復元されたボタンを確認するため変更しない。

- [ ] **Step 3: 対象system specでGREENを確認する**

Run:

```bash
docker compose exec web bundle exec rspec spec/system/my/profile_tag_autocomplete_spec.rb:100
```

Expected: `1 example, 0 failures`

- [ ] **Step 4: 関連system specを確認する**

Run:

```bash
docker compose exec web bundle exec rspec spec/system/my/profile_tag_autocomplete_spec.rb spec/system/my/profile_tag_description_spec.rb
```

Expected: すべて成功する。

- [ ] **Step 5: 全RSpecを確認する**

Run:

```bash
docker compose exec web bundle exec rspec
```

Expected: `586 examples, 0 failures`

- [ ] **Step 6: 静的解析と差分を確認する**

Run:

```bash
docker compose exec web bundle exec rubocop spec/system/my/profile_tag_autocomplete_spec.rb
git diff --check
git diff -- spec/system/my/profile_tag_autocomplete_spec.rb
```

Expected: RuboCop違反なし、空白エラーなし、変更は対象の期待値だけである。

- [ ] **Step 7: テスト修正をコミットする**

```bash
git add spec/system/my/profile_tag_autocomplete_spec.rb
git commit -m "test: 画面外の復元タグカードを検証 #290"
```

Expected: 対象RSpecファイル1件だけがコミットされる。
