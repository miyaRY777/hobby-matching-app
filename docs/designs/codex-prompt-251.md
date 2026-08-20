# Codex 実装プロンプト：Issue #251 趣味タグ統合専用画面（Admin）

## コンテキスト

- **リポジトリ:** hobby-matching-app（Ruby on Rails）
- **ブランチ:** `feature/251-admin-hobby-merges`
- **実行環境:** `docker compose exec web` 経由でコマンドを実行する
- **Issue:** #251

## 背景

管理者が表記ゆれのある趣味タグを安全に統合できる専用画面 `/admin/hobby_merges/new` を新規作成する。

既存の `Admin::HobbyMergeService` がすでにロジックを持っており、それを再利用する。
#248 で未分類タグ管理画面から統合機能が除去されたため、独立した専用画面として切り出す。

## 重要なルール

- **必ずTDD（RED → GREEN → REFACTOR）で進める**
- 実装より先にテストを書く
- コマンドはすべて `docker compose exec web` 経由
- マイグレーション不要（既存スキーマで対応）

## 既存コードの理解

### Admin::HobbyMergeService（変更しない）

```ruby
# app/services/admin/hobby_merge_service.rb
class Admin::HobbyMergeService
  Result = Struct.new(:success?, :error, keyword_init: true)

  def self.call(source:, target:)
    new(source:, target:).call
  end

  def call
    return Result.new(success?: false, error: "統合元と統合先が同じです") if @source.id == @target.id

    ActiveRecord::Base.transaction do
      duplicate_profile_ids = ProfileHobby.where(hobby_id: @target.id).pluck(:profile_id)
      ProfileHobby.where(hobby_id: @source.id, profile_id: duplicate_profile_ids).delete_all
      ProfileHobby.where(hobby_id: @source.id).update_all(hobby_id: @target.id)
      @source.destroy!
    end
    Result.new(success?: true, error: nil)
  rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::RecordInvalid => e
    Result.new(success?: false, error: e.message)
  end
end
```

### Admin::BaseController（変更しない）

```ruby
# app/controllers/admin/base_controller.rb
class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :authenticate_user!
  before_action :require_admin!

  private

  def require_admin!
    redirect_to root_path, alert: "権限がありません" unless current_user.admin?
  end
end
```

### 現在の routes.rb（admin namespace 部分）

```ruby
namespace :admin do
  root "dashboards#show"
  resources :parent_tags, only: %i[index new create edit update destroy]
  resources :hobbies, only: %i[new create edit update destroy]
  resources :unclassified_hobbies, only: [ :index, :update, :destroy ]
end
```

### admin レイアウト（app/views/layouts/admin.html.erb）

```erb
<header style="...">
  <span style="font-weight: bold; color: #f9fafb;">管理画面</span>
  <%= link_to "ダッシュボード", admin_root_path, style="..." %>
  <%= link_to "親タグ管理", admin_parent_tags_path, style="..." %>
  <%= link_to "未分類タグ管理", admin_unclassified_hobbies_path, style="..." %>
  <span style="margin-left: auto;">
    <%= link_to "サイトに戻る", root_path, style="..." %>
  </span>
</header>
```

### FactoryBot 定義

```ruby
# spec/factories/hobbies.rb
FactoryBot.define do
  factory :hobby do
    sequence(:name) { |n| "hobby#{n}" }
  end
end

# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "test#{n}@example.com" }
    password { "password123" }
    nickname { "test_user" }

    trait :admin do
      admin { true }
    end
  end
end
```

### 既存 system spec の認証パターン

```ruby
# request spec: sign_in ヘルパーを使う
let!(:admin_user) { create(:user, :admin) }
before { sign_in admin_user }

# system spec: login_as ヘルパーを使う
before { login_as(admin_user, scope: :user) }
```

---

## Task 1：Request spec + Routes + Controller

### 対象ファイル

- 新規: `spec/requests/admin/hobby_merges_spec.rb`
- 修正: `config/routes.rb`
- 新規: `app/controllers/admin/hobby_merges_controller.rb`

### Step 1: 失敗するテストを書く

