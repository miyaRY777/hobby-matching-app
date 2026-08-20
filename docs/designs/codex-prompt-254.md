# Codex 実装プロンプト：Issue #254 UI微修正3件

## コンテキスト

- **リポジトリ:** hobby-matching-app（Ruby on Rails）
- **ブランチ:** `feature/254-ui-minor-improvements`
- **実行環境:** `docker compose exec web` 経由でコマンドを実行する
- **Issue:** #254

## 背景

以下の3件のUI微修正を実装する。DBマイグレーション不要。

1. **「部屋に戻る」をCookie優先に変更** — 最後に参加した部屋ではなく、最後に開いた共有ページを指すようにする
2. **プロフィール作成後のリダイレクト先変更** — 公開プロフィールではなくマイページへ遷移させる
3. **公開部屋一覧の参加確認モーダル追加** — 「参加する」クリックで部屋詳細・参加者一覧を表示するモーダルを出す

## 重要なルール

- **必ずTDD（RED → GREEN → REFACTOR）で進める**
- 実装より先にテストを書く
- コマンドはすべて `docker compose exec web` 経由
- マイグレーション不要（既存スキーマで対応）

## 既存コードの理解

### ApplicationHelper#recent_room_nav_path（変更対象）

```ruby
# app/helpers/application_helper.rb
def recent_room_nav_path(user)
  profile = user&.profile
  return nil unless profile

  room = profile.last_joined_room_with_share_link
  return nil unless room

  room.shareable? ? share_path(room.share_link.token) : mypage_rooms_path
end
```

### SharesController#show（変更対象）

```ruby
# app/controllers/shares_controller.rb
def show
  @share_link     = ShareLink.includes(:room).find_by!(token: params[:token])
  @room           = @share_link.room
  @viewer_profile = current_user.profile

  authorize! @share_link, to: :show?

  RoomMembership.find_or_create_by!(room: @room, profile: @viewer_profile) if @viewer_profile
  @memberships = memberships_for_display
  @jsmind_data = JsmindDataBuilder.new(@room, @memberships).build
end
```

### My::ProfilesController#create（変更対象）

```ruby
# app/controllers/my/profiles_controller.rb
def create
  @profile = current_user.build_profile(profile_params.except(:hobbies_text))
  @profile.hobbies_text = profile_params[:hobbies_text]

  ApplicationRecord.transaction do
    @profile.save!
    @profile.update_hobbies_from_json(@profile.hobbies_text)
  end
  redirect_to profile_path(@profile), notice: "プロフィールを作成しました"  # ← ここを変更
rescue ActiveRecord::RecordInvalid
  @hobbies_text = @profile.hobbies_text
  flash.now[:alert] = "プロフィールを作成できませんでした"
  render :new, status: :unprocessable_entity
end
```

### RoomsController#index（変更対象）

```ruby
# app/controllers/rooms_controller.rb
def index
  @rooms = Room.unlocked
               .includes(issuer_profile: :user, room_memberships: :profile)  # ← room_memberships: { profile: :user } に変更
               .order(created_at: :desc)

  profile = current_user.profile
  @joined_room_ids = profile&.joined_room_ids || []
  @issued_room_ids = profile&.issued_room_ids || []
end
```

### modal_controller.js（変更しない。参考のみ）

```javascript
// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  open() {
    this.panelTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.panelTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }
}
```

### User#display_name

```ruby
# app/models/user.rb
def display_name
  nickname.presence || email
end
```

### rooms/_room.html.erb（変更対象）

```erb
<%# 操作列（46〜54行目付近）%>
<td style="padding: 1rem 1.25rem; vertical-align: middle;">
  <% unless issued || joined %>
    <%= button_to "参加する",
                  mypage_room_memberships_path,
                  params: { room_id: room.id },
                  style: "display: inline-flex; ..." %>
  <% else %>
    <span style="font-size: 0.875rem; color: #6b7280;">なし</span>
  <% end %>
</td>
```

### 既存 system spec の認証パターン

```ruby
# request spec: sign_in ヘルパーを使う
sign_in user

# system spec: login_as ヘルパーを使う
login_as(user, scope: :user)
```

### FactoryBot 定義（参考）

