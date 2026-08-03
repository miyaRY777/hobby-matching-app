# Parent Tag Detail Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 親タグ関連ユーザーの情報バッジを右ペイン上部の `詳細` 横へ表示し、説明文量にかかわらずページネーションを右ペイン下部へ固定する。

**Architecture:** `member_detail` Turbo Frameの更新範囲を、右ペインの見出し行と外枠の両方へ広げる。見出しは共通partialで描画し、親タグ表示だけ青い情報バッジを渡す。親タグ一覧の外枠は固定高のFlexboxとし、カード領域だけをスクロール可能、ページネーションを縮まない最下部要素にする。

**Tech Stack:** Ruby on Rails ERB、Turbo Frame、Tailwind CSS、Kaminari、RSpec System Spec、Capybara/Selenium

## Global Constraints

- 作業リポジトリは `/Users/miyary777/workspace/miyaRY777/Runteq/hobby-matching-app` とする。
- 作業ブランチは `codex/issue-282-parent-tag-members` とする。
- マインドマップ、右ペインの外枠寸法、ユーザー抽出条件、カードに表示する趣味タグの条件は変更しない。
- DBスキーマ、ルーティング、認証・認可、1ページ1人の仕様は変更しない。
- 親タグ選択、ページ移動、個別ユーザー選択では `member_detail` Turbo Frameだけを更新する。
- 既存の未追跡ファイルを編集、ステージ、コミットしない。
- 確認コマンドは `docker compose exec web` 経由で実行する。

---

### Task 1: 右ペイン見出しと固定ページネーション

**Files:**
- Create: `app/views/rooms/members/_detail_heading.html.erb`
- Modify: `app/views/shares/show.html.erb`
- Modify: `app/views/rooms/members/show.html.erb`
- Modify: `app/views/rooms/parent_tag_members/index.html.erb`
- Test: `spec/system/rooms/parent_tag_members_spec.rb`
- Test: `spec/system/rooms/share_layout_stability_spec.rb`

**Interfaces:**
- Consumes: `member_detail` Turbo Frameの既存`src`更新、`@parent_tag.name`、`@profiles.total_count`、`@profile`、`@room_related_phs`、Kaminariの`paginate`。
- Produces: `rooms/members/detail_heading` partial。local `summary_text`は`String`または`nil`。`nil`では`詳細`だけ、文字列では`詳細`の右に青いバッジを描画する。
- Produces: `[data-testid="member-detail-panel"]` は高さ624pxの右ペイン外枠、`[data-testid="member-detail-scroll-area"]` は縦スクロール領域、`[data-testid="member-detail-pagination"]` は下部固定領域。

- [ ] **Step 1: 見出し切り替えと固定位置を再現する失敗テストを書く**

`spec/system/rooms/parent_tag_members_spec.rb` の既存データで、2人目の説明文を十分長くする。

```ruby
create(
  :profile_hobby,
  profile: second_profile,
  hobby:,
  description: "second description " * 80
)
```

既存の「親タグ選択とページ送り」の例へ、見出しとバッジの責務を追加する。

```ruby
within("turbo-frame#member_detail") do
  expect(page).to have_css("[data-testid='member-detail-heading']", text: "詳細")
  expect(page).to have_css(
    "[data-testid='parent-tag-member-summary']",
    text: "ゲームに関連するユーザー 2人"
  )

  click_link "次へ ›"

  expect(page).to have_text("demo_user2")
  expect(page).to have_css(
    "[data-testid='parent-tag-member-summary']",
    text: "ゲームに関連するユーザー 2人"
  )
end
```

個別ユーザー切り替えの例では、`詳細`が残り、バッジだけが消えることを追加する。

```ruby
within("turbo-frame#member_detail") do
  expect(page).to have_css("[data-testid='member-detail-heading']", text: "詳細")
  expect(page).to have_no_css("[data-testid='parent-tag-member-summary']")
end
```

ページネーション位置の例を追加する。短い説明文を開いた1ページ目と、長い説明文を開いた2ページ目で、ページネーション下端が変わらないことをブラウザ上の座標で確認する。

```ruby
it "説明文量が変わってもページネーションを右ペイン下部に固定する" do
  find("jmnode[nodeid='pt_#{parent_tag.id}']").click

  within("turbo-frame#member_detail") do
    click_button "Among Us"
    first_bottom = page.evaluate_script(<<~JS)
      document.querySelector('[data-testid="member-detail-pagination"]')
        .getBoundingClientRect().bottom
    JS

    click_link "次へ ›"
    expect(page).to have_text("demo_user2")
    click_button "Among Us"
    second_bottom = page.evaluate_script(<<~JS)
      document.querySelector('[data-testid="member-detail-pagination"]')
        .getBoundingClientRect().bottom
    JS

    expect(second_bottom).to be_within(1).of(first_bottom)
    expect(page).to have_css("[data-testid='member-detail-scroll-area']")
  end
end
```

- [ ] **Step 2: 新規System SpecがREDになることを確認する**

Run:

```bash
docker compose exec web bundle exec rspec spec/system/rooms/parent_tag_members_spec.rb
```

Expected: FAIL。`data-testid='member-detail-heading'`、`parent-tag-member-summary`、`member-detail-pagination`が未実装で見つからない。

- [ ] **Step 3: 共通見出しpartialを作る**

`app/views/rooms/members/_detail_heading.html.erb`:

