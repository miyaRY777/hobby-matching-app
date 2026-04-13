# メンバー詳細パネル改善 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `shares/show` 右側の詳細パネルを「初期状態は説明非表示・タブクリックで展開」に変更し、ひとことタブをアンバー系に差別化して全体サイズを縮小する。

**Architecture:** `tabs_controller.js` に `defaultOpen` バリューとトグル動作を追加し、既存の `_form.html.erb` への影響を防ぐ。`rooms/members/show.html.erb` に `data-tabs-default-open-value="false"` を指定し、ひとことタブをアンバー系スタイルに変更する。

**Tech Stack:** Stimulus (Hotwire), ERB, RSpec (system spec, js: true)

---

## 変更ファイル一覧

| ファイル | 変更内容 |
|---|---|
| `spec/system/rooms/member_detail_tag_toggle_spec.rb` | 仕様変更に合わせて既存テストを修正・新テストを追加 |
| `app/javascript/controllers/tabs_controller.js` | `defaultOpen` バリュー追加・トグル対応・amber テーマ対応 |
| `app/views/rooms/members/show.html.erb` | サイズ縮小・ひとことスタイル変更・defaultOpen=false 設定 |

---

## Task 1: System Spec を新仕様に更新（RED）

**Files:**
- Modify: `spec/system/rooms/member_detail_tag_toggle_spec.rb`

### 変更内容の概要

| 既存テスト | 対応 |
|---|---|
| `"ページを開くと自己紹介が表示される"` | 削除（新仕様と矛盾） |
| `"「詳細を見る」リンクが表示される"` | 変更なし |
| `"タブをクリックすると説明文が表示される"` | 変更なし |
| `"「ひとこと」タブをクリックすると自己紹介に戻る"` | 変更なし |
| `"タブをクリックすると「未入力」と表示される"` | 変更なし |

追加するテスト：
- `"ページを開いても説明エリアは表示されない"`
- `"「💬 ひとこと」タブをクリックすると自己紹介が表示される"`
- `"選択中のタブを再クリックすると説明エリアが非表示になる"`

- [ ] **Step 1: spec ファイルを修正する**

`spec/system/rooms/member_detail_tag_toggle_spec.rb` を以下の内容に書き換える：

```ruby
require "rails_helper"

RSpec.describe "部屋メンバー詳細タブ切り替え", type: :system, js: true do
  let(:viewer_user) { create(:user) }
  let(:member_user) { create(:user) }
  let!(:viewer_profile) { create(:profile, user: viewer_user) }
  let!(:member_profile) { create(:profile, user: member_user, bio: "メンバー自己紹介です") }
  let!(:game_parent_tag) { create(:parent_tag, room_type: :game) }
  let!(:room) { create(:room, issuer_profile: viewer_profile, room_type: :game) }
  let!(:hobby) do
    hobby = create(:hobby, name: "ゲーム")
    create(:hobby_parent_tag, hobby:, parent_tag: game_parent_tag)
    hobby
  end

  before do
    create(:room_membership, room:, profile: viewer_profile)
    create(:room_membership, room:, profile: member_profile)
    create(:profile_hobby, profile: member_profile, hobby:, description: "毎日やってます")
    login_as(viewer_user, scope: :user)
    visit room_member_path(room_id: room.id, id: member_profile.id)
  end

  it "「詳細を見る」リンクが表示される" do
    expect(page).to have_link("詳細を見る")
  end

  it "ページを開いても説明エリアは表示されない" do
    expect(page).not_to have_text("メンバー自己紹介です")
  end

  it "「💬 ひとこと」タブをクリックすると自己紹介が表示される" do
    find("[data-tabs-target='tab']", text: "ひとこと").click
    expect(page).to have_text("メンバー自己紹介です")
  end

  it "選択中のタブを再クリックすると説明エリアが非表示になる" do
    find("[data-tabs-target='tab']", text: "ひとこと").click
    expect(page).to have_text("メンバー自己紹介です")

    find("[data-tabs-target='tab']", text: "ひとこと").click
    expect(page).not_to have_text("メンバー自己紹介です")
  end

  it "タブをクリックすると説明文が表示される" do
    find("[data-tabs-target='tab']", text: "ゲーム").click
    expect(page).to have_text("毎日やってます")
  end

  it "「ひとこと」タブをクリックすると自己紹介に戻る" do
    find("[data-tabs-target='tab']", text: "ゲーム").click
    expect(page).to have_text("毎日やってます")

    find("[data-tabs-target='tab']", text: "ひとこと").click
    expect(page).to have_text("メンバー自己紹介です")
    expect(page).to have_css("[data-tabs-target='panel'].hidden", text: "毎日やってます", visible: false)
  end

  context "説明文が未入力のタブがある場合" do
    let!(:hobby2) do
      hobby = create(:hobby, name: "釣り")
      create(:hobby_parent_tag, hobby:, parent_tag: game_parent_tag)
      hobby
    end

    before do
      create(:profile_hobby, profile: member_profile, hobby: hobby2, description: nil)
      visit room_member_path(room_id: room.id, id: member_profile.id)
    end

    it "タブをクリックすると「未入力」と表示される" do
      find("[data-tabs-target='tab']", text: "釣り").click
      expect(page).to have_text("未入力")
    end
  end
end
```

