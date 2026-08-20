# Codex 実装プロンプト：Issue #237 趣味タグUI改善（親タグ結びつき）

## コンテキスト

- **リポジトリ:** hobby-matching-app（Ruby on Rails + Stimulus.js）
- **ブランチ:** `feature/237-profile-tag-parent-suggestion`
- **実行環境:** `docker compose exec web` 経由でコマンドを実行する
- **Issue:** #237

## 背景

プロフィール編集画面の趣味タグ入力UIを改善する。
ユーザーが新規タグを作成する際、どの親タグ（カテゴリ）に属するかを選択できるようにする。
既存タグにはオートコンプリート候補に親タグ名バッジを表示する。

## 重要なルール

- **必ずTDD（RED → GREEN → REFACTOR）で進める**
- 実装より先にテストを書く
- コマンドはすべて `docker compose exec web` 経由
- `previously_new_record?` で新規Hobby のみ分類対象にする（既存Hobbyは触らない）
- マイグレーション不要（既存スキーマで対応）

## 既存コードの理解

### 主要モデルの関係

```
Profile → profile_hobbies → Hobby → hobby_parent_tags → ParentTag
```

- `ParentTag` は `room_type` enum（chat: 0, study: 1, game: 2）と `name`（例: プログラミング, FPS）を持つ
- `HobbyParentTag` は `(hobby_id, room_type)` の unique 制約あり
- `ProfileHobbiesUpdater.call(profile, tag_data)` が保存の起点
  - `tag_data` は `[{ name: String, description: String }]` 形式（今回拡張）

### 既存の autocomplete

```ruby
# app/controllers/hobbies_controller.rb
def autocomplete
  q = params[:q].to_s.strip
  return render json: [] if q.length < 2
  hobbies = Hobby.where("name LIKE ?", "#{q.downcase}%").limit(10).pluck(:name)
  render json: hobbies
end
```

### 既存の ProfileHobbiesUpdater（抜粋）

```ruby
# app/services/profile_hobbies_updater.rb
normalized.each do |tag|
  hobby = existing_hobbies[tag[:name]] ||
          Hobby.find_or_create_by!(normalized_name: tag[:name]) { |h| h.name = tag[:name] }
  ph = existing_phs[tag[:name]] || ProfileHobby.new(profile:, hobby:)
  ph.description = tag[:description]
  ph.save!
end
```

### 既存の My::ProfilesController#edit

```ruby
def edit
  @hobbies_text = @profile.profile_hobbies.includes(:hobby).map do |ph|
    { name: ph.hobby.name, description: ph.description.to_s }
  end.to_json
end
```

---

## Task 1：HobbiesController#autocomplete 改修

### 対象ファイル
- 修正: `app/controllers/hobbies_controller.rb`
- テスト: `spec/requests/hobbies_spec.rb`

### Step 1: テストを更新して失敗させる

`spec/requests/hobbies_spec.rb` の既存テストを以下に更新する：

```ruby
it "前方一致する候補を返す" do
  create(:hobby, name: "アニメ")
  create(:hobby, name: "アウトドア")
  create(:hobby, name: "野球")
  get autocomplete_hobbies_path, params: { q: "アニ" }
  body = JSON.parse(response.body)
  expect(body).to eq([ { "name" => "アニメ", "parent_tag_name" => nil, "room_type" => nil } ])
end

it "最大10件まで返す" do
  11.times { |i| create(:hobby, name: "アニメ#{i.to_s.rjust(2, '0')}") }
  get autocomplete_hobbies_path, params: { q: "アニメ" }
  expect(JSON.parse(response.body).size).to eq(10)
end
```

以下のテストを追加する：

```ruby
it "親タグが紐づいている hobby は parent_tag_name と room_type を返す" do
  programming = create(:parent_tag, name: "プログラミング", slug: "programming", room_type: :study)
  rails_hobby = create(:hobby, name: "Rails")
  create(:hobby_parent_tag, hobby: rails_hobby, parent_tag: programming)

  get autocomplete_hobbies_path, params: { q: "Rai" }
  body = JSON.parse(response.body)

  expect(body).to eq([ { "name" => "Rails", "parent_tag_name" => "プログラミング", "room_type" => "study" } ])
end

it "大文字で入力しても normalized_name で前方一致する" do
  create(:hobby, name: "Rails")

  get autocomplete_hobbies_path, params: { q: "RAIL" }
  body = JSON.parse(response.body)

  expect(body.map { |h| h["name"] }).to include("Rails")
end
```

