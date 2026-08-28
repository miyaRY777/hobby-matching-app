# 新規趣味タグの即カード化と追加後カテゴリー Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新規趣味タグを既存タグと同じ「確定したらすぐカード」にし、分類は載ったあとの新規カード上だけで任意にできるようにする。

**Architecture:** 名前の確定は `tag_autocomplete_controller.js`。カード描画とカテゴリー UI は `tag_description_controller.js`。submit 契約は hidden `hobbies_json`。サーバーの `ProfileHobbiesUpdater.classify_if_newly_created`（`previously_new_record?`）は変えない。`is_new` は hidden JSON とカード描画専用で、DB カラムにしない。

**Tech Stack:** Ruby on Rails、Hotwire Stimulus、RSpec system spec（js: true）、Capybara / Selenium、Docker Compose

## Global Constraints

- 作業ブランチは `feature/305-profile-new-tag-immediate-chip`。Issue は #305。
- 第1段が通るまで第2段のコードを書かない。
- マイグレーションなし。`is_new` をカラムにしない。
- `classify_if_newly_created` の判定を変えない。サーバーは `is_new` を無視する。
- 既存 Hobby（未分類含む）をユーザーが分類し直さない。
- 管理用 `ParentTag slug: uncategorized` をユーザー操作で付けない。未選択は `parent_tag_id` なし＝`HobbyParentTag` なし。
- マインドマップの「その他」は変更しない。
- 「親タグとは？」ヘルプ本文は対象外。`spec/system/mypage/profile_tag_help_spec.rb` の「わからない」期待を変えない。
- 確認コマンドは `docker compose exec web` 経由。
- RED → GREEN → REFACTOR。コミットメッセージは prefix 英語、説明は日本語。`git add .` は使わない。
- 推測で仕様を足さない。分岐したら止まる。

## File Structure

| ファイル | 責務 |
|---|---|
| `app/javascript/controllers/tag_autocomplete_controller.js` | 入力・候補・chip 配列・hidden JSON。第1段で即カード。第2段で `is_new` と `parent_tag_id` の同期・復元 |
| `app/javascript/controllers/tag_description_controller.js` | tag-card 描画。第2段で `is_new` カードにカテゴリー開閉 |
| `app/views/mypage/profiles/_form.html.erb` | 第2段で `tag-category-update` を data-action に足す |
| `spec/support/tag_input_helpers.rb` | system spec 用 `add_new_hobby_tag` |
| `spec/system/mypage/profile_tag_autocomplete_spec.rb` | 即カードの確定操作 |
| `spec/system/mypage/profile_tag_classification_spec.rb` | 第1段は門 UI 削除。第2段はカード上カテゴリー |
| `spec/system/mypage/profile_tag_description_spec.rb` | 追加操作を `add_new_hobby_tag` に置換。第2段で新規カードの「未分類」期待を「カテゴリー」に合わせる |
| `spec/system/profile_hobbies_flow_spec.rb` | 追加操作の置換のみ |

触らない: `app/services/profile_hobbies_updater.rb`、`spec/services/profile_hobbies_updater_spec.rb`、`spec/requests/mypage/profile_spec.rb`、`spec/system/mypage/profile_tag_help_spec.rb`、`app/services/jsmind_data_builder.rb`

---

### Task 1: 第1段 RED — 追加操作を即カード前提の spec に書き換える

**Files:**
- Create: `spec/support/tag_input_helpers.rb`
- Modify: `spec/rails_helper.rb`（`TagInputHelpers` を system spec に include）
- Modify: `spec/system/mypage/profile_tag_autocomplete_spec.rb`
- Modify: `spec/system/mypage/profile_tag_classification_spec.rb`
- Modify: `spec/system/mypage/profile_tag_description_spec.rb`
- Modify: `spec/system/profile_hobbies_flow_spec.rb`

**Interfaces:**
- Consumes: 既存の `fill_in "tag-input"`、`[data-testid='tag-input']`、`[data-testid='tag-card']`。
- Produces: `add_new_hobby_tag(name)`。`fill_in "tag-input", with: name` のあと `[data-testid='new-tag-add-row']` をクリックする。Capybara の find 待ちで、候補なし fetch 後の1行をクリックできる。
- Produces: 第1段の分類 spec は「追加行が出る」「即カードは未分類」。親タグを選んで保存する例は第2段まで書かない（今の例を削除する）。

