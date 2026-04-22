# Codex 実装プロンプト — Issue #248 未分類タグ管理画面の改善（分類主役・削除条件限定）

**ブランチ:** `feature/248-unclassified-hobbies-improvement`
**設計書:** `docs/designs/2026-04-22-unclassified-hobbies-improvement.md`

---

## 概要

管理者向け未分類タグ管理画面（`/admin/unclassified_hobbies`）を改修する。

- 統合機能（merge）を画面から除去する
- 分類フォームを視覚的に主役化する
- `usage_count = 0` のタグにのみ削除ボタンを表示する（`data-confirm` 付き）
- 使用中タグへの直接 DELETE リクエストは `restrict_with_error` で弾き、alert にリダイレクトする

---

## 変更対象ファイル

| ファイル | 変更種別 |
|---|---|
| `config/routes.rb` | 修正 |
| `app/controllers/admin/unclassified_hobbies_controller.rb` | 修正 |
| `app/views/admin/unclassified_hobbies/index.html.erb` | 修正 |
| `spec/requests/admin/unclassified_hobbies_spec.rb` | 修正 |
| `spec/system/admin/unclassified_hobbies_spec.rb` | 修正 |

---

## Task 1：request spec — merge テスト削除 + DELETE テスト追加

**対象ファイル:** `spec/requests/admin/unclassified_hobbies_spec.rb`

### Step 1: merge テストブロックを削除する

`describe "POST /admin/unclassified_hobbies/:id/merge"` ブロック全体を削除する。

### Step 2: DELETE テストブロックを末尾（最後の `end` の直前）に追加する

```ruby
describe "DELETE /admin/unclassified_hobbies/:id" do
  context "管理者の場合" do
    before { sign_in admin_user }

    context "usage_count が 0 の場合" do
      # hobby を使用しているプロフィールがない状態
      it "削除されて一覧にリダイレクトされる" do
        delete admin_unclassified_hobby_path(unclassified_hobby)
        aggregate_failures do
          expect(Hobby.find_by(id: unclassified_hobby.id)).to be_nil
          expect(response).to redirect_to(admin_unclassified_hobbies_path)
        end
      end
    end

    context "usage_count が 1 以上の場合" do
      # hobby を使用しているプロフィールがある状態
      let!(:owner_profile) { create(:profile) }

      before { create(:profile_hobby, profile: owner_profile, hobby: unclassified_hobby) }

      it "削除されずに alert でリダイレクトされる" do
        delete admin_unclassified_hobby_path(unclassified_hobby)
        aggregate_failures do
          expect(Hobby.find_by(id: unclassified_hobby.id)).not_to be_nil
          expect(response).to redirect_to(admin_unclassified_hobbies_path)
        end
      end
    end

    context "分類済み hobby の場合" do
      # unclassified スコープ外なので 404
      it "404 を返す" do
        delete admin_unclassified_hobby_path(classified_hobby)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context "一般ユーザーの場合" do
    let!(:normal_user) { create(:user) }

    before { sign_in normal_user }

    it "root_path にリダイレクトされる" do
      delete admin_unclassified_hobby_path(unclassified_hobby)
      expect(response).to redirect_to(root_path)
    end
  end
end
```

### Step 3: テスト実行 → DELETE テストが RED であることを確認

```bash
docker compose exec web bundle exec rspec spec/requests/admin/unclassified_hobbies_spec.rb
```

期待出力: `No route matches [DELETE]` のエラー（ルート未定義）

---

## Task 2：routes + controller 修正（GREEN）

### Step 1: `config/routes.rb` の unclassified_hobbies を書き換える

```ruby
# 変更前
resources :unclassified_hobbies, only: [ :index, :update ] do
  member do
    post :merge
  end
end

# 変更後
resources :unclassified_hobbies, only: [ :index, :update, :destroy ]
```

### Step 2: `app/controllers/admin/unclassified_hobbies_controller.rb` の index アクションを修正する

`@all_hobbies_grouped = build_all_hobbies_grouped` の行を削除する。