### Step 2: テスト実行 → 失敗確認

```bash
docker compose exec web bundle exec rspec spec/requests/hobbies_spec.rb
```

### Step 3: 実装

```ruby
# app/controllers/hobbies_controller.rb
class HobbiesController < ApplicationController
  before_action :authenticate_user!

  def autocomplete
    q = params[:q].to_s.strip
    return render json: [] if q.length < 2

    hobbies = Hobby.where("normalized_name LIKE ?", "#{Hobby.normalize(q)}%")
                   .includes(hobby_parent_tags: :parent_tag)
                   .limit(10)

    render json: hobbies.map { |h| serialize_hobby(h) }
  end

  private

  def serialize_hobby(hobby)
    primary = hobby.hobby_parent_tags.min_by { |hpt| HobbyParentTag.room_types[hpt.room_type] }
    {
      name: hobby.name,
      parent_tag_name: primary&.parent_tag&.name,
      room_type: primary&.room_type
    }
  end
end
```

### Step 4: テスト実行 → 全件成功確認

```bash
docker compose exec web bundle exec rspec spec/requests/hobbies_spec.rb
```

期待: `7 examples, 0 failures`

### Step 5: コミット

```bash
git add app/controllers/hobbies_controller.rb spec/requests/hobbies_spec.rb
git commit -m "feat: autocomplete を親タグ情報付き JSON 形式に変更 #237"
```

---

## Task 2：ProfileHobbiesUpdater 改修

### 対象ファイル
- 修正: `app/services/profile_hobbies_updater.rb`
- テスト: `spec/services/profile_hobbies_updater_spec.rb`

### Step 1: テストを追加して失敗させる

`spec/services/profile_hobbies_updater_spec.rb` に以下のコンテキストを追加する：

```ruby
context "parent_tag_id の処理" do
  let(:programming) do
    create(:parent_tag, name: "プログラミング", slug: "programming", room_type: :study)
  end

  it "新規タグ + 有効な parent_tag_id → HobbyParentTag が作成される" do
    described_class.call(profile, [ { name: "newlang", description: "", parent_tag_id: programming.id } ])

    hobby = Hobby.find_by(normalized_name: "newlang")
    expect(hobby.hobby_parent_tags.find_by(room_type: :study)&.parent_tag).to eq(programming)
  end

  it "既存（未分類）タグ + parent_tag_id → HobbyParentTag は作成されない" do
    create(:hobby, name: "existingtag")

    described_class.call(profile, [ { name: "existingtag", description: "", parent_tag_id: programming.id } ])

    hobby = Hobby.find_by(normalized_name: "existingtag")
    expect(hobby.hobby_parent_tags).to be_empty
  end

  it "既存（分類済み）タグ + 異なる parent_tag_id → 分類は変更されない" do
    game_tag = create(:parent_tag, name: "FPS", slug: "fps", room_type: :game)
    hobby = create(:hobby, name: "apex")
    create(:hobby_parent_tag, hobby:, parent_tag: game_tag)

    described_class.call(profile, [ { name: "apex", description: "", parent_tag_id: programming.id } ])

    expect(hobby.reload.hobby_parent_tags.find_by(room_type: :game)&.parent_tag).to eq(game_tag)
    expect(hobby.hobby_parent_tags.find_by(room_type: :study)).to be_nil
  end

  it "不正な parent_tag_id → 無視されて保存は成功する" do
    expect {
      described_class.call(profile, [ { name: "sometag", description: "", parent_tag_id: 99999 } ])
    }.not_to raise_error

    hobby = Hobby.find_by(normalized_name: "sometag")
    expect(hobby).not_to be_nil
    expect(hobby.hobby_parent_tags).to be_empty
  end

  it "parent_tag_id が nil → HobbyParentTag は作成されない（わからない選択）" do
    described_class.call(profile, [ { name: "unknowntag", description: "", parent_tag_id: nil } ])

    hobby = Hobby.find_by(normalized_name: "unknowntag")
    expect(hobby.hobby_parent_tags).to be_empty
  end
end
```