- [ ] **Step 1: helper を追加し、skip-parent-tag 依存を書き換える**

`spec/support/tag_input_helpers.rb`:

```ruby
module TagInputHelpers
  def add_new_hobby_tag(name)
    fill_in "tag-input", with: name
    find("[data-testid='new-tag-add-row']").click
  end
end
```

`spec/rails_helper.rb` の `config.include Devise::Test::IntegrationHelpers` の近くへ:

```ruby
config.include TagInputHelpers, type: :system
```

次をすべて `find("[data-testid='skip-parent-tag']").click` から `add_new_hobby_tag("...")` に置換する（`fill_in` と click が二重にならないよう、fill_in 行は helper に任せる）。

- `spec/system/mypage/profile_tag_autocomplete_spec.rb`
- `spec/system/mypage/profile_tag_description_spec.rb`
- `spec/system/profile_hobbies_flow_spec.rb`

autocomplete spec の「新規タグを追加セクションから説明カードとして追加できる」は例名を「候補がないタグは追加行クリックで即カードになる」に変え、次を足す。

```ruby
it "候補がないタグは追加行クリックで即カードになる" do
  add_new_hobby_tag("ゲーム")

  expect(page).to have_css("[data-testid='tag-child-chip']", text: "ゲーム")
  expect(page).to have_css("[data-testid='tag-parent-label']", text: "未分類")
  expect(page).to have_no_button("わからない")
  expect(page).to have_no_button("追加する")
  expect(page).to have_no_css("[data-testid='new-tag-parent-select']")
end

it "候補を選んでいない状態で Enter すると即カードになる" do
  fill_in "tag-input", with: "ボードゲーム"
  find("[data-testid='tag-input']").send_keys(:enter)

  expect(page).to have_css("[data-testid='tag-child-chip']", text: "ボードゲーム")
  expect(find("[data-testid='tag-input']").value).to eq("")
end

it "2文字以上入力しただけではカードが増えない" do
  fill_in "tag-input", with: "ゲーム"

  expect(page).to have_css("[data-testid='new-tag-add-row']")
  expect(page).to have_no_css("[data-testid='tag-card']")
end
```

`profile_tag_classification_spec.rb` の `describe "新規タグの親タグ選択"` を次で置き換える。既存タグのバッジ describe は維持する。

```ruby
describe "新規タグの即カード" do
  it "候補にないタグでは追加行だけが出て、分類フォームは出ない" do
    fill_in "tag-input", with: "新作ゲームタグ"

    expect(page).to have_css("[data-testid='new-tag-add-row']", text: "新作ゲームタグ")
    expect(page).to have_no_button("わからない")
    expect(page).to have_no_button("追加する")
    expect(page).to have_no_css("[data-testid='new-tag-parent-select']")
  end

  it "追加行をクリックすると未分類のカードがすぐ出る" do
    add_new_hobby_tag("新作ゲームタグ")

    expect(page).to have_css("[data-testid='tag-parent-label']", text: "未分類")
    expect(page).to have_css("[data-testid='tag-child-chip']", text: "新作ゲームタグ")
  end

  it "未分類のまま保存すると HobbyParentTag は付かない" do
    add_new_hobby_tag("未分類タグ")
    click_button "更新する"

    expect(page).to have_current_path(profile_path(current_profile))
    hobby = Hobby.find_by(normalized_name: "未分類タグ")
    expect(hobby.hobby_parent_tags).to be_empty
  end
end
```

- [ ] **Step 2: 対象 spec を実行し、現行実装で失敗することを確認する**

Run:

```bash
docker compose exec web bundle exec rspec \
  spec/system/mypage/profile_tag_autocomplete_spec.rb \
  spec/system/mypage/profile_tag_classification_spec.rb \
  spec/system/mypage/profile_tag_description_spec.rb \
  spec/system/profile_hobbies_flow_spec.rb
```