```ruby
# spec/factories/users.rb
factory :user do
  sequence(:email) { |n| "test#{n}@example.com" }
  password { "password123" }
  nickname { "test_user" }
end

# spec/factories/profiles.rb
factory :profile do
  user
  bio { "自己紹介文" }
end

# spec/factories/rooms.rb
factory :room do
  association :issuer_profile, factory: :profile
  label { "テスト部屋" }
  locked { false }
end

# spec/factories/room_memberships.rb
factory :room_membership do
  room
  profile
end

# spec/factories/share_links.rb
factory :share_link do
  room { nil }
  token { "MyString" }
  expires_at { "2026-02-17 15:23:34" }
end
```

---

## Task 1：プロフィール作成後のリダイレクト先変更

### 対象ファイル

- 修正: `app/controllers/my/profiles_controller.rb`（19行目）
- テスト: `spec/requests/my/profile_spec.rb`

### Step 1: 失敗するテストを書く

`spec/requests/my/profile_spec.rb` の `describe "POST /my/profile"` ブロック内に追加：

```ruby
it "作成成功後にマイページへリダイレクトする" do
  hobbies_text = [ { name: "ゲーム", description: "" } ].to_json

  post my_profile_path, params: { profile: { bio: "自己紹介", hobbies_text: } }

  expect(response).to redirect_to(mypage_root_path)
end
```

### Step 2: テスト実行 → 失敗確認

```bash
docker compose exec web bundle exec rspec spec/requests/my/profile_spec.rb
```

期待出力: `FAILED (expected redirect to /mypage but got /profiles/...)`

### Step 3: 最小実装

`app/controllers/my/profiles_controller.rb` の19行目を変更：

```ruby
# 変更前
redirect_to profile_path(@profile), notice: "プロフィールを作成しました"

# 変更後
redirect_to mypage_root_path, notice: "プロフィールを作成しました"
```

### Step 4: テスト実行 → 成功確認

```bash
docker compose exec web bundle exec rspec spec/requests/my/profile_spec.rb
```

期待出力: `4 examples, 0 failures`

### Step 5: コミット

```bash
git add app/controllers/my/profiles_controller.rb spec/requests/my/profile_spec.rb
git commit -m "improve: プロフィール作成後のリダイレクト先をマイページに変更 #254"
```

---

## Task 2：共有ページ訪問時のCookie保存

### 対象ファイル

- 修正: `app/controllers/shares_controller.rb`
- テスト: `spec/requests/shares_spec.rb`

### Step 1: 失敗するテストを書く

`spec/requests/shares_spec.rb` の `describe "GET /share/:token"` 内に追加：

```ruby
context "公開部屋にアクセスした場合" do
  it "recent_room_token CookieにトークンがセットされるYou" do
    # セットアップ
    owner = create(:user)
    owner_profile = create(:profile, user: owner)
    room = create(:room, issuer_profile: owner_profile, locked: false)
    create(:share_link, room: room, expires_at: nil, token: "cookietoken")
    member = create(:user)
    create(:profile, user: member)
    sign_in member

    # アクション
    get share_path("cookietoken")

    # アサーション
    expect(response.cookies["recent_room_token"]).to eq("cookietoken")
  end
end
```

### Step 2: テスト実行 → 失敗確認

```bash
docker compose exec web bundle exec rspec spec/requests/shares_spec.rb
```

期待出力: `FAILED (expected "cookietoken" but got nil)`

### Step 3: 最小実装

`app/controllers/shares_controller.rb` の `show` アクションに `cookies` セットを追加：

```ruby
def show
  @share_link     = ShareLink.includes(:room).find_by!(token: params[:token])
  @room           = @share_link.room
  @viewer_profile = current_user.profile

  authorize! @share_link, to: :show?

  cookies[:recent_room_token] = { value: params[:token], expires: 1.year.from_now }

  RoomMembership.find_or_create_by!(room: @room, profile: @viewer_profile) if @viewer_profile
  @memberships = memberships_for_display
  @jsmind_data = JsmindDataBuilder.new(@room, @memberships).build
end
```

### Step 4: テスト実行 → 成功確認

```bash
docker compose exec web bundle exec rspec spec/requests/shares_spec.rb
```

