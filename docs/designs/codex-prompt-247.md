# Codex 実装プロンプト — Issue #247 趣味タグ ヘルプ導線

## 概要

プロフィール編集フォームの趣味タグセクションに「親タグとは？」ヘルプ導線を追加する。
クリックするとインラインでヘルプが展開・折りたたみできる UI。

## ブランチ

`feature/247-profile-tag-help`

## 作業ルール

- **TDD 厳守: RED → GREEN → REFACTOR**
- すべてのコマンドは `docker compose exec web` 経由
- 実装前に必ず spec を書いて失敗を確認してから実装する
- コミットは spec と実装を分けて 2 回行う

---

## Task 1: system spec を書く（RED）

### 新規作成ファイル

`spec/system/my/profile_tag_help_spec.rb`

```ruby
require "rails_helper"

RSpec.describe "趣味タグ ヘルプ導線", type: :system, js: true do
  let(:current_user) { create(:user) }
  let!(:current_profile) { create(:profile, user: current_user) }

  before do
    # タグタブに切り替えてからヘルプ操作を確認
    login_as(current_user, scope: :user)
    visit edit_my_profile_path
    click_on "タグ"
  end

  it "「親タグとは？」ボタンが表示されている" do
    # ヘルプトグルボタンが存在すること
    expect(page).to have_css("[data-testid='tag-help-toggle']")
    expect(page).to have_text("親タグとは？")
  end

  it "「親タグとは？」をクリックするとヘルプが展開される" do
    # ヘルプコンテンツは初期状態で非表示
    expect(page).not_to have_css("[data-testid='tag-help-content']", visible: true)

    # ボタンをクリック
    find("[data-testid='tag-help-toggle']").click

    # ヘルプコンテンツが表示される
    expect(page).to have_css("[data-testid='tag-help-content']", visible: true)
    expect(page).to have_text("親タグとは？")
    expect(page).to have_text("雑談系")
    expect(page).to have_text("学習系")
    expect(page).to have_text("ゲーム系")
    expect(page).to have_text("わからない")
  end

  it "展開後に「閉じる」をクリックするとヘルプが折りたたまれる" do
    # ヘルプを開く
    find("[data-testid='tag-help-toggle']").click
    expect(page).to have_css("[data-testid='tag-help-content']", visible: true)

    # 閉じるをクリック
    find("[data-testid='tag-help-toggle']").click

    # ヘルプコンテンツが非表示になる
    expect(page).to have_css("[data-testid='tag-help-content']", visible: false)
  end
end
```

### spec 実行（失敗を確認）

```bash
docker compose exec web bundle exec rspec spec/system/my/profile_tag_help_spec.rb
```

期待出力: `3 examples, 3 failures`

---

## Task 2: ビューを実装して GREEN にする

### 修正ファイル

`app/views/my/profiles/_form.html.erb`

#### 変更箇所

65〜75 行目の以下のブロック：

```erb
      <div class="mb-5 flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
        <div>
          <h2 class="text-sm font-semibold text-slate-200">趣味タグ</h2>
          <p class="mt-1 text-sm leading-relaxed text-slate-400">
            まずは気軽に 2〜5 個ほど登録すると、プロフィールの雰囲気が伝わりやすくなります。
          </p>
        </div>
        <div data-tag-autocomplete-target="count"
             data-testid="tag-count"
             class="text-xs font-medium tracking-wide text-slate-500">0 / 10件</div>
      </div>
```

を以下に置き換える：

```erb
      <%# toggle_controller でヘルプ展開を制御 %>
      <div data-controller="toggle">
        <div class="mb-5 flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
          <div>
            <%# 見出しとヘルプボタンを横並び %>
            <div class="flex items-center gap-2">
              <h2 class="text-sm font-semibold text-slate-200">趣味タグ</h2>
              <button type="button"
                      data-action="click->toggle#toggle"
                      data-testid="tag-help-toggle"
                      class="text-xs text-blue-400 underline underline-offset-2 hover:text-blue-300 transition">
                <span data-toggle-target="openText">親タグとは？</span>
                <span data-toggle-target="closeText" class="hidden">閉じる</span>
              </button>
            </div>
            <p class="mt-1 text-sm leading-relaxed text-slate-400">
              まずは気軽に 2〜5 個ほど登録すると、プロフィールの雰囲気が伝わりやすくなります。
            </p>
          </div>
          <div data-tag-autocomplete-target="count"
               data-testid="tag-count"
               class="text-xs font-medium tracking-wide text-slate-500">0 / 10件</div>
        </div>

        <%# ヘルプコンテンツ（toggle_controller の connect() で hidden が付与される）%>
        <div data-toggle-target="content"
             data-testid="tag-help-content"
             class="mb-4 rounded-xl border border-slate-700/50 bg-slate-900/60 p-4 text-sm text-slate-300 leading-relaxed">
          <p class="font-semibold text-slate-200 mb-2">親タグとは？</p>
          <p class="mb-3">趣味タグを大きなカテゴリでまとめるラベルです。登録したタグに合う親タグを選ぶと、どんな系統の趣味か一目で伝わりやすくなります。</p>
          <ul class="mb-3 space-y-1 list-none pl-0">
            <li>🗨️ <span class="font-medium text-slate-200">雑談系</span> — アニメ・マンガ・映画・料理 など</li>
            <li>📚 <span class="font-medium text-slate-200">学習系</span> — プログラミング・語学・資格 など</li>
            <li>🎮 <span class="font-medium text-slate-200">ゲーム系</span> — RPG・FPS・ボードゲーム など</li>
          </ul>
          <p class="text-slate-400">迷った場合は「わからない」を選んでも大丈夫です。あとから変更できます。</p>
        </div>
      </div>
```

### spec 実行（全通過を確認）

```bash
docker compose exec web bundle exec rspec spec/system/my/profile_tag_help_spec.rb
```

期待出力: `3 examples, 0 failures`

### 既存 spec への影響確認

```bash
docker compose exec web bundle exec rspec spec/system/my/
```

期待出力: `0 failures`

---

## Task 3: REFACTOR + コミット

### RuboCop チェック

```bash
docker compose exec web bundle exec rubocop
```

期待出力: `no offenses detected`

### コミット（2 回に分けて実行）

```bash
# 1. spec コミット
git add spec/system/my/profile_tag_help_spec.rb
git commit -m "test: 趣味タグヘルプ導線の system spec を追加 #247"

# 2. ビューコミット
git add app/views/my/profiles/_form.html.erb
git commit -m "feat: 趣味タグセクションに親タグヘルプ導線を追加 #247"
```

---

## 受入条件（完了チェック）

- [ ] 趣味タグ見出し横に「親タグとは？」ボタンが表示される
- [ ] クリックするとインラインでヘルプコンテンツが展開される
- [ ] 親タグの説明・具体例（雑談系/学習系/ゲーム系）が含まれる
- [ ] 「迷った場合は『わからない』でよい」旨が含まれる
- [ ] 「閉じる」クリックで折りたたまれる
- [ ] system spec 全通過 / RuboCop 全通過