Expected: FAIL。`new-tag-add-row` が無く、`skip-parent-tag` / 「わからない」がまだ出る。

- [ ] **Step 3: この Task では実装コードを書かない。失敗を確認したら Task 2 へ進む**

---

### Task 2: 第1段 GREEN — 確定したらすぐカードにする

**Files:**
- Modify: `app/javascript/controllers/tag_autocomplete_controller.js`

**Interfaces:**
- Consumes: 既存の `#addChip(name, description, parentTagId, parentTagName)`、`#fetchSuggestions`、`#selectExistingTag`。
- Produces: `confirmNewTagRow(event)` 公開アクション。入力中の名前で `#confirmNewName(query)` を呼ぶ。
- Produces: `#confirmNewName(query)` は `#addChip(query)` のあと入力を空にし `#closeDropdown()` する。この段では `is_new` を付けない。
- Produces: `#renderNewTagAddRow(query)` は `[data-testid='new-tag-add-row']` の1行だけ。文言は `「{query}」を新しいタグとして追加`。
- Produces: `onInput` は `#triggerNewTagFlow` を呼ばない。2文字未満で閉じ、2文字以上は debounce 300ms で `#fetchSuggestions` のみ。
- Produces: `#fetchSuggestions` は候補ありなら `#renderDropdown`、空なら `#renderNewTagAddRow(query)`。
- Produces: Enter はハイライト中の `autocomplete-item` があれば既存選択。なければ入力中文字列で `#confirmNewName`。
- 削除: `confirmNewTag`、`skipParentTag`、`#renderNewTagUI`、`#pendingNewTag`、`#triggerNewTagFlow`。`ROOM_TYPE_LABELS` はこの段では未使用になるので削除する（第2段で description 側に置く）。

- [ ] **Step 1: autocomplete JS を即カードに最小変更する**

`onInput` を次にする。

```javascript
onInput() {
  clearTimeout(this.#debounceTimer)
  const q = this.inputTarget.value.trim()
  if (q.length < 2) {
    this.#closeDropdown()
    return
  }

  this.#debounceTimer = setTimeout(() => this.#fetchSuggestions(q), 300)
}
```

Enter の else を `#confirmNewName(q)` にする。`#closeDropdown` から `#pendingNewTag` を外す。フィールド `#pendingNewTag` を削除する。

公開メソッドと private を次で置き換える。