```ruby
# spec/requests/admin/hobby_merges_spec.rb
require "rails_helper"

RSpec.describe "Admin::HobbyMergesController", type: :request do
  let!(:admin_user) { create(:user, :admin) }
  let!(:source_hobby) { create(:hobby, name: "ゲーム") }
  let!(:target_hobby) { create(:hobby, name: "Gaming") }

  describe "GET /admin/hobby_merges/new" do
    # 管理者の場合: 200 を返す
    context "管理者の場合" do
      before { sign_in admin_user }

      it "200 OK を返す" do
        get new_admin_hobby_merge_path
        expect(response).to have_http_status(:ok)
      end
    end

    # 一般ユーザーの場合: root にリダイレクト
    context "一般ユーザーの場合" do
      before { sign_in create(:user) }

      it "root_path にリダイレクトされる" do
        get new_admin_hobby_merge_path
        expect(response).to redirect_to(root_path)
      end
    end

    # 未ログインの場合: ログインページにリダイレクト
    context "未ログインの場合" do
      it "ログインページにリダイレクトされる" do
        get new_admin_hobby_merge_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /admin/hobby_merges" do
    context "管理者の場合" do
      before { sign_in admin_user }

      # 正常系: 異なるタグを指定した場合
      context "異なるタグを指定した場合" do
        it "統合元タグが削除される" do
          expect {
            post admin_hobby_merges_path,
                 params: { source_hobby_id: source_hobby.id, target_hobby_id: target_hobby.id }
          }.to change(Hobby, :count).by(-1)
        end

        it "new にリダイレクトされる" do
          post admin_hobby_merges_path,
               params: { source_hobby_id: source_hobby.id, target_hobby_id: target_hobby.id }
          expect(response).to redirect_to(new_admin_hobby_merge_path)
        end

        it "profile_hobbies が統合先に付け替えられる" do
          profile = create(:profile)
          create(:profile_hobby, profile: profile, hobby: source_hobby)

          post admin_hobby_merges_path,
               params: { source_hobby_id: source_hobby.id, target_hobby_id: target_hobby.id }

          expect(profile.profile_hobbies.reload.map(&:hobby_id)).to include(target_hobby.id)
        end
      end

      # 異常系: 同じタグを指定した場合
      context "同じタグを指定した場合" do
        it "422 を返す" do
          post admin_hobby_merges_path,
               params: { source_hobby_id: source_hobby.id, target_hobby_id: source_hobby.id }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "エラーメッセージがレスポンスに含まれる" do
          post admin_hobby_merges_path,
               params: { source_hobby_id: source_hobby.id, target_hobby_id: source_hobby.id }
          expect(response.body).to include("統合元と統合先が同じです")
        end
      end
    end

    # 一般ユーザーの場合: root にリダイレクト
    context "一般ユーザーの場合" do
      before { sign_in create(:user) }

      it "root_path にリダイレクトされる" do
        post admin_hobby_merges_path,
             params: { source_hobby_id: source_hobby.id, target_hobby_id: target_hobby.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
```

### Step 2: テスト実行 → 失敗確認

```bash
docker compose exec web bundle exec rspec spec/requests/admin/hobby_merges_spec.rb
```

期待出力: `RoutingError` （ルートが存在しない）

### Step 3: ルート追加

`config/routes.rb` の admin namespace 内に追加する：

```ruby
namespace :admin do
  root "dashboards#show"
  resources :parent_tags, only: %i[index new create edit update destroy]
  resources :hobbies, only: %i[new create edit update destroy]
  resources :unclassified_hobbies, only: [ :index, :update, :destroy ]
  resources :hobby_merges, only: %i[new create]
end
```

### Step 4: Controller 作成

```ruby
# app/controllers/admin/hobby_merges_controller.rb
class Admin::HobbyMergesController < Admin::BaseController
  def new
    @hobbies = Hobby.order(:name)
  end

  def create
    source = Hobby.find(params[:source_hobby_id])
    target = Hobby.find(params[:target_hobby_id])
    result = Admin::HobbyMergeService.call(source:, target:)
    if result.success?
      redirect_to new_admin_hobby_merge_path,
                  notice: "「#{source.name}」を「#{target.name}」に統合しました"
    else
      @hobbies = Hobby.order(:name)
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end
end
```

### Step 5: テスト実行 → 全件成功確認

```bash
docker compose exec web bundle exec rspec spec/requests/admin/hobby_merges_spec.rb
```

期待出力: `8 examples, 0 failures`

### Step 6: コミット

```bash
git add spec/requests/admin/hobby_merges_spec.rb config/routes.rb app/controllers/admin/hobby_merges_controller.rb
git commit -m "feat: Admin::HobbyMergesController と routes を追加 #251"
```

---

## Task 2：System spec + View + ナビバーリンク

### 対象ファイル

- 新規: `spec/system/admin/hobby_merges_spec.rb`
- 新規: `app/views/admin/hobby_merges/new.html.erb`
- 修正: `app/views/layouts/admin.html.erb`（未分類タグ管理リンクの後にリンク追加）

### Step 1: 失敗するテストを書く

```ruby
# spec/system/admin/hobby_merges_spec.rb
require "rails_helper"

RSpec.describe "Admin 趣味タグ統合", type: :system do
  let!(:admin_user) { create(:user, :admin) }
  let!(:source_hobby) { create(:hobby, name: "ゲーム") }
  let!(:target_hobby) { create(:hobby, name: "Gaming") }

  before { login_as(admin_user, scope: :user) }

  # フォーム表示
  describe "フォーム表示" do
    before { visit new_admin_hobby_merge_path }

    it "ページタイトルが表示される" do
      expect(page).to have_content "趣味タグ統合"
    end

    it "統合元セレクトに全タグが含まれる" do
      expect(page).to have_select("source_hobby_id", with_options: %w[ゲーム Gaming])
    end

    it "統合先セレクトに全タグが含まれる" do
      expect(page).to have_select("target_hobby_id", with_options: %w[ゲーム Gaming])
    end
  end

  # 統合実行（confirm あり）
  describe "統合実行", js: true do
    before { visit new_admin_hobby_merge_path }

    it "異なるタグを選択して統合するとflashが表示される" do
      select "ゲーム", from: "source_hobby_id"
      select "Gaming", from: "target_hobby_id"
      accept_confirm { click_button "統合する" }
      expect(page).to have_content "「ゲーム」を「Gaming」に統合しました"
    end

    it "統合後に統合元タグが削除される" do
      select "ゲーム", from: "source_hobby_id"
      select "Gaming", from: "target_hobby_id"
      accept_confirm { click_button "統合する" }
      expect(Hobby.exists?(name: "ゲーム")).to be false
    end

    it "同じタグを選択するとエラーが表示される" do
      select "ゲーム", from: "source_hobby_id"
      select "ゲーム", from: "target_hobby_id"
      accept_confirm { click_button "統合する" }
      expect(page).to have_content "統合元と統合先が同じです"
    end
  end

  # アクセス制御
  describe "アクセス制御" do
    it "一般ユーザーは root にリダイレクトされる" do
      login_as(create(:user), scope: :user)
      visit new_admin_hobby_merge_path
      expect(page).to have_current_path root_path
    end
  end
end
```