- [ ] **Step 2: spec を実行して RED を確認する**

```bash
docker compose exec web bundle exec rspec spec/system/rooms/member_detail_tag_toggle_spec.rb --format documentation
```

期待される結果：
- `"ページを開いても説明エリアは表示されない"` → FAIL（現在は表示される）
- `"「💬 ひとこと」タブをクリックすると自己紹介が表示される"` → PASS（すでに動く）または FAIL（💬がないと）
- `"選択中のタブを再クリックすると説明エリアが非表示になる"` → FAIL（トグル未実装）

- [ ] **Step 3: コミット**

```bash
git add spec/system/rooms/member_detail_tag_toggle_spec.rb
git commit -m "test: メンバー詳細パネルの新仕様に合わせてsystem specを更新 (RED)"
```

---

## Task 2: tabs_controller.js を更新（GREEN その1）

**Files:**
- Modify: `app/javascript/controllers/tabs_controller.js`

- [ ] **Step 1: tabs_controller.js を以下の内容に書き換える**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { defaultOpen: { type: Boolean, default: true } }

  connect() {
    this.activeIndex = null
    if (this.defaultOpenValue) {
      this.activate(0)
    } else {
      this.panelTargets.forEach(p => p.classList.add("hidden"))
      this._resetAllTabs()
    }
  }

  switch(event) {
    const index = this.tabTargets.indexOf(event.currentTarget)
    if (this.activeIndex === index) {
      this.deactivate()
    } else {
      this.activate(index)
    }
  }

  activate(index) {
    this.activeIndex = index
    this._resetAllTabs()
    const tab = this.tabTargets[index]
    if (tab.dataset.tabsTheme === "amber") {
      tab.style.background = "linear-gradient(135deg, #d97706, #b45309)"
    } else {
      tab.style.background = "linear-gradient(135deg, #2563eb, #1d4ed8)"
    }
    tab.style.color = "#ffffff"
    tab.style.borderColor = "transparent"
    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index)
    })
  }

  deactivate() {
    this.activeIndex = null
    this.panelTargets.forEach(p => p.classList.add("hidden"))
    this._resetAllTabs()
  }

  _resetAllTabs() {
    this.tabTargets.forEach(tab => {
      if (tab.dataset.tabsTheme === "amber") {
        tab.style.background = "rgba(251, 191, 36, 0.12)"
        tab.style.color = "#fbbf24"
        tab.style.borderColor = "#fbbf24"
      } else {
        tab.style.background = "rgba(96, 165, 250, 0.15)"
        tab.style.color = "#60a5fa"
        tab.style.borderColor = "rgba(96, 165, 250, 0.4)"
      }
    })
  }
}
```

- [ ] **Step 2: spec を実行して進捗確認**

```bash
docker compose exec web bundle exec rspec spec/system/rooms/member_detail_tag_toggle_spec.rb --format documentation
```

この時点ではまだ `rooms/members/show.html.erb` を変更していないため、`"ページを開いても説明エリアは表示されない"` と `"選択中のタブを再クリックすると説明エリアが非表示になる"` は引き続き FAIL。

- [ ] **Step 3: コミット**

```bash
git add app/javascript/controllers/tabs_controller.js
git commit -m "feat: tabs_controller に defaultOpen バリューとトグル動作を追加"
```

---

## Task 3: rooms/members/show.html.erb を更新（GREEN その2）

**Files:**
- Modify: `app/views/rooms/members/show.html.erb`

- [ ] **Step 1: rooms/members/show.html.erb を以下の内容に書き換える**

```erb
<turbo-frame id="member_detail">
  <div style="padding: 1rem; border-radius: 1rem; background: linear-gradient(180deg, rgba(28, 32, 48, 0.98), rgba(24, 27, 44, 0.96)); border: 1px solid rgba(71, 85, 105, 0.45); box-shadow: 0 24px 60px rgba(2, 6, 23, 0.28);">

    <%# アバター + ユーザー名 %>
    <div style="display: flex; align-items: center; gap: 0.75rem; margin-bottom: 1rem;">
      <%= avatar_image_tag(@profile.user, size: :small) %>
      <p style="font-size: 0.95rem; font-weight: 700; color: #ffffff;">
        <%= @profile.user.nickname.presence || "no-name" %>
      </p>
    </div>

    <%# タブ %>
    <div data-controller="tabs" data-tabs-default-open-value="false">

      <%# タブボタン群 %>
      <div style="display: flex; flex-wrap: wrap; gap: 0.5rem; margin-bottom: 0.75rem; padding-bottom: 0.5rem; border-bottom: 1px solid rgba(55, 65, 81, 0.4);">
        <button type="button"
                data-tabs-target="tab"
                data-action="click->tabs#switch"
                data-tabs-theme="amber"
                style="font-size: 0.75rem; padding: 0.25rem 0.65rem; border-radius: 9999px; cursor: pointer; border: 1px solid #fbbf24; color: #fbbf24; background: rgba(251, 191, 36, 0.12); transition: background 0.2s;">
          💬 ひとこと
        </button>
        <% @room_related_phs.each do |ph| %>
          <button type="button"
                  data-tabs-target="tab"
                  data-action="click->tabs#switch"
                  style="font-size: 0.75rem; padding: 0.25rem 0.65rem; border-radius: 9999px; cursor: pointer; border: 1px solid rgba(96, 165, 250, 0.35); color: #93c5fd; background: rgba(37, 99, 235, 0.18); transition: background 0.2s;">
            <%= ph.hobby.name %>
          </button>
        <% end %>
      </div>

      <%# パネル群 %>
      <div data-tabs-target="panel"
           class="hidden"
           style="min-height: 6rem; font-size: 0.875rem; line-height: 1.8; color: #d1d5db; white-space: pre-line; word-break: break-word;">
        <%= @profile.bio.presence || "未入力" %>
      </div>
      <% @room_related_phs.each do |ph| %>
        <div data-tabs-target="panel"
             class="hidden"
             style="min-height: 6rem; font-size: 0.875rem; line-height: 1.8; color: #d1d5db; white-space: pre-line; word-break: break-word;">
          <%= ph.description.presence || "未入力" %>
        </div>
      <% end %>
    </div>

    <%# 詳細を見るリンク %>
    <div style="margin-top: 1rem; text-align: right;">
      <%= link_to "詳細を見る", profile_path(@profile),
            style: "font-size: 0.875rem; font-weight: 600; color: #60a5fa; text-decoration: none;" %>
    </div>
  </div>