```ruby
def index
  scope = Hobby.unclassified
               .left_joins(:profile_hobbies)
               .select("hobbies.*, COUNT(DISTINCT profile_hobbies.id) AS usage_count, COUNT(DISTINCT profile_hobbies.profile_id) AS user_count")
               .group("hobbies.id")
  scope = scope.where("hobbies.name LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%") if params[:q].present?
  @hobbies = scope
  @parent_tags = ParentTag.order(:room_type, :position)
  @grouped_parent_tag_options = build_grouped_parent_tag_options
end
```

### Step 3: `merge` アクションを削除し、`destroy` アクションを `update` の後に追加する

```ruby
def destroy
  @hobby = Hobby.unclassified.find(params[:id])
  @hobby.destroy!
  redirect_to admin_unclassified_hobbies_path, notice: "削除しました"
rescue ActiveRecord::RecordNotDestroyed
  redirect_to admin_unclassified_hobbies_path, alert: "削除できませんでした（使用中のタグは削除できません）"
end
```

### Step 4: private の `build_all_hobbies_grouped` メソッドを削除する

削除対象:

```ruby
def build_all_hobbies_grouped
  grouped_hobbies = Hobby.includes(:hobby_parent_tags)
                         .order(:name)
                         .each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |hobby, hash|
    hash[hobby.primary_room_type] << [ hobby.name, hobby.id ]
  end

  ParentTag.room_types.keys
           .append("unclassified")
           .index_with { |room_type| grouped_hobbies[room_type] }
           .reject { |_, hobbies| hobbies.empty? }
end
```

### Step 5: request spec を実行 → GREEN を確認

```bash
docker compose exec web bundle exec rspec spec/requests/admin/unclassified_hobbies_spec.rb
```

期待出力: `X examples, 0 failures`

---

## Task 3：system spec — merge テスト削除 + delete テスト追加

**対象ファイル:** `spec/system/admin/unclassified_hobbies_spec.rb`

### Step 1: 統合テストブロックを削除する

`describe "統合"` ブロック全体を削除する。

### Step 2: 削除テストブロックを「アクセス制御」describe の直前に追加する

```ruby
describe "削除" do
  let!(:unused_hobby) { create(:hobby, name: "unused-tag") }
  let!(:used_hobby) { create(:hobby, name: "used-tag") }
  let!(:owner_profile) { create(:profile) }

  before do
    # used_hobby は1件のプロフィールで使用中
    create(:profile_hobby, profile: owner_profile, hobby: used_hobby)
    visit admin_unclassified_hobbies_path
  end

  it "usage_count が 0 のタグに削除ボタンが表示される" do
    within "[data-hobby-id='#{unused_hobby.id}']" do
      expect(page).to have_button "削除"
    end
  end

  it "usage_count が 1 以上のタグに削除ボタンが表示されず「使用中」と表示される" do
    within "[data-hobby-id='#{used_hobby.id}']" do
      expect(page).not_to have_button "削除"
      expect(page).to have_content "使用中"
    end
  end

  it "削除後にタグが一覧から消えてフラッシュが表示される" do
    within "[data-hobby-id='#{unused_hobby.id}']" do
      accept_confirm { click_button "削除" }
    end
    expect(page).not_to have_css("[data-hobby-id='#{unused_hobby.id}']")
    expect(page).to have_content "削除しました"
  end
end
```

### Step 3: system spec を実行 → 削除テストが RED であることを確認

```bash
docker compose exec web bundle exec rspec spec/system/admin/unclassified_hobbies_spec.rb
```

期待出力: 削除テスト3件が `FAILED`（ビューに削除ボタンがないため）

---

## Task 4：ビュー改修（GREEN）

**対象ファイル:** `app/views/admin/unclassified_hobbies/index.html.erb`

### Step 1: thead の「統合」列ヘッダーを「削除」に変更する