期待出力: `6 examples, 0 failures`

### Step 5: コミット

```bash
git add app/controllers/shares_controller.rb spec/requests/shares_spec.rb
git commit -m "improve: 共有ページ訪問時にCookieへトークンを保存 #254"
```

---

## Task 3：ヘルパーのCookie優先ロジック

### 対象ファイル

- 修正: `app/helpers/application_helper.rb`
- テスト: `spec/helpers/application_helper_spec.rb`

### Step 1: 失敗するテストを書く

`spec/helpers/application_helper_spec.rb` の `describe "#recent_room_nav_path"` 内に追加：

```ruby
context "CookieにトークンがセットされているYou場合" do
  it "DBを参照せずCookieのトークンでshare_pathを返す" do
    # セットアップ：Cookieをスタブ
    allow(helper).to receive(:cookies).and_return({ "recent_room_token" => "tok456" })

    # アクション＋アサーション：nilユーザーでもshare_pathを返すこと
    expect(helper.recent_room_nav_path(nil)).to eq(share_path("tok456"))
  end
end
```

### Step 2: テスト実行 → 失敗確認

```bash
docker compose exec web bundle exec rspec spec/helpers/application_helper_spec.rb
```

期待出力: `FAILED (expected share_path("tok456") but got nil)`

### Step 3: 最小実装

`app/helpers/application_helper.rb` の `recent_room_nav_path` を以下に変更：

```ruby
def recent_room_nav_path(user)
  token = cookies[:recent_room_token]
  return share_path(token) if token.present?

  profile = user&.profile
  return nil unless profile

  room = profile.last_joined_room_with_share_link
  return nil unless room

  room.shareable? ? share_path(room.share_link.token) : mypage_rooms_path
end
```

### Step 4: テスト実行 → 成功確認

```bash
docker compose exec web bundle exec rspec spec/helpers/application_helper_spec.rb
```

期待出力: `6 examples, 0 failures`

### Step 5: コミット

```bash
git add app/helpers/application_helper.rb spec/helpers/application_helper_spec.rb
git commit -m "improve: 部屋に戻るリンクをCookie優先ロジックに変更 #254"
```

---

## Task 4：公開部屋一覧の参加確認モーダル

### 対象ファイル

- 修正: `app/controllers/rooms_controller.rb`
- 新規: `app/javascript/controllers/room_modal_controller.js`
- 修正: `app/views/rooms/index.html.erb`
- 修正: `app/views/rooms/_room.html.erb`
- テスト: `spec/system/rooms_spec.rb`

### Step 1: 失敗するシステムスペックを書く

`spec/system/rooms_spec.rb` に以下を追加し、既存の「参加するボタンを押すと参加済みバッジに変わる」テストを削除する（モーダル経由のテストに置き換え）：

```ruby
it "参加するボタンをクリックするとモーダルが開く" do
  # アクション
  visit rooms_path

  within find("[id='#{ActionView::RecordIdentifier.dom_id(unjoined_room)}']") do
    click_button "参加する"
  end

  # アサーション：モーダルに部屋名が表示される
  expect(page).to have_css("[data-room-modal-target='panel']")
  expect(page).to have_text("未参加の部屋")
end

it "モーダルの参加するボタンを押すと参加済みバッジに変わる" do
  # アクション
  visit rooms_path

  within find("[id='#{ActionView::RecordIdentifier.dom_id(unjoined_room)}']") do
    click_button "参加する"
  end

  within("[data-room-modal-target='panel']") do
    click_button "参加する"
  end

  # アサーション
  within find("[id='#{ActionView::RecordIdentifier.dom_id(unjoined_room)}']") do
    expect(page).to have_text("参加済み")
    expect(page).to have_no_button("参加する")
  end
  expect(RoomMembership.exists?(room: unjoined_room, profile: current_profile)).to be true
end

it "モーダルの一覧に戻るボタンを押すとモーダルが閉じる" do
  # アクション
  visit rooms_path

  within find("[id='#{ActionView::RecordIdentifier.dom_id(unjoined_room)}']") do
    click_button "参加する"
  end

  within("[data-room-modal-target='panel']") do
    click_button "一覧に戻る"
  end

  # アサーション：モーダルが非表示になる
  expect(page).to have_css("[data-room-modal-target='panel'].hidden")
end
```

