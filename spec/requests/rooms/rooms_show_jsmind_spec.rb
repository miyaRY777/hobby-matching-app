require "rails_helper"

# ここで見ること: 部屋ページのマインドマップデータ
# ここでは見ないこと: 招待リンク経由の案内
RSpec.describe "Rooms#show jsMind data", type: :request do
  # 部屋の作成者（ログインユーザー）
  let(:current_user)    { create(:user, nickname: "issuer_nick") }
  let(:current_profile) { create(:profile, user: current_user) }
  let(:chat_room)       { create(:room, issuer_profile: current_profile, room_type: :chat) }
  let(:chat_parent_tag) { create(:parent_tag, name: "アニメ", room_type: :chat) }

  before do
    # セットアップ: 作成者として参加済み・ログイン状態にする
    create(:room_membership, room: chat_room, profile: current_profile)
    sign_in current_user
  end

  it "親タグ名がjsMindデータとしてレスポンスに含まれる" do
    # セットアップ: 部屋タイプに合う親タグ付きの趣味を付ける
    hobby = create(:hobby, name: "ワンピース")
    create(:hobby_parent_tag, hobby:, parent_tag: chat_parent_tag)
    current_profile.hobbies << hobby

    # アクション: 部屋ページを開く
    get room_path(chat_room)

    # アサーション: マインドマップデータに親タグ名が入る
    expect(response.body).to include("アニメ")
  end

  it "ユーザーのnicknameがjsMindデータとしてレスポンスに含まれる" do
    # セットアップ: 趣味がないと人ノードが出ないので付ける
    hobby = create(:hobby, name: "読書")
    create(:hobby_parent_tag, hobby:, parent_tag: chat_parent_tag)
    current_profile.hobbies << hobby

    # アクション: 部屋ページを開く
    get room_path(chat_room)

    # アサーション: マインドマップデータに nickname が入る
    expect(response.body).to include("issuer_nick")
  end

  it "人ノードの詳細URLがレスポンスに含まれる" do
    # セットアップ: 趣味がないと人ノードが出ないので付ける
    hobby = create(:hobby, name: "料理")
    create(:hobby_parent_tag, hobby:, parent_tag: chat_parent_tag)
    current_profile.hobbies << hobby

    # アクション: 部屋ページを開く
    get room_path(chat_room)

    # アサーション: メンバー詳細への URL がマインドマップデータに入る
    expect(response.body).to include("/rooms/#{chat_room.id}/members/#{current_profile.id}")
  end
end