```javascript
confirmNewTagRow() {
  const query = this.inputTarget.value.trim()
  if (query) this.#confirmNewName(query)
}

#confirmNewName(query) {
  this.#addChip(query)
  this.inputTarget.value = ""
  this.#closeDropdown()
}

#renderNewTagAddRow(query) {
  this.dropdownTarget.innerHTML = `
    <li data-testid="new-tag-add-row"
        class="autocomplete-item"
        data-action="click->tag-autocomplete#confirmNewTagRow">
      「${this.#escapeHtml(query)}」を新しいタグとして追加
    </li>
  `
  this.dropdownTarget.classList.remove("hidden")
}
```

`#fetchSuggestions` の空配列分岐を `this.#renderNewTagAddRow(query)` にする。`confirmNewTag` / `skipParentTag` / `#triggerNewTagFlow` / `#renderNewTagUI` / `ROOM_TYPE_LABELS` を削除する。`#addChip` のシグネチャはこの段では変えない。

- [ ] **Step 2: Task 1 と同じ spec を実行し、通ることを確認する**

Run:

```bash
docker compose exec web bundle exec rspec \
  spec/system/mypage/profile_tag_autocomplete_spec.rb \
  spec/system/mypage/profile_tag_classification_spec.rb \
  spec/system/mypage/profile_tag_description_spec.rb \
  spec/system/profile_hobbies_flow_spec.rb
```

Expected: PASS

- [ ] **Step 3: ヘルプ spec がまだ通ることを確認する（「わからない」はヘルプ内の文言）**

Run:

```bash
docker compose exec web bundle exec rspec spec/system/mypage/profile_tag_help_spec.rb
```

Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add spec/support/tag_input_helpers.rb spec/rails_helper.rb \
  spec/system/mypage/profile_tag_autocomplete_spec.rb \
  spec/system/mypage/profile_tag_classification_spec.rb \
  spec/system/mypage/profile_tag_description_spec.rb \
  spec/system/profile_hobbies_flow_spec.rb \
  app/javascript/controllers/tag_autocomplete_controller.js
git commit -m "$(cat <<'EOF'
feat: 新規趣味タグを確定したらすぐカードにする #305

分類 UI を追加の門にしない。候補なしは追加行、Enter でも即カードにする。
EOF
)"
```

---

### Task 3: 第2段 RED — 新規カード上のカテゴリー開閉を spec にする

**Files:**
- Modify: `spec/system/mypage/profile_tag_classification_spec.rb`

**Interfaces:**
- Consumes: Task 1 の `add_new_hobby_tag`。`let!(:fps)` の ParentTag。
- Produces: 新規カードは `[data-testid='tag-category-trigger']`（未選択時テキストは `カテゴリー`）。既存カードは今どおり `[data-testid='tag-parent-label']`。
- Produces: 開いたパネルは `[data-testid='tag-category-panel']`。固定文言2行と `[data-testid='tag-category-option']`。
- Produces: 既存パスのカードに `tag-category-trigger` は出ない。

- [ ] **Step 1: 分類 spec にカード上カテゴリーの例を追加する**

`describe "新規タグの即カード"` のあとに次を足す。即カードの3例は残す。

```ruby
describe "新規カードのカテゴリー" do
  it "新規カードにカテゴリー開閉が出て、説明文がパネル内にある" do
    add_new_hobby_tag("新作ゲームタグ")
    find("[data-testid='tag-category-trigger']").click

    expect(page).to have_css("[data-testid='tag-category-panel']")
    expect(page).to have_text("近いカテゴリーを選ぶと、マインドマップ上で同じ趣味の人とまとまって表示されやすくなります。")
    expect(page).to have_text("迷ったら、選ばなくても大丈夫です。")
    expect(page).to have_text("ゲーム系")
    expect(page).to have_css("[data-testid='tag-category-option']", text: "FPS")
    expect(page).to have_no_text("管理者にお問い合わせ")
    expect(page).to have_no_button("わからない")
  end

  it "カテゴリーを選んで保存すると HobbyParentTag が付く" do
    add_new_hobby_tag("新規タグ123")
    find("[data-testid='tag-category-trigger']").click
    find("[data-testid='tag-category-option']", text: "FPS").click
    click_button "更新する"

    expect(page).to have_current_path(profile_path(current_profile))
    hobby = Hobby.find_by(normalized_name: "新規タグ123")
    expect(hobby.hobby_parent_tags.find_by(room_type: :game)&.parent_tag).to eq(fps)
  end

  it "バリデーション失敗後も新規カードのカテゴリー選択が残る" do
    fill_in "自己紹介（500字以内）", with: "あ" * 501
    add_new_hobby_tag("再表示タグ")
    find("[data-testid='tag-category-trigger']").click
    find("[data-testid='tag-category-option']", text: "FPS").click
    click_button "更新する"

    click_on "趣味"
    expect(page).to have_css("[data-testid='tag-category-trigger']", text: "FPS")
  end
end
```

既存タグ describe に次を足す。

```ruby
it "既存タグのカードにカテゴリー開閉は出ない" do
  fill_in "tag-input", with: "Rai"
  find("[data-testid='autocomplete-item']", text: "Rails").click

  expect(page).to have_css("[data-testid='tag-parent-label']", text: "プログラミング")
  expect(page).to have_no_css("[data-testid='tag-category-trigger']")