### Step 2: テスト実行 → 失敗確認

```bash
docker compose exec web bundle exec rspec spec/services/profile_hobbies_updater_spec.rb
```

### Step 3: 実装

`app/services/profile_hobbies_updater.rb` のループ内（`find_or_create_by!` の直後）に追加：

```ruby
hobby = existing_hobbies[tag[:name]] ||
        Hobby.find_or_create_by!(normalized_name: tag[:name]) { |h| h.name = tag[:name] }

classify_if_newly_created(hobby, tag[:parent_tag_id])  # ← この行を追加
```

クラスの末尾（既存の private メソッドの後）に追加：

```ruby
def self.classify_if_newly_created(hobby, parent_tag_id)
  return unless hobby.previously_new_record?
  return if parent_tag_id.blank?

  parent_tag = ParentTag.find_by(id: parent_tag_id)
  return unless parent_tag

  Admin::HobbyClassificationService.call(hobby:, parent_tag:)
end
```

### Step 4: テスト実行 → 全件成功確認

```bash
docker compose exec web bundle exec rspec spec/services/profile_hobbies_updater_spec.rb
```

期待: `17 examples, 0 failures`

### Step 5: コミット

```bash
git add app/services/profile_hobbies_updater.rb spec/services/profile_hobbies_updater_spec.rb
git commit -m "feat: 新規タグ作成時に parent_tag_id で分類できるようにする #237"
```

---

## Task 3：My::ProfilesController 改修

### 対象ファイル
- 修正: `app/controllers/my/profiles_controller.rb`
- テスト: `spec/requests/my/profile_spec.rb`

### Step 1: テストを追加して失敗させる

`spec/requests/my/profile_spec.rb` に以下を追加する：

```ruby
describe "GET /my/profile/edit" do
  # 既存テストの下に追加
  context "プロフィール作成済み" do
    let!(:profile) { create(:profile, user:) }
    let(:programming) { create(:parent_tag, name: "プログラミング", slug: "programming", room_type: :study) }

    it "hobbies_text に parent_tag_name と room_type が含まれる" do
      rails_hobby = create(:hobby, name: "Rails")
      create(:hobby_parent_tag, hobby: rails_hobby, parent_tag: programming)
      create(:profile_hobby, profile:, hobby: rails_hobby)

      get edit_my_profile_path

      expect(response.body).to include("プログラミング")
      expect(response.body).to include("study")
    end
  end
end

# PATCH のテスト内に追加
describe "PATCH /my/profile" do
  let!(:profile) { create(:profile, user:) }
  let(:fps) { create(:parent_tag, name: "FPS", slug: "fps", room_type: :game) }

  it "parent_tag_id 付きで新規タグを保存すると HobbyParentTag が作成される" do
    hobbies_text = [ { name: "brandnewtag", description: "", parent_tag_id: fps.id } ].to_json

    patch my_profile_path, params: { profile: { bio: "自己紹介", hobbies_text: } }

    hobby = Hobby.find_by(normalized_name: "brandnewtag")
    expect(hobby.hobby_parent_tags.find_by(room_type: :game)&.parent_tag).to eq(fps)
  end
end
```

### Step 2: テスト実行 → 失敗確認

```bash
docker compose exec web bundle exec rspec spec/requests/my/profile_spec.rb
```

### Step 3: 実装

```ruby
# app/controllers/my/profiles_controller.rb
# before_action に追加
before_action :set_parent_tags, only: %i[new create edit update]

# edit アクションを差し替え
def edit
  @hobbies_text = @profile.profile_hobbies
    .includes(hobby: { hobby_parent_tags: :parent_tag })
    .map { |ph| serialize_profile_hobby(ph) }
    .to_json
end

# private に追加
def serialize_profile_hobby(ph)
  primary = ph.hobby.hobby_parent_tags.min_by { |hpt| HobbyParentTag.room_types[hpt.room_type] }
  {
    name: ph.hobby.name,
    description: ph.description.to_s,
    parent_tag_name: primary&.parent_tag&.name,
    room_type: primary&.room_type
  }
end

def set_parent_tags
  @parent_tags_by_room_type = ParentTag.where.not(slug: "uncategorized")
                                       .order(:room_type, :position)
                                       .group_by(&:room_type)
end
```