```erb
<%# 変更前 %>
<th style="padding: 0.5rem 1rem;">分類</th>
<th style="padding: 0.5rem 1rem;">統合</th>

<%# 変更後 %>
<th style="padding: 0.5rem 1rem;">分類</th>
<th style="padding: 0.5rem 1rem;">削除</th>
```

### Step 2: 分類フォームの submit ボタンを主役化する

```erb
<%# 変更前 %>
<%= f.submit "分類",
      style: "margin-left: 0.25rem; background: #2563eb; color: white; border: none; padding: 0.25rem 0.75rem; border-radius: 0.25rem; cursor: pointer;" %>

<%# 変更後 %>
<%= f.submit "分類",
      style: "margin-left: 0.5rem; background: #2563eb; color: white; border: none; padding: 0.375rem 1rem; border-radius: 0.25rem; cursor: pointer; font-weight: bold;" %>
```

### Step 3: tbody の統合フォーム列を削除し、条件付き削除ボタン列に置き換える

削除対象（統合フォーム `<td>` 全体）:

```erb
<td style="padding: 0.5rem 1rem;">
  <%= form_with url: merge_admin_unclassified_hobby_path(hobby), method: :post, local: true do |f| %>
    ...
  <% end %>
</td>
```

追加する削除列:

```erb
<td style="padding: 0.5rem 1rem;">
  <% if hobby.usage_count == 0 %>
    <%= button_to "削除",
          admin_unclassified_hobby_path(hobby),
          method: :delete,
          data: { confirm: "「#{hobby.name}」を削除しますか？この操作は取り消せません。" },
          style: "background: #dc2626; color: white; border: none; padding: 0.375rem 0.75rem; border-radius: 0.25rem; cursor: pointer;" %>
  <% else %>
    <span style="color: #6b7280; font-size: 0.875rem;">使用中</span>
  <% end %>
</td>
```

### Step 4: system spec を実行 → GREEN を確認

```bash
docker compose exec web bundle exec rspec spec/system/admin/unclassified_hobbies_spec.rb
```

期待出力: `X examples, 0 failures`

---

## Task 5：全 spec 確認 + RuboCop + コミット

### Step 1: 関連 spec を全件実行

```bash
docker compose exec web bundle exec rspec spec/requests/admin/unclassified_hobbies_spec.rb spec/system/admin/unclassified_hobbies_spec.rb
```

期待出力: `X examples, 0 failures`

### Step 2: RuboCop を実行

```bash
docker compose exec web bundle exec rubocop app/controllers/admin/unclassified_hobbies_controller.rb app/views/admin/unclassified_hobbies/index.html.erb config/routes.rb
```

期待出力: `no offenses detected`

### Step 3: 違反があれば自動修正して再確認

```bash
docker compose exec web bundle exec rubocop -a app/controllers/admin/unclassified_hobbies_controller.rb
docker compose exec web bundle exec rubocop app/controllers/admin/unclassified_hobbies_controller.rb
```

### Step 4: コミット

```bash
git add config/routes.rb \
  app/controllers/admin/unclassified_hobbies_controller.rb \
  app/views/admin/unclassified_hobbies/index.html.erb \
  spec/requests/admin/unclassified_hobbies_spec.rb \
  spec/system/admin/unclassified_hobbies_spec.rb
git commit -m "improve: 未分類タグ管理画面を分類主役・削除条件限定に改修 #248"
```

---

## 受入条件チェックリスト

- [ ] 統合列・統合フォームが画面から消えている
- [ ] 分類ボタンが視覚的に主役として目立つ
- [ ] `usage_count = 0` のタグに削除ボタンが表示される
- [ ] `usage_count > 0` のタグに削除ボタンが表示されない（「使用中」表示）
- [ ] 削除ボタン押下時に確認ダイアログが出る
- [ ] 削除後に一覧から消え、`Hobby` レコードが削除されている
- [ ] 分類済みタグや存在しないタグへの `DELETE` は 404 を返す
- [ ] 使用中タグへの直接 `DELETE` リクエストは alert リダイレクトになる
- [ ] RSpec / RuboCop 全通過