end
```

bio の label が `自己紹介（500字以内）` でない場合は、`find("textarea[name='profile[bio]']").fill_in with: "あ" * 501` を使う。フォームは `f.text_area :bio` なので `name='profile[bio]'` でよい。

- [ ] **Step 2: 分類 spec を実行し、現行（第1段まで）で失敗することを確認する**

Run:

```bash
docker compose exec web bundle exec rspec spec/system/mypage/profile_tag_classification_spec.rb
```

Expected: FAIL。`tag-category-trigger` が無い。

- [ ] **Step 3: この Task では実装コードを書かない。失敗を確認したら Task 4 へ進む**

---

### Task 4: 第2段 GREEN — `is_new` とカード上カテゴリー

**Files:**
- Modify: `app/javascript/controllers/tag_autocomplete_controller.js`
- Modify: `app/javascript/controllers/tag_description_controller.js`
- Modify: `app/views/mypage/profiles/_form.html.erb`
- Modify: `spec/system/mypage/profile_tag_description_spec.rb`（新規カードの親ラベル期待）

**Interfaces:**
- Consumes: chip `{ name, normalized_name, description, parent_tag_id, parent_tag_name }`。`parentTagsValue`（`{ chat: [{id, name}], study: [...], game: [...] }`）。
- Produces: chip に `is_new: boolean` を足す。新規パス（`#confirmNewName`）だけ `true`。既存パス（`#selectExistingTag`）と edit 初期 JSON（`is_new` なし）は falsy。
- Produces: `#addChip(name, description = "", parentTagId = null, parentTagName = null, isNew = false)`
- Produces: `#syncHiddenField` は `{ name, description, parent_tag_id }` に加え、`is_new === true` のときだけ `is_new: true` を付ける。
- Produces: `connect()` は `tag.is_new === true` と `tag.parent_tag_id` を復元する。`parent_tag_name` が空で id があるときは `#parentTagNameById(id)` で `parentTagsValue` から引く。
- Produces: `updateCategory(event)` は `event.detail` の `{ name, parentTagId, parentTagName }` を `is_new` chip に書き、hidden を同期し `chips-changed` を再送する。`is_new` でない chip は無視する。
- Produces: `chips-changed` の detail は `{ chips: [...this.#chips], parentTags: this.parentTagsValue }`。
- Produces: `tag_description_controller.js` は `is_new` なら `tag-parent-label` の代わりに `tag-category-trigger` を描く。未選択テキストは `カテゴリー`。選択後は `parent_tag_name`。クリックで `tag-category-panel` をトグルする。
- Produces: パネル先頭の文言は次の2行で固定する。
  - `近いカテゴリーを選ぶと、マインドマップ上で同じ趣味の人とまとまって表示されやすくなります。`
  - `迷ったら、選ばなくても大丈夫です。`
- Produces: 候補は room_type 見出し（雑談系 / 学習系 / ゲーム系）の下に `tag-category-option`。`data-parent-tag-id` と `data-parent-tag-name`。空 option「わからない」は置かない。
- Produces: option クリックで CustomEvent `tag-category-update`（bubbles、detail は `{ name, parentTagId: number, parentTagName: string }`）。
- Produces: `_form.html.erb` の `data-action` に `tag-category-update->tag-autocomplete#updateCategory` を足す。

- [ ] **Step 1: 失敗する description spec の親ラベル期待を第2段に合わせる**

`spec/system/mypage/profile_tag_description_spec.rb` の新規カード例で `tag-parent-label` / `未分類` を見ている箇所は、次に変える。

```ruby
expect(page).to have_css("[data-testid='tag-category-trigger']", text: "カテゴリー")
expect(page).to have_css("[data-testid='tag-child-chip']", text: "ゲーム")
```

既存タグ復元の例は `tag-parent-label` のまま（`is_new` なし）。

- [ ] **Step 2: form の data-action にカテゴリー更新を足す**

`app/views/mypage/profiles/_form.html.erb` の趣味パネル:

```erb
data-action="chips-changed->tag-description#onChipsChanged tag-description-update->tag-autocomplete#updateDescription tag-remove-request->tag-autocomplete#removeTag tag-category-update->tag-autocomplete#updateCategory"
```

- [ ] **Step 3: autocomplete に `is_new` と category 更新を入れる**

chip コメントを `// chips: [{ name, normalized_name, description, parent_tag_id, parent_tag_name, is_new }]` に更新する。

`#confirmNewName`:

```javascript
#confirmNewName(query) {
  this.#addChip(query, "", null, null, true)
  this.inputTarget.value = ""
  this.#closeDropdown()
}
```

`#addChip` の push:

```javascript
this.#chips.push({
  name: displayName,
  normalized_name: normalizedName,
  description,
  parent_tag_id: parentTagId,
  parent_tag_name: parentTagName,
  is_new: Boolean(isNew)
})
```