```erb
<div class="mb-4 flex min-h-[48px] flex-wrap items-center gap-3"
     data-testid="member-detail-heading">
  <span class="text-lg font-semibold tracking-wide text-slate-200">詳細</span>
  <% if summary_text.present? %>
    <span class="inline-flex items-center rounded-full border border-blue-400/40 bg-blue-500/15 px-3 py-1 text-sm font-semibold text-blue-300"
          data-testid="parent-tag-member-summary">
      <%= summary_text %>
    </span>
  <% end %>
</div>
```

- [ ] **Step 4: 初期表示のTurbo Frameへ見出しと外枠を含める**

`app/views/shares/show.html.erb` の右カラムは、既存の見出しと外枠の外側にあったTurbo Frameを次の構造へ変更する。

```erb
<div class="min-w-0">
  <turbo-frame id="member_detail">
    <%= render "rooms/members/detail_heading", summary_text: nil %>
    <div class="flex h-[624px] min-h-0 flex-col rounded-[24px] border border-white/10 bg-slate-900/25 p-4 shadow-[0_18px_40px_rgba(2,6,23,0.22)]"
         data-testid="member-detail-panel">
      <div class="min-h-0 flex-1 overflow-y-auto"
           data-testid="member-detail-scroll-area">
        <div class="w-full rounded-[20px] border border-white/10 bg-[linear-gradient(180deg,rgba(255,255,255,0.98),rgba(248,250,252,0.96))] px-6 py-10 text-center text-sm text-slate-400 shadow-[0_24px_60px_rgba(15,23,42,0.18)]">
          左のマインドマップからメンバーを選択してください
        </div>
      </div>
    </div>
  </turbo-frame>
</div>
```

- [ ] **Step 5: 個別ユーザー表示でも見出しと同じ外枠を返す**

`app/views/rooms/members/show.html.erb`:

```erb
<turbo-frame id="member_detail">
  <%= render "rooms/members/detail_heading", summary_text: nil %>
  <div class="flex h-[624px] min-h-0 flex-col rounded-[24px] border border-white/10 bg-slate-900/25 p-4 shadow-[0_18px_40px_rgba(2,6,23,0.22)]"
       data-testid="member-detail-panel">
    <div class="min-h-0 flex-1 overflow-y-auto"
         data-testid="member-detail-scroll-area">
      <%= render "rooms/members/card", profile: @profile, room_related_phs: @room_related_phs %>
    </div>
  </div>
</turbo-frame>
```

- [ ] **Step 6: 親タグ表示で青いバッジと下部固定ページネーションを返す**

`app/views/rooms/parent_tag_members/index.html.erb`:

```erb
<turbo-frame id="member_detail">
  <%= render "rooms/members/detail_heading",
             summary_text: "#{@parent_tag.name}に関連するユーザー #{@profiles.total_count}人" %>

  <div class="flex h-[624px] min-h-0 flex-col gap-4 rounded-[24px] border border-white/10 bg-slate-900/25 p-4 shadow-[0_18px_40px_rgba(2,6,23,0.22)]"
       data-testid="member-detail-panel">
    <div class="min-h-0 flex-1 overflow-y-auto"
         data-testid="member-detail-scroll-area">
      <% if @profile %>
        <%= render "rooms/members/card", profile: @profile, room_related_phs: @room_related_phs %>
      <% else %>
        <p class="text-slate-400">該当するユーザーはいません</p>
      <% end %>
    </div>

    <% if @profiles.total_pages > 1 %>
      <div class="shrink-0" data-testid="member-detail-pagination">
        <%= paginate @profiles %>
      </div>
    <% end %>
  </div>
</turbo-frame>
```

- [ ] **Step 7: 対象System SpecをGREENにする**

Run:

```bash
docker compose exec web bundle exec rspec spec/system/rooms/parent_tag_members_spec.rb spec/system/rooms/share_layout_stability_spec.rb
```

Expected: PASS。親タグ表示、ページ移動、個別ユーザー切り替え、説明文タブ、横位置維持がすべて成功する。

- [ ] **Step 8: 関連Request SpecとView回帰を確認する**

Run:

```bash
docker compose exec web bundle exec rspec \
  spec/requests/rooms/parent_tag_members_index_spec.rb \
  spec/requests/rooms/members_show_spec.rb \
  spec/system/rooms/member_detail_tag_toggle_spec.rb
```

Expected: PASS。認証・認可、空状態、範囲外ページ、カード内容、既存タブ切り替えが維持される。

- [ ] **Step 9: 全体検証を行う**

Run:

```bash
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rubocop
docker compose exec web yarn build
docker compose exec web yarn build:css
git diff --check
```

Expected: RSpec 0 failures、RuboCop 0 offenses、JavaScript/CSS build exit 0、`git diff --check` exit 0。

- [ ] **Step 10: コミット前にユーザー確認を取り、承認後にコミットする**

対象ファイルを次の5ファイルに限定する。

```bash
git add \
  app/views/rooms/members/_detail_heading.html.erb \
  app/views/shares/show.html.erb \
  app/views/rooms/members/show.html.erb \
  app/views/rooms/parent_tag_members/index.html.erb \
  spec/system/rooms/parent_tag_members_spec.rb
git diff --cached --check
git diff --cached --stat
git commit -m "fix: 親タグ詳細の見出しとページネーションを調整 #282"
```

Expected: ユーザー所有の未追跡ファイルを含まず、上記5ファイルだけをコミットする。