### Step 2: テスト実行 → 失敗確認

```bash
docker compose exec web bundle exec rspec spec/system/rooms_spec.rb
```

期待出力: `FAILED`（モーダルが存在しないため）

### Step 3a: rooms_controller.rb の includes 変更

`app/controllers/rooms_controller.rb` の `includes` を変更：

```ruby
@rooms = Room.unlocked
             .includes(issuer_profile: :user, room_memberships: { profile: :user })
             .order(created_at: :desc)
```

### Step 3b: room_modal_controller.js を新規作成

```javascript
// app/javascript/controllers/room_modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "name", "badge", "creator", "memberCount", "membersList", "roomId"]

  open(event) {
    const btn = event.currentTarget
    this.nameTarget.textContent        = btn.dataset.roomName
    this.badgeTarget.textContent       = btn.dataset.roomBadge
    this.creatorTarget.textContent     = btn.dataset.roomCreator
    this.memberCountTarget.textContent = btn.dataset.roomMemberCount
    this.roomIdTarget.value            = btn.dataset.roomId
    this.membersListTarget.innerHTML   = JSON.parse(btn.dataset.roomMembers)
      .map(name => `<span style="display:inline-flex;align-items:center;padding:0.25rem 0.75rem;border-radius:9999px;background:rgba(255,255,255,0.06);border:1px solid rgba(107,114,128,0.3);color:#d1d5db;font-size:0.8125rem;">${name}</span>`)
      .join("")
    this.panelTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.panelTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }
}
```

### Step 3c: rooms/index.html.erb にモーダルDOM追加

`</section>` の直前（`</div>` の前）に以下を追加する。`data-controller="room-modal"` をページ最外のdivに追加し、モーダルDOMをテーブルの外に配置する：

```erb
<%# index.html.erb のページ全体を data-controller="room-modal" で包む %>
<%# 最上部の <div style="max-width: 72rem; ..."> を以下に変更 %>
<div data-controller="room-modal" style="max-width: 72rem; margin: 0 auto; padding: 2.5rem 1.5rem;">
```

そして `</section>` の直後・`</div>`（ページ最外div）の直前に追加：

```erb
  <%# 参加確認モーダル %>
  <div data-room-modal-target="panel"
       class="hidden"
       style="position:fixed;inset:0;z-index:50;display:flex;align-items:center;justify-content:center;background:rgba(0,0,0,0.6);">
    <div style="background:#1f2937;border:1px solid rgba(55,65,81,0.6);border-radius:1rem;width:100%;max-width:32rem;padding:1.5rem;margin:1rem;box-shadow:0 20px 60px rgba(0,0,0,0.5);">
      <%# ヘッダー %>
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:1.25rem;">
        <h2 data-room-modal-target="name"
            style="font-size:1.125rem;font-weight:700;color:#ffffff;margin:0;"></h2>
        <button type="button"
                data-action="room-modal#close"
                style="background:none;border:none;color:#9ca3af;cursor:pointer;font-size:1.5rem;line-height:1;padding:0.25rem;">×</button>
      </div>
      <%# 詳細情報 %>
      <dl style="display:grid;grid-template-columns:auto 1fr;gap:0.5rem 1rem;margin-bottom:1.25rem;font-size:0.875rem;">
        <dt style="color:#9ca3af;">種別</dt>
        <dd data-room-modal-target="badge" style="color:#d1d5db;margin:0;"></dd>
        <dt style="color:#9ca3af;">参加人数</dt>
        <dd data-room-modal-target="memberCount" style="color:#d1d5db;margin:0;"></dd>
        <dt style="color:#9ca3af;">作成者</dt>
        <dd data-room-modal-target="creator" style="color:#d1d5db;margin:0;"></dd>
      </dl>
      <%# 参加者一覧 %>
      <div style="margin-bottom:1.5rem;">
        <p style="font-size:0.8125rem;color:#9ca3af;margin:0 0 0.5rem 0;">参加者</p>
        <div data-room-modal-target="membersList"
             style="display:flex;flex-wrap:wrap;gap:0.375rem;"></div>
      </div>
      <%# フッターボタン %>
      <div style="display:flex;gap:0.75rem;">
        <button type="button"
                data-action="room-modal#close"
                style="flex:1;padding:0.625rem 1rem;border-radius:0.5rem;background:rgba(255,255,255,0.05);border:1px solid rgba(107,114,128,0.4);color:#d1d5db;font-size:0.875rem;cursor:pointer;">
          一覧に戻る
        </button>
        <%= form_with url: mypage_room_memberships_path, method: :post, style: "flex:1;" do |f| %>
          <%= f.hidden_field :room_id, data: { "room-modal-target": "roomId" } %>
          <%= f.submit "参加する",
                style: "width:100%;padding:0.625rem 1rem;border-radius:0.5rem;background:linear-gradient(135deg,#2563eb,#1d4ed8);border:none;color:#ffffff;font-size:0.875rem;font-weight:600;cursor:pointer;box-shadow:0 4px 12px rgba(37,99,235,0.3);" %>
        <% end %>
      </div>
    </div>
  </div>
```

