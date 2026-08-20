require "rails_helper"

RSpec.describe "Rooms#show", type: :request do
  it "趣味を持つメンバーがjsMindデータとしてレスポンスに含まれる" do
    # 発行者Aを作成する
    issuer_user = create(:user, nickname: "tana_A")
    issuer_profile = create(:profile, user: issuer_user)
    room = create(:room, issuer_profile: issuer_profile)
    hobby = create(:hobby, name: "読書")

    # 発行者をJOINさせる（初期メンバー）
    create(:room_membership, room: room, profile: issuer_profile)
    issuer_profile.hobbies << hobby

    # 参加者B, C, D を作成する
    b_user = create(:user, nickname: "tana_B")
    b = create(:profile, user: b_user)
    c_user = create(:user, nickname: "tana_C")
    c = create(:profile, user: c_user)
    d_user = create(:user, nickname: "tana_D")
    d = create(:profile, user: d_user)

    # JOIN順を作る（B → C → D）
    create(:room_membership, room: room, profile: b)
    create(:room_membership, room: room, profile: c)
    create(:room_membership, room: room, profile: d)

    b.hobbies << hobby
    c.hobbies << hobby
    d.hobbies << hobby

    # 表示確認
    sign_in b_user
    get room_path(room)

    body = response.body

    # jsMindデータに全メンバーのnicknameが含まれることを確認
    expect(body).to include("tana_A", "tana_B", "tana_C", "tana_D")

    # jsMindデータ内でid昇順（作成順）に並んでいることを確認
    expect(body.index("tana_A")).to be < body.index("tana_B")
    expect(body.index("tana_B")).to be < body.index("tana_C")
    expect(body.index("tana_C")).to be < body.index("tana_D")
  end
end
