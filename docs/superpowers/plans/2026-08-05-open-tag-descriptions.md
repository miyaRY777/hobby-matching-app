# タグ説明欄を初期表示で開く Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** プロフィール編集画面で既存タグと新規タグの説明欄を最初から開き、ボタン文言で次の開閉操作を明示する。

**Architecture:** 既存の `tag-description` Stimulus コントローラを表示状態の唯一の管理箇所として維持する。タグカード生成時は説明欄を開いて描画し、ボタン操作時は同じカード内の `hidden` とボタン文言を同期して切り替える。

**Tech Stack:** Ruby on Rails、Hotwire Stimulus、RSpec system specs、Capybara、Docker Compose

## Global Constraints

- 既存タグと新規タグの説明欄を、説明の有無にかかわらず最初から開く。
- 開いている状態のボタン文言は「説明を閉じる」、閉じている状態は「説明を開く」とする。
- 説明文は任意入力のままとし、DB、モデル、保存サービスを変更しない。
- プロフィール表示画面のタグ開閉動作を変更しない。
- 確認系コマンドは `docker compose exec web` 経由を優先する。
- RED → GREEN → REFACTOR の順で進める。

---

### Task 1: タグ説明欄の初期表示と開閉文言を同期する

**Files:**
- Modify: `spec/system/my/profile_tag_description_spec.rb:12-96`
- Modify: `app/javascript/controllers/tag_description_controller.js:9-16,75-96`

**Interfaces:**
- Consumes: `chips-changed` イベントの `event.detail.chips` と、既存の `[data-description-content]`、`[data-testid='description-toggle']` DOM属性。
- Produces: タグ生成直後は表示された説明欄と「説明を閉じる」ボタンを持つカード。`onToggle(event)` はクリック対象カードだけを切り替え、閉じた後は「説明を開く」、再び開いた後は「説明を閉じる」と表示する。

- [ ] **Step 1: 新規タグと既存タグの初期表示、および開閉文言の失敗するテストを書く**

`spec/system/my/profile_tag_description_spec.rb` の「説明文入力欄の表示」を、初期表示と2回の切り替えを検証する内容へ更新する。

```ruby
it "新規タグ追加直後から説明文入力欄が表示される" do
  fill_in "tag-input", with: "ゲーム"
  find("[data-testid='skip-parent-tag']").click

  expect(page).to have_css("[data-testid='description-input']")
  expect(page).to have_button("説明を閉じる")
end

it "既存タグも説明文入力欄が開いた状態で復元される" do
  hobby = create(:hobby, name: "ゲーム")
  create(:profile_hobby, profile: current_profile, hobby:, description: "毎日遊びます")
  visit edit_my_profile_path
  click_on "タグ"

  expect(find("[data-testid='description-input']").value).to eq("毎日遊びます")
  expect(page).to have_button("説明を閉じる")
end

it "ボタンで説明文入力欄と文言を交互に切り替える" do
  fill_in "tag-input", with: "ゲーム"
  find("[data-testid='skip-parent-tag']").click

  click_button "説明を閉じる"
  expect(page).not_to have_css("[data-testid='description-input']")
  expect(page).to have_button("説明を開く")

  click_button "説明を開く"
  expect(page).to have_css("[data-testid='description-input']")
  expect(page).to have_button("説明を閉じる")
end
```

既存の保存テストとTurbo再表示テストでは、初期状態ですでに開いているため、説明入力前の `find("[data-testid='description-toggle']").click` を削除する。タグ削除テストは維持する。

- [ ] **Step 2: 対象スペックを実行し、現行実装で失敗することを確認する**

Run:

```bash
docker compose exec web bundle exec rspec spec/system/my/profile_tag_description_spec.rb
```

Expected: FAIL。新規・既存カードの説明欄が `hidden` のため見つからず、初期ボタン文言も「説明を追加」のため一致しない。

- [ ] **Step 3: 説明欄を開いて生成し、表示状態とボタン文言を同期する最小実装を書く**

`app/javascript/controllers/tag_description_controller.js` の `onToggle` を次のように更新する。

```javascript
onToggle(event) {
  const button = event.currentTarget
  const content = button.closest("[data-testid='tag-card']")
                        ?.querySelector("[data-description-content]")
  if (!content) return

  const isHidden = content.classList.toggle("hidden")
  button.textContent = isHidden ? "説明を開く" : "説明を閉じる"
}
```

カード生成テンプレートのボタン文言を変更し、説明欄から初期 `hidden` を外す。

```html
<button type="button"
        data-action="click->tag-description#onToggle"
        data-testid="description-toggle"
        class="shrink-0 border-none cursor-pointer"
        style="display:inline-flex;align-items:center;justify-content:center;white-space:nowrap;line-height:1.2;padding:0.35rem 0.7rem;border-radius:9999px;background:rgba(59,130,246,0.14);color:#bfdbfe;border:1px solid rgba(96,165,250,0.22);font-size:0.75rem;font-weight:600;">説明を閉じる</button>

<div data-description-content class="border-t border-slate-700/60 px-4 pb-4 pt-4">
```

- [ ] **Step 4: 対象スペックを再実行し、通過を確認する**

Run:

```bash
docker compose exec web bundle exec rspec spec/system/my/profile_tag_description_spec.rb
```

Expected: PASS。新規・既存タグの初期表示、開閉文言、保存、タグ削除、Turbo再表示の全例が成功する。

- [ ] **Step 5: 関連するプロフィールタグの回帰テストを実行する**

Run:

```bash
docker compose exec web bundle exec rspec spec/system/my/profile_tag_autocomplete_spec.rb spec/system/my/profile_tag_description_spec.rb
```

Expected: PASS。タグ候補、最大10件、親タグ表示、説明入力と削除の既存挙動に回帰がない。

- [ ] **Step 6: RuboCop と差分チェックを実行する**

Run:

```bash
docker compose exec web bundle exec rubocop spec/system/my/profile_tag_description_spec.rb
git diff --check
```

Expected: 両方とも終了コード0。RuboCop違反と空白エラーがない。

- [ ] **Step 7: 実装差分だけをコミットする**

```bash
git add -- app/javascript/controllers/tag_description_controller.js spec/system/my/profile_tag_description_spec.rb
git commit -m "feat: タグ説明欄を初期表示で開く #288"
```
