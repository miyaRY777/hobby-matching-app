# Codex 実装依頼: 部屋一覧表示と参加機能 (Issue #230)

## ブランチ
`feature/230-rooms-index-and-join`（すでに作成済み・このブランチで作業すること）

## 前提ルール
- すべてのコマンドは `docker compose exec web` 経由で実行する
- TDD厳守: RED（失敗テスト）→ GREEN（実装）→ REFACTOR の順
- テストなしで実装を先に書かない
- コントローラは薄く、ビジネスロジックはモデル or Service へ
- N+1クエリを発生させない

---

## 実装対象

### 1. ルーティング追加（`config/routes.rb`）

```ruby
# トップレベルに追加
resources :rooms, only: [:index]

# mypage namespace 内の room_memberships に :create を追加（現在は :destroy のみ）
namespace :mypage do
  resources :room_memberships, only: [:create, :destroy]
end
```

### 2. Room モデル（`app/models/room.rb`）

既存の `scope :unlocked` の有無を確認し、なければ追加する：

```ruby
scope :unlocked, -> { where(locked: false) }
```

### 3. RoomsController（新規: `app/controllers/rooms_controller.rb`）

```ruby
class RoomsController < ApplicationController
  before_action :authenticate_user!

  def index
    @rooms = Room.unlocked
                 .includes(issuer_profile: :user, room_memberships: :profile)
                 .order(created_at: :desc)
    profile = current_user.profile
    @joined_room_ids = profile&.room_memberships&.pluck(:room_id) || []
    @issued_room_ids = profile&.issued_rooms&.pluck(:id) || []
  end
end
```

### 4. Mypage::RoomMembershipsController に `#create` 追加

既存ファイル: `app/controllers/mypage/room_memberships_controller.rb`

```ruby
def create
  profile = current_user.profile
  return redirect_to rooms_path, alert: "プロフィールを作成してください" unless profile

  room = Room.unlocked.find(params[:room_id])
  RoomMembership.create!(room: room, profile: profile)

  respond_to do |format|
    format.turbo_stream { flash.now[:notice] = "部屋に参加しました" }
    format.html { redirect_to rooms_path, notice: "部屋に参加しました" }
  end
rescue ActiveRecord::RecordNotFound
  redirect_to rooms_path, alert: "部屋が見つかりません"
rescue ActiveRecord::RecordInvalid
  redirect_to rooms_path, alert: "すでに参加しています"
end
```

### 5. ビュー（新規）

#### `app/views/rooms/index.html.erb`

一覧ページ。既存の `mypage/rooms/index.html.erb` のデザイン（ダーク系・グラスモーフィズム）を参考にすること。

#### `app/views/rooms/_room.html.erb`

部屋カードの部分テンプレート。以下の情報を表示する：
- 部屋名（`room.label.presence || "名無しの部屋"`）
- 種別バッジ（`room_type_badge(room.room_type)` ヘルパー使用）
- メンバー数（`room.room_memberships.size`）
- 作成者名（`room.issuer_profile.user.email` など）
- 状態バッジ（以下の優先順）:
  - 自分が作成した部屋 → 「作成した部屋」バッジ（紫系: `rgba(124, 58, 237, 0.2)`）
  - 参加済み（作成者以外） → 「参加済み」バッジ（緑系: `rgba(34, 197, 94, 0.15)`）
  - 未参加 → 「参加する」ボタン（POST `/mypage/room_memberships`、`room_id` パラメータ）

バッジ/ボタンの判定に `issued_room_ids` と `joined_room_ids` を使うこと（ローカル変数として渡す）。

---

## テスト

### `spec/system/rooms_spec.rb`（新規）

以下のシナリオをカバーする system spec を書くこと（日本語コメント: セットアップ・アクション・アサーション）:

1. 公開部屋一覧が表示される（locked: false のみ、locked: true は非表示）
2. 自分が作成した部屋に「作成した部屋」バッジが表示される
3. 参加済み部屋に「参加済み」バッジが表示される
4. 未参加部屋に「参加する」ボタンが表示される
5. 「参加する」ボタンを押すと参加できる（「参加済み」バッジに変わる）

### `spec/requests/rooms_spec.rb`（新規）

1. GET /rooms: 認証済みで200、未認証でリダイレクト
2. POST /mypage/room_memberships: 参加成功・重複参加エラー・locked部屋はエラー

---

## 既存UIパターン（参照用）

デザインは `app/views/mypage/rooms/_room.html.erb` を参考にすること：
- 背景: `rgba(255,255,255,0.03)`、ボーダー: `rgba(55, 65, 81, 0.4)`
- バッジ: `border-radius: 9999px`、`font-size: 0.75rem`
- ヘルパー: `room_type_badge(room.room_type)`（`app/helpers/rooms_helper.rb` に定義済み）

---

## 完了条件

- [ ] `docker compose exec web bundle exec rspec spec/system/rooms_spec.rb` 全通過
- [ ] `docker compose exec web bundle exec rspec spec/requests/rooms_spec.rb` 全通過
- [ ] `docker compose exec web bundle exec rubocop` 違反なし
- [ ] `locked: true` の部屋が一覧に表示されないこと
- [ ] N+1クエリが発生しないこと（`bullet` または手動確認）