`connect()`:

```javascript
parsed.forEach(tag => {
  const parentTagId = tag.parent_tag_id ?? null
  const parentTagName = tag.parent_tag_name || this.#parentTagNameById(parentTagId)
  this.#addChip(tag.name, tag.description || "", parentTagId, parentTagName, tag.is_new === true)
})
```

`#syncHiddenField`:

```javascript
#syncHiddenField() {
  this.hiddenFieldTarget.value = JSON.stringify(
    this.#chips.map(({ name, description, parent_tag_id, is_new }) => {
      const payload = { name, description, parent_tag_id }
      if (is_new) payload.is_new = true
      return payload
    })
  )
}

#dispatchChipsChanged() {
  this.element.dispatchEvent(new CustomEvent("chips-changed", {
    bubbles: true,
    detail: { chips: [...this.#chips], parentTags: this.parentTagsValue }
  }))
}

updateCategory(event) {
  const { name, parentTagId, parentTagName } = event.detail
  const chip = this.#chips.find(currentChip => currentChip.name === name)
  if (!chip?.is_new) return

  chip.parent_tag_id = parentTagId
  chip.parent_tag_name = parentTagName
  this.#syncHiddenField()
  this.#dispatchChipsChanged()
}

#parentTagNameById(parentTagId) {
  if (!parentTagId) return null
  const groups = Object.values(this.parentTagsValue)
  for (const tags of groups) {
    const list = Array.isArray(tags) ? tags : []
    const match = list.find(tag => tag.id === parentTagId)
    if (match) return match.name
  }
  return null
}
```

- [ ] **Step 4: description にカテゴリー開閉を描く**

コントローラ先頭にラベル定数を置く。

```javascript
const ROOM_TYPE_LABELS = {
  chat: "雑談系",
  study: "学習系",
  game: "ゲーム系"
}
```

フィールド:

```javascript
#parentTags = {}
```

`onChipsChanged`:

```javascript
onChipsChanged(event) {
  const { chips, parentTags } = event.detail
  if (parentTags) this.#parentTags = parentTags
  this.#renderDescriptionInputs(chips)
}
```

公開アクション:

```javascript
onCategoryToggle(event) {
  const card = event.currentTarget.closest("[data-testid='tag-card']")
  const panel = card?.querySelector("[data-testid='tag-category-panel']")
  panel?.classList.toggle("hidden")
}

onCategorySelect(event) {
  const button = event.currentTarget
  const name = button.dataset.name
  const parentTagId = parseInt(button.dataset.parentTagId, 10)
  const parentTagName = button.dataset.parentTagName

  this.element.dispatchEvent(new CustomEvent("tag-category-update", {
    bubbles: true,
    detail: { name, parentTagId, parentTagName }
  }))
}
```

`#renderDescriptionInputs` の親ラベル箇所を、`chip.is_new` なら trigger + 隠しパネル、それ以外は今の `tag-parent-label` にする。trigger の表示は `chip.parent_tag_name || "カテゴリー"`。パネル HTML は `#categoryPanelHtml(chip)` で組み立てる。