### Step 3d: rooms/_room.html.erb のボタン変更

`<% unless issued || joined %>` ブロック内の `button_to` を以下に変更：

```erb
<% unless issued || joined %>
  <button type="button"
          data-action="room-modal#open"
          data-room-name="<%= room.label.presence || '名無しの部屋' %>"
          data-room-badge="<%= badge&.dig(:label) || '未分類' %>"
          data-room-creator="<%= creator_name %>"
          data-room-member-count="<%= room.room_memberships.size %> 人"
          data-room-id="<%= room.id %>"
          data-room-members="<%= room.room_memberships.map { |m| m.profile.user.display_name }.to_json.html_safe %>"
          style="display:inline-flex;align-items:center;justify-content:center;padding:0.5rem 1rem;border-radius:0.5rem;background:linear-gradient(135deg,#2563eb,#1d4ed8);color:#ffffff;font-size:0.875rem;font-weight:600;border:none;cursor:pointer;box-shadow:0 4px 12px rgba(37,99,235,0.3),inset 0 1px 0 rgba(255,255,255,0.1);">
    参加する
  </button>
```

### Step 4: テスト実行 → 成功確認

```bash
docker compose exec web bundle exec rspec spec/system/rooms_spec.rb
```

期待出力: `6 examples, 0 failures`

### Step 5: コミット

```bash
git add app/controllers/rooms_controller.rb \
        app/javascript/controllers/room_modal_controller.js \
        app/views/rooms/index.html.erb \
        app/views/rooms/_room.html.erb \
        spec/system/rooms_spec.rb
git commit -m "feat: 公開部屋一覧に参加確認モーダルを追加 #254"
```

---

## Task 5：REFACTOR

### Step 1: RuboCop 実行・修正

```bash
docker compose exec web bundle exec rubocop app/controllers/my/profiles_controller.rb app/controllers/shares_controller.rb app/helpers/application_helper.rb app/controllers/rooms_controller.rb
```

オフェンスがあれば自動修正：

```bash
docker compose exec web bundle exec rubocop -a app/controllers/my/profiles_controller.rb app/controllers/shares_controller.rb app/helpers/application_helper.rb app/controllers/rooms_controller.rb
```

### Step 2: 全テスト実行

```bash
docker compose exec web bundle exec rspec spec/requests/my/profile_spec.rb spec/requests/shares_spec.rb spec/helpers/application_helper_spec.rb spec/system/rooms_spec.rb
```

期待出力: `全例 0 failures`

### Step 3: RuboCop 全体確認

```bash
docker compose exec web bundle exec rubocop
```

期待出力: `no offenses detected`

### Step 4: 修正があればコミット

```bash
git add -p
git commit -m "refactor: RuboCop オフェンス修正 #254"
```

---

## 完了確認

全タスク完了後に実行する：

```bash
docker compose exec web bundle exec rspec spec/requests/my/profile_spec.rb spec/requests/shares_spec.rb spec/helpers/application_helper_spec.rb spec/system/rooms_spec.rb
docker compose exec web bundle exec rubocop
```

すべて `0 failures` / `no offenses detected` になれば実装完了。