### Step 4: テスト実行 → 全件成功確認

```bash
docker compose exec web bundle exec rspec spec/requests/my/profile_spec.rb
```

### Step 5: コミット

```bash
git add app/controllers/my/profiles_controller.rb spec/requests/my/profile_spec.rb
git commit -m "feat: プロフィール編集で親タグ情報を読み書きする #237"
```

---

## Task 4：_form.html.erb に data 属性追加

### 対象ファイル
- 修正: `app/views/my/profiles/_form.html.erb`

### Step 1: タグパネルの div に data 属性を追加

`data-controller="tag-description tag-autocomplete"` がある div に `data-tag-autocomplete-parent-tags-value` を追加する：

```erb
<div data-tabs-target="panel"
     class="relative hidden rounded-2xl border border-slate-700/50 bg-slate-950/40 p-5 md:p-6"
     data-controller="tag-description tag-autocomplete"
     data-tag-autocomplete-url-value="<%= autocomplete_hobbies_path %>"
     data-tag-autocomplete-max-value="10"
     data-tag-autocomplete-parent-tags-value="<%= @parent_tags_by_room_type.transform_values { |pts| pts.map { |pt| { id: pt.id, name: pt.name } } }.to_json.html_safe %>"
     data-action="chips-changed->tag-description#onChipsChanged tag-description-update->tag-autocomplete#updateDescription">
```

### Step 2: コミット

```bash
git add app/views/my/profiles/_form.html.erb
git commit -m "feat: タグ入力エリアに親タグ JSON を data 属性で渡す #237"
```

---

## Task 5：tag_autocomplete_controller.js 改修

### 対象ファイル
- 修正: `app/javascript/controllers/tag_autocomplete_controller.js`
- 新規: `spec/system/my/profile_tag_classification_spec.rb`

### Step 1: system spec を新規作成して失敗させる

```ruby
# spec/system/my/profile_tag_classification_spec.rb
require "rails_helper"

RSpec.describe "タグ作成時の親タグ選択", type: :system, js: true do
  let(:current_user) { create(:user) }
  let!(:current_profile) { create(:profile, user: current_user) }
  let!(:fps) { create(:parent_tag, name: "FPS", slug: "fps", room_type: :game, position: 0) }

  before do
    login_as(current_user, scope: :user)
    visit edit_my_profile_path
    click_on "タグ"
  end

  describe "新規タグの親タグ選択" do
    it "候補にないタグを追加すると新規追加セクションが表示される" do
      fill_in "tag-input", with: "brandnewgame"
      expect(page).to have_css("[data-testid='new-tag-section']")
    end

    it "親タグを選んで追加するとチップにバッジが表示される" do
      fill_in "tag-input", with: "brandnewgame"
      select "FPS", from: "new-tag-parent-select"
      click_button "追加する"

      expect(page).to have_css("[data-testid='chip']", text: "brandnewgame")
      expect(page).to have_css("[data-testid='chip-badge']", text: "FPS")
    end

    it "わからないを選んで追加するとバッジなしのチップが表示される" do
      fill_in "tag-input", with: "unknowntag"
      find("[data-testid='skip-parent-tag']").click

      expect(page).to have_css("[data-testid='chip']", text: "unknowntag")
      expect(page).not_to have_css("[data-testid='chip-badge']")
    end

    it "保存すると親タグ選択が DB に反映される" do
      fill_in "tag-input", with: "newtag123"
      select "FPS", from: "new-tag-parent-select"
      click_button "追加する"
      click_button "保存する"

      hobby = Hobby.find_by(normalized_name: "newtag123")
      expect(hobby.hobby_parent_tags.find_by(room_type: :game)&.parent_tag).to eq(fps)
    end
  end

  describe "既存タグのバッジ表示" do
    let!(:rails_hobby) { create(:hobby, name: "Rails") }
    let!(:programming) { create(:parent_tag, name: "プログラミング", slug: "programming", room_type: :study, position: 0) }
    let!(:hpt) { create(:hobby_parent_tag, hobby: rails_hobby, parent_tag: programming) }

    it "autocomplete の候補に親タグ名バッジが表示される" do
      fill_in "tag-input", with: "Rai"

      expect(page).to have_css("[data-testid='autocomplete-item']", text: "Rails")
      expect(page).to have_css("[data-testid='autocomplete-badge']", text: "プログラミング")
    end

    it "既存タグを選択するとチップに親タグ名バッジが表示される" do
      fill_in "tag-input", with: "Rai"
      find("[data-testid='autocomplete-item']", text: "Rails").click

      expect(page).to have_css("[data-testid='chip']", text: "rails")
      expect(page).to have_css("[data-testid='chip-badge']", text: "プログラミング")
    end
  end
end
```

