require "rails_helper"

RSpec.describe "Shares#show jsMind data", type: :request do
  # 事前準備（User, Profile, Room, ShareLink）
  let(:issuer_user) { create(:user, nickname: "issuer_nick") }
  let(:issuer_profile) { create(:profile, user: issuer_user) }
  let(:room) { create(:room, issuer_profile: issuer_profile) }
  let(:share_link) { create(:share_link, room: room, expires_at: 1.hour.from_now) }

  # issuer_profile を room のメンバーに追加（jsMindデータ生成に必要）
  # Shares#show にアクセスできるようログイン状態にする
  before do
    create(:room_membership, room: room, profile: issuer_profile)
    sign_in issuer_user
  end

  it "趣味名がjsMindデータとしてレスポンスに含まれる" do
    hobby = create(:hobby, name: "登山")
    issuer_profile.hobbies << hobby

    get share_path(share_link.token)

    expect(response.body).to include("登山")
  end

  it "ユーザーのnicknameがjsMindデータとしてレスポンスに含まれる" do
    hobby = create(:hobby, name: "読書")
    issuer_profile.hobbies << hobby

    get share_path(share_link.token)

    expect(response.body).to include("issuer_nick")
  end

  it "人ノードの詳細URLがレスポンスに含まれる" do
    hobby = create(:hobby, name: "料理")
    issuer_profile.hobbies << hobby

    get share_path(share_link.token)

    expect(response.body).to include("/rooms/#{room.id}/members/#{issuer_profile.id}")
  end
end
