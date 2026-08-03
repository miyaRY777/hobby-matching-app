# Parent Tag Member Cards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 親タグ選択時に、関連ユーザー全員のカードをページネーションなしで右ペインへ縦並び表示し、カードごとに説明文を独立して展開できるようにする。

**Architecture:** 既存の`RoomParentTagProfilesQuery`が返すeager load済みRelationをページングせず配列化し、コントローラで各プロフィールと部屋カテゴリー関連趣味の組を作る。ERBは全カードを固定高のスクロール領域へ描画し、既存のカード単位Stimulus `tabs` controllerによって複数カードの説明状態を独立させる。

**Tech Stack:** Ruby on Rails、ActiveRecord、ERB、Turbo Frame、Stimulus、RSpec Request/System Spec、Capybara、ActiveSupport::Notifications

## Global Constraints

- 作業リポジトリは `/Users/miyary777/workspace/miyaRY777/Runteq/hobby-matching-app` とする。
- 作業ブランチは `codex/issue-284-parent-tag-member-cards` とする。
- Issue #284の範囲だけを変更する。
- DBスキーマ、公開API、ルーティング、認証・認可を変更しない。
- 右ペイン外枠は624px固定高、青い情報バッジ、2カラム幅を維持する。
- 個別ユーザーノード選択時は従来の1人表示を維持する。
- 親タグ表示ではページネーションを完全に削除し、`page`パラメータを使用しない。
- カードには部屋カテゴリーに関連する趣味タグを従来どおり表示する。
- 既存の未追跡ファイルを編集、ステージ、コミットしない。
- 確認コマンドは`docker compose exec web`経由で実行する。

---

### Task 1: 関連ユーザー全員のカード一覧と独立タブ

**Files:**
- Modify: `app/controllers/rooms/parent_tag_members_controller.rb`
- Modify: `app/views/rooms/parent_tag_members/index.html.erb`
- Modify: `app/views/rooms/members/_card.html.erb`
- Modify: `spec/requests/rooms/parent_tag_members_index_spec.rb`
- Modify: `spec/system/rooms/parent_tag_members_spec.rb`

**Interfaces:**
- Consumes: `RoomParentTagProfilesQuery.call(room:, parent_tag:) -> ActiveRecord::Relation<Profile>`。RelationはプロフィールID昇順、重複排除、`profile_hobbies.hobby.hobby_parent_tags`、`user.avatar_attachment.blob`を事前読込済み。
- Produces: `@profile_cards -> Array<Hash>`。各要素は`{ profile: Profile, room_related_phs: Array<ProfileHobby> }`。
- Produces: `data-testid="member-card"`と`data-profile-id="<profile.id>"`を持つカードDOM。
- Produces: `data-testid="member-detail-scroll-area"`内に全カードを描画し、`member-detail-pagination`を描画しない。

- [ ] **Step 1: Request Specを全カード表示仕様へ変更する**

`spec/requests/rooms/parent_tag_members_index_spec.rb`の「プロフィールID昇順で1人ずつ表示する」と「範囲外ページでは最終ページを表示する」を削除し、全員表示とページ番号無視を1関心ずつ検証する。

```ruby
it "プロフィールID昇順で関連ユーザー全員を表示する" do
  first_profile = create_member("first_user")
  second_profile = create_member("second_user")
  third_profile = create_member("third_user")

  get room_parent_tag_members_path(room_id: room.id, parent_tag_id: parent_tag.id)

  expect(response.body).to include("関連ユーザー：3人")
  expect(response.body).to include("first_user", "second_user", "third_user")
  expect(response.body.index("first_user")).to be < response.body.index("second_user")
  expect(response.body.index("second_user")).to be < response.body.index("third_user")
  expect(response.body.scan("data-profile-id=\"#{first_profile.id}\"").size).to eq(1)
  expect(response.body.scan("data-profile-id=\"#{second_profile.id}\"").size).to eq(1)
  expect(response.body.scan("data-profile-id=\"#{third_profile.id}\"").size).to eq(1)
  expect(response.body).not_to include("member-detail-pagination", "次へ", "前へ")
end
```

```ruby
it "pageパラメータが指定されても全員を表示する" do
  create_member("first_user")
  create_member("second_user")

  get room_parent_tag_members_path(
    room_id: room.id,
    parent_tag_id: parent_tag.id,
    page: 99
  )

  expect(response.body).to include("first_user", "second_user")
  expect(response.body).not_to include("member-detail-pagination")
end
```

空状態、認証・認可、部屋カテゴリー別タグ表示の既存例は維持する。

- [ ] **Step 2: Request SpecがREDになることを確認する**

Run:

```bash
docker compose exec web bundle exec rspec spec/requests/rooms/parent_tag_members_index_spec.rb
```

