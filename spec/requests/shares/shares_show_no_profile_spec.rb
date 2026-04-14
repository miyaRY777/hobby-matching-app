require "rails_helper"

RSpec.describe "shares#show", type: :request do
  it "プロフィールがない場合、プロフィール作成画面へリダイレクトされる" do
    # 共有リンクを作る
    issuer = create(:profile)
    room = create(:room, issuer_profile: issuer)
    share_link = create(:share_link, room: room, expires_at: 1.hour.from_now)

    # プロフィールなしの訪問者を作る
    viewer = create(:user)

    # ログイン
    sign_in viewer

    # 検証
    expect {
      get share_path(share_link.token)
    }.not_to change(RoomMembership, :count)

    expect(response).to redirect_to(new_my_profile_path)

    follow_redirect!
    expect(response.body).to include("部屋に入るにはプロフィールを作成してください")
  end
end