</turbo-frame>
```

主な変更点：
- `data-tabs-default-open-value="false"` を追加
- ひとこと button に `data-tabs-theme="amber"` と amber スタイルを追加
- ひとこと button テキストを `💬 ひとこと` に変更
- **bio パネルに `class="hidden"` を追加**（これが必須。以前は hidden なしだった）
- padding: `1.5rem → 1rem`
- border-radius: `1.5rem → 1rem`
- ユーザー名 font-size: `1.1rem → 0.95rem`
- タブ font-size: `0.8rem → 0.75rem`、padding: `0.35rem 0.85rem → 0.25rem 0.65rem`
- パネル min-height: `8rem → 6rem`、font-size: `0.95rem → 0.875rem`
- margin-bottom: `1.5rem → 1rem`

- [ ] **Step 2: spec を実行して GREEN を確認する**

```bash
docker compose exec web bundle exec rspec spec/system/rooms/member_detail_tag_toggle_spec.rb --format documentation
```

期待される結果：全テスト PASS

- [ ] **Step 3: 全 spec を実行してリグレッションがないか確認する**

```bash
docker compose exec web bundle exec rspec --format progress
```

期待される結果：既存のテスト（`_form.html.erb` 利用箇所含む）が引き続き PASS

- [ ] **Step 4: コミット**

```bash
git add app/views/rooms/members/show.html.erb
git commit -m "feat: メンバー詳細パネルのサイズ縮小・ひとことタブのアンバー差別化・初期表示を非表示に変更"
```

---

## Task 4: REFACTOR

**Files:**
- No file changes expected（UIのみの変更のため大きなリファクタは不要）

- [ ] **Step 1: RuboCop を実行する**

```bash
docker compose exec web bundle exec rubocop app/views/rooms/members/show.html.erb
```

期待される結果：no offenses detected（ERB は対象外の場合はスキップされる）

- [ ] **Step 2: rails-reviewer サブエージェントを実行する**

変更した2ファイルをサブエージェントで確認する：
- `app/javascript/controllers/tabs_controller.js`
- `app/views/rooms/members/show.html.erb`

指摘があれば対応する。

- [ ] **Step 3: ブラウザで動作確認する**

以下を手動で確認する：
1. `shares/show` にアクセスし、マインドマップからメンバーを選択
2. 詳細パネルが表示される → 説明エリアが非表示であること
3. `💬 ひとこと` タブがアンバー色で表示されること
4. `💬 ひとこと` クリック → 自己紹介が表示されること
5. 再クリック → 説明エリアが非表示になること
6. 趣味タブクリック → 説明が表示されること（青ハイライト）
7. `my/profiles` の編集フォームでタブが正常に動作すること（defaultOpen が true のまま）

- [ ] **Step 4: PR 前の最終確認**

```bash
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rubocop
```

期待される結果：全テスト PASS、RuboCop offenses なし