Expected: FAIL。現在は1ページ1人のため2人目以降がなく、`data-profile-id`も未実装で、ページネーションが存在する。

- [ ] **Step 3: System Specを縦並び・独立展開仕様へ変更する**

`spec/system/rooms/parent_tag_members_spec.rb`へ3人目を追加する。

```ruby
let!(:third_profile) { create_member("demo_user3") }
```

`before`で3人目にも同じ親タグの趣味を紐付ける。

```ruby
create(
  :profile_hobby,
  profile: third_profile,
  hobby:,
  description: "third description"
)
```

既存のページ送り例を、全カード表示とページネーション非表示へ置き換える。

```ruby
it "親タグ選択で関連ユーザー全員のカードを縦並び表示する" do
  find("jmnode[nodeid='pt_#{parent_tag.id}']").click

  within("turbo-frame#member_detail") do
    expect(page).to have_css(
      "[data-testid='parent-tag-member-summary']",
      text: "関連ユーザー：3人"
    )
    cards = all("[data-testid='member-card']")
    expect(cards.map { |card| card["data-profile-id"] }).to eq(
      [first_profile.id, second_profile.id, third_profile.id].map(&:to_s)
    )
    expect(page).to have_text("demo_user1")
    expect(page).to have_text("demo_user2")
    expect(page).to have_text("demo_user3")
    expect(page).to have_no_css("[data-testid='member-detail-pagination']")
  end
end
```

ユーザー2の説明を開いても全カードが残る例を追加する。

```ruby
it "対象カード内で説明を開いても他ユーザーのカードを維持する" do
  find("jmnode[nodeid='pt_#{parent_tag.id}']").click

  within(member_card(second_profile)) do
    click_button "Among Us"
    expect(page).to have_text("second description")
  end

  within("turbo-frame#member_detail") do
    expect(page).to have_css("[data-profile-id='#{first_profile.id}']")
    expect(page).to have_css("[data-profile-id='#{second_profile.id}']", text: "second description")
    expect(page).to have_css("[data-profile-id='#{third_profile.id}']")
  end
end
```

複数ユーザーの説明を同時に開く例を追加する。

```ruby
it "複数ユーザーの説明を同時に開ける" do
  find("jmnode[nodeid='pt_#{parent_tag.id}']").click

  within(member_card(first_profile)) { click_button "Among Us" }
  within(member_card(second_profile)) { click_button "💬 自己紹介" }

  within(member_card(first_profile)) do
    expect(page).to have_text("first description")
  end
  within(member_card(second_profile)) do
    expect(page).to have_text(long_bio)
  end
end
```

右ペインの実overflowを検証する。

```ruby
it "展開したカード一覧を右ペイン内で縦スクロールできる" do
  find("jmnode[nodeid='pt_#{parent_tag.id}']").click

  within(member_card(first_profile)) { click_button "Among Us" }
  within(member_card(second_profile)) { click_button "💬 自己紹介" }

  metrics = page.evaluate_script(<<~JS)
    (() => {
      const area = document.querySelector('[data-testid="member-detail-scroll-area"]');
      return {
        overflowY: window.getComputedStyle(area).overflowY,
        scrollHeight: area.scrollHeight,
        clientHeight: area.clientHeight
      };
    })()
  JS

  expect(metrics["overflowY"]).to eq("auto")
  expect(metrics["scrollHeight"]).to be > metrics["clientHeight"]
end
```

System Spec helperを追加する。

```ruby
def member_card(profile)
  find("[data-testid='member-card'][data-profile-id='#{profile.id}']")
end
```

個別ユーザーノード選択、青バッジ配色、カード内タブ動作の既存検証は維持する。ページネーション位置を検証していた例は削除する。

- [ ] **Step 4: System SpecがREDになることを確認する**

Run:

```bash
docker compose exec web bundle exec rspec spec/system/rooms/parent_tag_members_spec.rb
```

Expected: FAIL。現在は1カードだけで、`member-card`識別属性と3人分の同時表示が存在しない。

- [ ] **Step 5: コントローラをページングなしの全カードデータへ変更する**

`app/controllers/rooms/parent_tag_members_controller.rb#index`:

```ruby
def index
  profiles = RoomParentTagProfilesQuery.call(room: @room, parent_tag: @parent_tag).to_a
  @profile_cards = profiles.map do |profile|
    {
      profile:,
      room_related_phs: room_related_profile_hobbies(profile)
    }
  end
end
```

次を削除する。

- `.page(params[:page]).per(1)`
- 範囲外ページの補正
- `@profile`
- 単一プロフィール用の`@room_related_phs`

`room_related_profile_hobbies(profile)`は、eager load済み関連をメモリ上で絞り込む既存実装を維持する。