### Step 2: テスト実行 → 失敗確認

```bash
docker compose exec web bundle exec rspec spec/system/admin/hobby_merges_spec.rb
```

期待出力: `ActionView::MissingTemplate` （Viewが存在しない）

### Step 3: View 作成

```erb
<%# app/views/admin/hobby_merges/new.html.erb %>
<div style="max-width: 48rem; margin: 0 auto;">
  <h1 style="font-size: 1.5rem; font-weight: bold; color: #f9fafb; margin-bottom: 1.5rem;">趣味タグ統合</h1>

  <%= form_with url: admin_hobby_merges_path, data: { turbo_confirm: "選択したタグを統合しますか？この操作は取り消せません。" } do |f| %>
    <div style="margin-bottom: 1.5rem;">
      <label for="source_hobby_id" style="color: #d1d5db; display: block; margin-bottom: 0.5rem;">
        統合元タグ（削除されます）
      </label>
      <%= select_tag :source_hobby_id,
            options_from_collection_for_select(@hobbies, :id, :name),
            prompt: "選択してください",
            style: "background: #1f2937; color: #f9fafb; border: 1px solid #374151; padding: 0.375rem 0.75rem; border-radius: 0.25rem; width: 100%;" %>
    </div>

    <div style="margin-bottom: 1.5rem;">
      <label for="target_hobby_id" style="color: #d1d5db; display: block; margin-bottom: 0.5rem;">
        統合先タグ（残ります）
      </label>
      <%= select_tag :target_hobby_id,
            options_from_collection_for_select(@hobbies, :id, :name),
            prompt: "選択してください",
            style: "background: #1f2937; color: #f9fafb; border: 1px solid #374151; padding: 0.375rem 0.75rem; border-radius: 0.25rem; width: 100%;" %>
    </div>

    <%= f.submit "統合する",
          style: "background: #dc2626; color: white; border: none; padding: 0.5rem 1.5rem; border-radius: 0.25rem; cursor: pointer; font-weight: bold;" %>
  <% end %>
</div>
```

### Step 4: ナビバーにリンク追加

`app/views/layouts/admin.html.erb` の `link_to "未分類タグ管理"` の直後に追加する：

```erb
<%= link_to "タグ統合", new_admin_hobby_merge_path, style: "color: #9ca3af; text-decoration: none; font-size: 0.875rem;" %>
```

### Step 5: テスト実行 → 全件成功確認

```bash
docker compose exec web bundle exec rspec spec/system/admin/hobby_merges_spec.rb
```

期待出力: `7 examples, 0 failures`

### Step 6: コミット

```bash
git add spec/system/admin/hobby_merges_spec.rb app/views/admin/hobby_merges/new.html.erb app/views/layouts/admin.html.erb
git commit -m "feat: 趣味タグ統合フォームのView・system specを追加 #251"
```

---

## Task 3：REFACTOR

### Step 1: RuboCop 実行・修正

```bash
docker compose exec web bundle exec rubocop app/controllers/admin/hobby_merges_controller.rb
```

オフェンスがあれば修正する。

```bash
docker compose exec web bundle exec rubocop -a app/controllers/admin/hobby_merges_controller.rb
```

### Step 2: 全テスト実行

```bash
docker compose exec web bundle exec rspec spec/requests/admin/hobby_merges_spec.rb spec/system/admin/hobby_merges_spec.rb
```

期待出力: `15 examples, 0 failures`

### Step 3: RuboCop 全体確認

```bash
docker compose exec web bundle exec rubocop
```

期待出力: `no offenses detected`

### Step 4: 修正があればコミット

```bash
git add app/controllers/admin/hobby_merges_controller.rb
git commit -m "refactor: RuboCop オフェンス修正 #251"
```

---

## 完了確認

全タスク完了後に実行する：

```bash
docker compose exec web bundle exec rspec spec/requests/admin/hobby_merges_spec.rb spec/system/admin/hobby_merges_spec.rb
docker compose exec web bundle exec rubocop
```

すべて `0 failures` / `no offenses detected` になれば実装完了。
