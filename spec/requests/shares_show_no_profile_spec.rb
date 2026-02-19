require "rails_helper"

RSpec.describe "shares#show", type: :request do
  it "プロフィールがない場合、部屋に参加できない" do
    # 共有リンクを作る
    issuer = create(:profile)
    room = create(:room, issuer_profile: issuer)
    share_link = create(:share_link, room: room, expires_at: 1.hour.from_now)

    # プロフィールなしの訪問者を作る
    viewer = create(:user)

    # ログイン
    sign_in viewer

    # ★ここに入れる（getの直前）
    puts "expires_at: #{share_link.reload.expires_at}, now: #{Time.current}"

    # 検証
    expect {
      get share_path(share_link.token)
    }.not_to change(RoomMembership, :count)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("プロフィール未登録です")
    expect(response.body).to include(new_my_profile_path)
  end
end