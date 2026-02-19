require "rails_helper"

RSpec.describe "shares#show", type: :request do
  it "メンバーを参加した順番で表示する" do
    # 発行者Aと共有リンクを作成する
    issuer_user = create(:user, nickname: "A")
    issuer_profile = create(:profile, user: issuer_user)
    room = create(:room, issuer_profile: issuer_profile)
    share_link = create(:share_link, room: room, expires_at: 1.hour.from_now)

    # 発行者をJOINさせる（初期メンバー）
    create(:room_membership, room: room, profile: issuer_profile)

     # 参加者B, C, D を作成する
    b_user = create(:user, nickname: "B")
    c_user = create(:user, nickname: "C")
    d_user = create(:user, nickname: "D")

    # JOIN順を作る（B → C → D）
    sign_in b_user
    get share_path(share_link.token)

    sign_out :user

    sign_in c_user
    get share_path(share_link.token)

    sign_out :user

    sign_in d_user
    get share_path(share_link.token)

    sign_out :user

    # 表示確認
    sign_in b_user
    get share_path(share_link.token)

    body = response.body

    # 参加順で表示されていることを確認
    expect(body).to include("A", "B", "C", "D")
    expect(body.index("A")).to be < body.index("B")
    expect(body.index("B")).to be < body.index("C")
    expect(body.index("C")).to be < body.index("D")
  end
end
