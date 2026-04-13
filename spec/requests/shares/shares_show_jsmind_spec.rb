require "rails_helper"

RSpec.describe "Shares#show jsMind data", type: :request do
  # 部屋オーナー（ログインユーザー）
  let(:current_user)    { create(:user, nickname: "issuer_nick") }
  let(:current_profile) { create(:profile, user: current_user) }
  let(:chat_room)       { create(:room, issuer_profile: current_profile, room_type: :chat) }
  let(:share_link)      { create(:share_link, room: chat_room, expires_at: 1.hour.from_now) }
  let(:chat_parent_tag) { create(:parent_tag, name: "アニメ", room_type: :chat) }

  before do
    # 部屋に参加済み・ログイン状態にする
    create(:room_membership, room: chat_room, profile: current_profile)
    sign_in current_user
  end

  it "親タグ名がjsMindデータとしてレスポンスに含まれる" do
    hobby = create(:hobby, name: "ワンピース")
    create(:hobby_parent_tag, hobby:, parent_tag: chat_parent_tag)
    current_profile.hobbies << hobby

    get share_path(share_link.token)

    expect(response.body).to include("アニメ")
  end

  it "ユーザーのnicknameがjsMindデータとしてレスポンスに含まれる" do
    hobby = create(:hobby, name: "読書")
    create(:hobby_parent_tag, hobby:, parent_tag: chat_parent_tag)
    current_profile.hobbies << hobby

    get share_path(share_link.token)

    expect(response.body).to include("issuer_nick")
  end

  it "人ノードの詳細URLがレスポンスに含まれる" do
    hobby = create(:hobby, name: "料理")
    create(:hobby_parent_tag, hobby:, parent_tag: chat_parent_tag)
    current_profile.hobbies << hobby

    get share_path(share_link.token)

    expect(response.body).to include("/rooms/#{chat_room.id}/members/#{current_profile.id}")
  end
end
