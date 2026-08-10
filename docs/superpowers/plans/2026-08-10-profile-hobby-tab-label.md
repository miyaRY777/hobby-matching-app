# プロフィール編集の趣味タブ文言変更 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** プロフィール編集画面のタブ名を「タグ」から「趣味」へ変更し、表示名に依存するシステムテストを追従させる。

**Architecture:** 既存のERBとCapybaraシステムテストの表示文言だけを変更する。Stimulus、モデル、コントローラ、DB、公開APIの挙動は変更しない。

**Tech Stack:** Ruby on Rails、ERB、RSpec、Capybara、Docker Compose

## Global Constraints

- タブ以外の「趣味タグ」「親タグ」などの文言は変更しない。
- 趣味タグの登録・削除・説明入力の挙動は変更しない。
- DB、モデル、コントローラ、公開APIは変更しない。
- 確認コマンドは `docker compose exec web` 経由を優先する。
- ユーザー作成の無関係な未追跡ファイルには触れない。

---

### Task 1: 趣味タブ表示とシステムテストを一致させる

**Files:**
- Modify: `app/views/my/profiles/_form.html.erb:30`
- Modify: `spec/system/profile_hobbies_flow_spec.rb:10`
- Modify: `spec/system/my/profile_tag_classification_spec.rb:11`
- Modify: `spec/system/my/profile_tag_help_spec.rb:10`
- Modify: `spec/system/my/profile_tag_autocomplete_spec.rb:8-11,109-110`
- Modify: `spec/system/my/profile_tag_description_spec.rb:13-128`
- Modify: `spec/system/my/profile_tabs_spec.rb:32-41`

**Interfaces:**
- Consumes: プロフィール編集画面の `[data-tabs-target='tab']` タブ切り替えUI
- Produces: 表示名が「趣味」のタブと、その表示名を使って操作できるCapybaraシステムテスト

- [ ] **Step 1: 現在の変更に対して既存テストがREDになることを確認する**

Run:

```bash
docker compose exec web bundle exec rspec \
  spec/system/profile_hobbies_flow_spec.rb \
  spec/system/my/profile_tag_classification_spec.rb \
  spec/system/my/profile_tag_help_spec.rb \
  spec/system/my/profile_tag_autocomplete_spec.rb \
  spec/system/my/profile_tag_description_spec.rb \
  spec/system/my/profile_tabs_spec.rb
```

Expected: `click_on "タグ"` がボタンを見つけられずFAILし、表示名変更が既存テストで検出される。

- [ ] **Step 2: 表示名に依存するテストを「趣味」に変更する**

各対象ファイルの操作を次のように変更する。

```ruby
click_on "趣味"
```

テスト名とコメントの「タグタブ」は「趣味タブ」へ変更する。「タグ入力」「タグパネル」「趣味タグ」など、機能自体を指す語は変更しない。

- [ ] **Step 3: 対象テストがGREENになることを確認する**

Run:

```bash
docker compose exec web bundle exec rspec \
  spec/system/profile_hobbies_flow_spec.rb \
  spec/system/my/profile_tag_classification_spec.rb \
  spec/system/my/profile_tag_help_spec.rb \
  spec/system/my/profile_tag_autocomplete_spec.rb \
  spec/system/my/profile_tag_description_spec.rb \
  spec/system/my/profile_tabs_spec.rb
```

Expected: 対象テストがすべてPASSする。

- [ ] **Step 4: 全体検証を行う**

Run:

```bash
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rubocop
git diff --check
```

Expected: RSpecは0 failures、RuboCopは0 offenses、`git diff --check`は出力なしで終了する。

- [ ] **Step 5: Issue #292の実装変更だけをコミットする**

コミット対象を次の7ファイルに限定する。

```bash
git add app/views/my/profiles/_form.html.erb \
  spec/system/profile_hobbies_flow_spec.rb \
  spec/system/my/profile_tag_classification_spec.rb \
  spec/system/my/profile_tag_help_spec.rb \
  spec/system/my/profile_tag_autocomplete_spec.rb \
  spec/system/my/profile_tag_description_spec.rb \
  spec/system/my/profile_tabs_spec.rb
git commit -m "fix: プロフィール編集のタグタブを趣味へ変更 #292"
```

Expected: 無関係な未追跡ファイルを含まず、表示文言と対応テストだけがコミットされる。