### Step 2: テスト実行 → 失敗確認

```bash
docker compose exec web bundle exec rspec spec/system/my/profile_tag_classification_spec.rb
```

### Step 3: tag_autocomplete_controller.js を全面改修

`app/javascript/controllers/tag_autocomplete_controller.js` を以下で置き換える：

```javascript
import { Controller } from "@hotwired/stimulus"

const ROOM_TYPE_LABELS = { chat: "雑談系", study: "学習系", game: "ゲーム系" }

export default class extends Controller {
  static targets = ["input", "hiddenField", "chipList", "dropdown", "count"]
  static values = {
    url: String,
    max: { type: Number, default: 10 },
    parentTags: { type: Object, default: {} }
  }

  #debounceTimer = null
  // chips: [{ name, description, parent_tag_id, parent_tag_name }]
  #chips = []
  #activeIndex = -1
  #pendingNewTag = null

  connect() {
    const existing = this.hiddenFieldTarget.value
    if (existing) {
      try {
        const parsed = JSON.parse(existing)
        parsed.forEach(tag => this.#addChip(tag.name, tag.description || "", null, tag.parent_tag_name || null))
      } catch { /* JSON でない場合は無視 */ }
    }
  }

  onInput() {
    clearTimeout(this.#debounceTimer)
    const q = this.inputTarget.value.trim()
    if (q.length < 2) { this.#closeDropdown(); return }
    this.#debounceTimer = setTimeout(() => this.#fetchSuggestions(q), 300)
  }

  onKeydown(event) {
    const items = this.dropdownTarget.querySelectorAll("[data-testid='autocomplete-item']")
    const isOpen = !this.dropdownTarget.classList.contains("hidden") && items.length > 0

    if (event.key === "ArrowDown") {
      event.preventDefault()
      if (!isOpen) return
      this.#activeIndex = Math.min(this.#activeIndex + 1, items.length - 1)
      this.#updateActiveItem(items)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      if (!isOpen) return
      this.#activeIndex = Math.max(this.#activeIndex - 1, -1)
      this.#updateActiveItem(items)
    } else if (event.key === "Enter") {
      event.preventDefault()
      if (isOpen && this.#activeIndex >= 0) {
        const item = items[this.#activeIndex]
        this.#selectExistingTag(item.dataset.name, item.dataset.parentTagName || null)
      } else {
        const q = this.inputTarget.value.trim()
        if (q) this.#triggerNewTagFlow(q)
      }
    } else if (event.key === "Escape") {
      this.#closeDropdown()
    }
  }

  selectSuggestion(event) {
    const { name, parentTagName } = event.currentTarget.dataset
    this.#selectExistingTag(name, parentTagName || null)
  }

  confirmNewTag() {
    if (!this.#pendingNewTag) return
    const select = this.dropdownTarget.querySelector("[data-testid='new-tag-parent-select']")
    const selectedOption = select?.options[select.selectedIndex]
    const parentTagId = selectedOption?.value ? parseInt(selectedOption.value) : null
    const parentTagName = selectedOption?.value ? selectedOption.text : null

    this.#addChip(this.#pendingNewTag, "", parentTagId, parentTagName)
    this.inputTarget.value = ""
    this.#pendingNewTag = null
    this.#closeDropdown()
  }

  skipParentTag() {
    if (!this.#pendingNewTag) return
    this.#addChip(this.#pendingNewTag, "", null, null)
    this.inputTarget.value = ""
    this.#pendingNewTag = null
    this.#closeDropdown()
  }

  removeChip(event) {
    const name = event.currentTarget.dataset.name
    this.#chips = this.#chips.filter(c => c.name !== name)
    this.#renderChips()
    this.#syncHiddenField()
    this.#dispatchChipsChanged()
    if (this.#chips.length < this.maxValue) this.inputTarget.disabled = false
  }

  updateDescription(event) {
    const { name, description } = event.detail
    const chip = this.#chips.find(c => c.name === name)
    if (chip) { chip.description = description; this.#syncHiddenField() }
  }

  // private

  #selectExistingTag(name, parentTagName) {
    this.#addChip(name, "", null, parentTagName || null)
    this.inputTarget.value = ""
    this.#closeDropdown()
  }

  #triggerNewTagFlow(q) {
    const normalized = q.toLowerCase()
    if (this.#chips.find(c => c.name === normalized)) return
    this.#pendingNewTag = normalized
    this.#renderNewTagUI(q)
  }

  #addChip(name, description = "", parentTagId = null, parentTagName = null) {
    const normalized = name.toLowerCase()
    if (this.#chips.find(c => c.name === normalized)) return
    if (this.#chips.length >= this.maxValue) return
    this.#chips.push({ name: normalized, description, parent_tag_id: parentTagId, parent_tag_name: parentTagName })
    this.#renderChips()
    this.#syncHiddenField()
    this.#dispatchChipsChanged()
    if (this.#chips.length >= this.maxValue) this.inputTarget.disabled = true
  }

  #renderChips() {
    this.chipListTarget.innerHTML = this.#chips.map(chip => `
      <span data-testid="chip"
            style="display:inline-flex;align-items:center;gap:0.25rem;border-radius:9999px;background:rgba(96,165,250,0.15);padding:0.25rem 0.75rem;font-size:0.875rem;color:#60a5fa;">
        ${this.#escapeHtml(chip.name)}
        ${chip.parent_tag_name
          ? `<span data-testid="chip-badge" style="font-size:0.7rem;background:rgba(96,165,250,0.2);padding:0.1rem 0.4rem;border-radius:9999px;">${this.#escapeHtml(chip.parent_tag_name)}</span>`
          : ""}
        <button type="button"
                data-action="click->tag-autocomplete#removeChip"
                data-name="${this.#escapeHtml(chip.name)}"
                style="margin-left:0.25rem;color:#60a5fa;background:none;border:none;cursor:pointer;line-height:1;"
                aria-label="${this.#escapeHtml(chip.name)}を削除">×</button>
      </span>
    `).join("")

    if (this.hasCountTarget) {
      this.countTarget.textContent = `${this.#chips.length} / ${this.maxValue}件`
    }
  }

  #syncHiddenField() {
    this.hiddenFieldTarget.value = JSON.stringify(
      this.#chips.map(({ name, description, parent_tag_id }) => ({ name, description, parent_tag_id }))
    )
  }

  #dispatchChipsChanged() {
    this.element.dispatchEvent(new CustomEvent("chips-changed", { bubbles: true, detail: { chips: [...this.#chips] } }))
  }

  async #fetchSuggestions(q) {
    const url = `${this.urlValue}?q=${encodeURIComponent(q)}`
    try {
      const res = await fetch(url, { headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" } })
      const hobbies = await res.json()
      if (hobbies.length > 0) {
        this.#renderDropdown(hobbies)
      } else {
        this.#triggerNewTagFlow(q)
      }
    } catch { this.#closeDropdown() }
  }

  #renderDropdown(hobbies) {
    this.dropdownTarget.innerHTML = hobbies.map(h => `
      <li data-testid="autocomplete-item"
          data-name="${this.#escapeHtml(h.name)}"
          data-parent-tag-name="${this.#escapeHtml(h.parent_tag_name || "")}"
          data-action="click->tag-autocomplete#selectSuggestion"
          style="cursor:pointer;padding:0.5rem 1rem;font-size:0.875rem;color:#d1d5db;display:flex;justify-content:space-between;align-items:center;"
          onmouseenter="this.style.background='rgba(96,165,250,0.15)'"
          onmouseleave="this.style.background='transparent'">
        <span>${this.#escapeHtml(h.name)}</span>
        ${h.parent_tag_name
          ? `<span data-testid="autocomplete-badge" style="font-size:0.7rem;background:rgba(96,165,250,0.15);color:#93c5fd;padding:0.1rem 0.5rem;border-radius:9999px;">${this.#escapeHtml(h.parent_tag_name)}</span>`
          : ""}
      </li>
    `).join("")
    this.dropdownTarget.classList.remove("hidden")
  }

  #renderNewTagUI(q) {
    const options = Object.entries(this.parentTagsValue).flatMap(([roomType, tags]) => {
      if (!tags || tags.length === 0) return []
      return [
        `<optgroup label="${ROOM_TYPE_LABELS[roomType] || roomType}">`,
        ...tags.map(pt => `<option value="${pt.id}">${this.#escapeHtml(pt.name)}</option>`),
        "</optgroup>"
      ]
    }).join("")

    this.dropdownTarget.innerHTML = `
      <li data-testid="new-tag-section"
          style="padding:0.75rem 1rem;font-size:0.875rem;color:#d1d5db;">
        <div style="margin-bottom:0.5rem;">「${this.#escapeHtml(q)}」を新しいタグとして追加する</div>
        <div style="margin-bottom:0.5rem;color:#9ca3af;font-size:0.8rem;">近い分類を選ぶと、あとで見つけやすくなります</div>
        <select data-testid="new-tag-parent-select"
                id="new-tag-parent-select"
                style="width:100%;background:#1e293b;color:#f9fafb;border:1px solid #374151;padding:0.375rem 0.5rem;border-radius:0.375rem;margin-bottom:0.5rem;">
          ${options}
        </select>
        <div style="display:flex;gap:0.5rem;">
          <button type="button"
                  data-action="click->tag-autocomplete#confirmNewTag"
                  style="background:#2563eb;color:white;border:none;padding:0.375rem 0.75rem;border-radius:0.375rem;cursor:pointer;font-size:0.8rem;">
            追加する
          </button>
          <button type="button"
                  data-testid="skip-parent-tag"
                  data-action="click->tag-autocomplete#skipParentTag"
                  style="background:#374151;color:#9ca3af;border:none;padding:0.375rem 0.75rem;border-radius:0.375rem;cursor:pointer;font-size:0.8rem;">
            わからない
          </button>
        </div>
      </li>
    `
    this.dropdownTarget.classList.remove("hidden")
  }

  #closeDropdown() {
    this.dropdownTarget.innerHTML = ""
    this.dropdownTarget.classList.add("hidden")
    this.#activeIndex = -1
    this.#pendingNewTag = null
  }

  #updateActiveItem(items) {
    items.forEach((item, i) => {
      item.style.background = i === this.#activeIndex ? "rgba(96,165,250,0.15)" : "transparent"
    })
  }

  #escapeHtml(str) {
    return String(str)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;").replace(/'/g, "&#39;")
  }
}
```

### Step 4: テスト実行 → 全件成功確認

```bash
docker compose exec web bundle exec rspec spec/system/my/profile_tag_classification_spec.rb
```

期待: `5 examples, 0 failures`

### Step 5: 全テスト実行

```bash
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rubocop
```

### Step 6: コミット

```bash
git add app/javascript/controllers/tag_autocomplete_controller.js spec/system/my/profile_tag_classification_spec.rb
git commit -m "feat: タグ入力UIに親タグバッジ・新規タグ時の親タグ選択を追加 #237"
```

---

## 完了確認

全タスク完了後に実行する：

```bash
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rubocop
```

すべて 0 failures / 0 offenses になれば実装完了。