- [ ] **Step 6: 全カードをスクロール領域へ描画する**

`app/views/rooms/parent_tag_members/index.html.erb`:

```erb
<turbo-frame id="member_detail">
  <%= render "rooms/members/detail_heading",
             summary_text: "関連ユーザー：#{@profile_cards.size}人" %>

  <div class="flex h-[624px] min-h-0 min-h-[624px] flex-col rounded-[24px] border border-white/10 bg-slate-900/25 p-4 shadow-[0_18px_40px_rgba(2,6,23,0.22)]"
       data-testid="member-detail-panel">
    <div class="min-h-0 flex-1 space-y-4 overflow-y-auto"
         data-testid="member-detail-scroll-area">
      <% if @profile_cards.any? %>
        <% @profile_cards.each do |card| %>
          <%= render "rooms/members/card",
                     profile: card[:profile],
                     room_related_phs: card[:room_related_phs] %>
        <% end %>
      <% else %>
        <p class="text-slate-400">該当するユーザーはいません</p>
      <% end %>
    </div>
  </div>
</turbo-frame>
```

ページネーションwrapperと`paginate @profiles`を削除する。

- [ ] **Step 7: カードへ安定した識別属性を追加する**

`app/views/rooms/members/_card.html.erb`の最上位`div`へ属性を追加する。既存のstyleは変更しない。

```erb
<div data-testid="member-card"
     data-profile-id="<%= profile.id %>"
     style="padding: 1rem; ...">
```

カードごとの`data-controller="tabs"`は維持し、カード間で状態を共有しない。

- [ ] **Step 8: Request/System SpecをGREENにする**

Run:

```bash
docker compose exec web bundle exec rspec \
  spec/requests/rooms/parent_tag_members_index_spec.rb \
  spec/system/rooms/parent_tag_members_spec.rb
```

Expected: PASS。全カード、ID昇順、重複なし、独立タブ、内部スクロール、ページネーション非表示を確認できる。

- [ ] **Step 9: N+1回帰テストを追加する**

`spec/requests/rooms/parent_tag_members_index_spec.rb`へ、1人時と5人時のSELECT数が等しい例を追加する。通知対象はリクエスト中だけとし、SCHEMA、TRANSACTION、キャッシュ済みSQLを除外する。

```ruby
it "関連ユーザー数が増えてもSELECT数が増えない" do
  create_member("member_1")
  one_member_queries = select_queries_for_parent_tag_request

  4.times { |index| create_member("member_#{index + 2}") }
  five_member_queries = select_queries_for_parent_tag_request

  expect(five_member_queries.size).to eq(one_member_queries.size)
end
```

```ruby
def select_queries_for_parent_tag_request
  queries = []
  subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
    next if payload[:cached]
    next unless payload[:sql].match?(/\ASELECT/i)

    queries << payload[:sql]
  end

  get room_parent_tag_members_path(room_id: room.id, parent_tag_id: parent_tag.id)
  queries
ensure
  ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
end
```

Run:

```bash
docker compose exec web bundle exec rspec spec/requests/rooms/parent_tag_members_index_spec.rb
```

Expected: PASS。1人時と5人時のSELECT数が同数。

- [ ] **Step 10: 関連回帰テストを実行する**

Run:

```bash
docker compose exec web bundle exec rspec \
  spec/queries/room_parent_tag_profiles_query_spec.rb \
  spec/requests/rooms/members_show_spec.rb \
  spec/services/jsmind_data_builder_spec.rb \
  spec/system/rooms/member_detail_tag_toggle_spec.rb \
  spec/system/shares/layout_stability_spec.rb
```

Expected: PASS。検索条件、認証・認可、個別表示、jsMind URL、既存タブ、横幅を維持する。

- [ ] **Step 11: 全体検証を行う**

Run:

```bash
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rubocop
docker compose exec web yarn build
docker compose exec web yarn build:css
git diff --check
```

Expected: RSpec 0 failures、RuboCop 0 offenses、JavaScript/CSS build exit 0、`git diff --check` exit 0。

- [ ] **Step 12: コミット前にユーザー確認を取り、承認後にコミットする**

対象を次の5ファイルに限定する。

```bash
git add \
  app/controllers/rooms/parent_tag_members_controller.rb \
  app/views/rooms/parent_tag_members/index.html.erb \
  app/views/rooms/members/_card.html.erb \
  spec/requests/rooms/parent_tag_members_index_spec.rb \
  spec/system/rooms/parent_tag_members_spec.rb
git diff --cached --check
git diff --cached --stat
git commit -m "feat: 親タグ関連ユーザーをカード一覧で表示 #284"
```

Expected: ユーザー所有の未追跡ファイルを含まず、上記5ファイルだけをコミットする。
