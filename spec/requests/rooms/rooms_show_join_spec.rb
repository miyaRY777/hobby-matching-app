require "rails_helper"

# ここで見ること: 部屋ページの「参加する」
# ここでは見ないこと: 一覧のモーダル
RSpec.describe "Rooms#show 参加する", type: :request do
  let(:room_owner_user) { create(:user) }
  let(:room_owner_profile) { create(:profile, user: room_owner_user) }
  let(:public_room) { create(:room, issuer_profile: room_owner_profile, locked: false) }
  let(:current_user) { create(:user) }
  let(:current_profile) { create(:profile, user: current_user) }

  before { sign_in current_user }

  it "公開部屋の未参加には「参加する」がある" do
    # セットアップ: プロフィールはあるが未参加
    current_profile

    # アクション: 部屋ページを開く
    get room_path(public_room)

    # アサーション: 明示的な参加操作がある
    expect(response.body).to include("参加する")
  end

  it "参加済みには「参加する」がない" do
    # セットアップ: すでに中にいる人
    create(:room_membership, room: public_room, profile: current_profile)

    # アクション: 部屋ページを開く
    get room_path(public_room)

    # アサーション: 参加ボタンは出さない
    expect(response.body).not_to include("参加する")
  end

  it "プロフィール未作成でも「参加する」がある" do
    # セットアップ: current_profile は作らない

    # アクション: 部屋ページを開く
    get room_path(public_room)

    # アサーション: 地図は見えて、参加するときだけ作成へ誘導できる
    expect(response.body).to include("参加する")
  end
end