```javascript
#categoryPanelHtml(chip) {
  const groups = Object.entries(this.#parentTags).flatMap(([roomType, tags]) => {
    const tagList = Array.isArray(tags) ? tags : []
    if (tagList.length === 0) return []

    const options = tagList.map(parentTag => `
      <button type="button"
              data-testid="tag-category-option"
              data-name="${this.#escapeHtml(chip.name)}"
              data-parent-tag-id="${parentTag.id}"
              data-parent-tag-name="${this.#escapeHtml(parentTag.name)}"
              data-action="click->tag-description#onCategorySelect"
              class="block w-full text-left px-3 py-1.5 text-sm text-slate-200">
        ${this.#escapeHtml(parentTag.name)}
      </button>
    `).join("")

    return [
      `<div class="px-3 pt-2 pb-1 text-xs font-semibold text-slate-400">${ROOM_TYPE_LABELS[roomType] || roomType}</div>`,
      options
    ]
  }).join("")

  return `
    <div data-testid="tag-category-panel"
         class="hidden absolute z-20 mt-1 min-w-[16rem] rounded-lg border border-slate-700 bg-slate-900 p-3 shadow-lg">
      <p class="mb-2 text-xs leading-relaxed text-slate-300">近いカテゴリーを選ぶと、マインドマップ上で同じ趣味の人とまとまって表示されやすくなります。</p>
      <p class="mb-3 text-xs leading-relaxed text-slate-400">迷ったら、選ばなくても大丈夫です。</p>
      ${groups}
    </div>
  `
}
```

trigger は `relative` なラッパー内に置き、パネルがカードに重なるようにする。

```javascript
#categoryTriggerHtml(chip) {
  const label = chip.parent_tag_name || "カテゴリー"
  return `
    <div style="position:relative;">
      <button type="button"
              data-testid="tag-category-trigger"
              data-action="click->tag-description#onCategoryToggle"
              class="inline-flex items-center rounded-full px-2.5 text-[11px] font-semibold"
              style="background:rgba(71,85,105,0.22);color:#cbd5e1;border:1px solid rgba(148,163,184,0.28);padding-top:0.18rem;padding-bottom:0.18rem;">
        ${this.#escapeHtml(label)}
      </button>
      ${this.#categoryPanelHtml(chip)}
    </div>
  `
}
```

選んだあとの trigger は `#parentLabelStyle(chip.parent_tag_name)` を使って既存バッジに寄せてよい。未選択はグレーのまま。

- [ ] **Step 5: 第2段 spec と第1段回帰を実行する**

Run:

```bash
docker compose exec web bundle exec rspec \
  spec/system/mypage/profile_tag_classification_spec.rb \
  spec/system/mypage/profile_tag_autocomplete_spec.rb \
  spec/system/mypage/profile_tag_description_spec.rb \
  spec/system/profile_hobbies_flow_spec.rb \
  spec/system/mypage/profile_tag_help_spec.rb \
  spec/services/profile_hobbies_updater_spec.rb \
  spec/requests/mypage/profile_spec.rb
```

Expected: PASS

bio ラベルで fill_in が失敗したら、Step 1 のとおり `textarea[name='profile[bio]']` に切り替えて同じ spec を再実行する。1仮説ずつ直す。

- [ ] **Step 6: RuboCop**

Run:

```bash
docker compose exec web bundle exec rubocop
```

Expected: 違反なし。出たら対象ファイルだけ直す。

- [ ] **Step 7: Commit**

```bash
git add app/javascript/controllers/tag_autocomplete_controller.js \
  app/javascript/controllers/tag_description_controller.js \
  app/views/mypage/profiles/_form.html.erb \
  spec/system/mypage/profile_tag_classification_spec.rb \
  spec/system/mypage/profile_tag_description_spec.rb
git commit -m "$(cat <<'EOF'
feat: 新規カードの追加後にカテゴリーを任意選択できるようにする #305

is_new は失敗再表示用。分類権限は previously_new_record? のままにする。
EOF
)"
```

---

## Self-Review

1. **Spec coverage:** 即カード、Enter、入力中は増やさない、門 UI 削除、新規だけカテゴリー、固定文言、未選択は HobbyParentTag なし、選択保存、失敗再表示、既存カードに開閉なし、ヘルプ非改修、Updater 非改修、マインドマップ非改修。Task 1–4 で対応。
2. **Placeholder scan:** TBD / 「同様に」なし。helper・JS・spec 本文を各 Task に書いた。
3. **Type consistency:** `add_new_hobby_tag`、`new-tag-add-row`、`#confirmNewName`、`is_new`、`tag-category-trigger` / `panel` / `option`、`updateCategory` の detail `{ name, parentTagId, parentTagName }` で統一。

## 実行時の注意

- `onInput` から即 `#addChip` しない。打ちながらカードが増える。
- 候補があるときの追加行は出さない。新規は Enter。
- `connect()` が `parent_tag_id` を `null` で上書きしたままだと、第2段の再表示が落ちる。
- 未選択を `uncategorized` 親タグに付けない。join が無いことが管理の未分類一覧の条件。
