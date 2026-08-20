require "rails_helper"

RSpec.describe "shares#show", type: :request do
  it "プロフィールがなくても部屋ページへ案内される" do
    # セットアップ: 有効な招待リンクと、プロフィールなしの訪問者
    issuer = create(:profile)
    room = create(:room, issuer_profile: issuer)
    share_link = create(:share_link, room: room, expires_at: 1.hour.from_now)

    viewer = create(:user)
    sign_in viewer

    # アクション: 招待リンクの URL を開く
    expect {
      get share_path(share_link.token)
    }.not_to change(RoomMembership, :count)

    # アサーション: プロフィール作成へは行かず、部屋へ案内する
    expect(response).to redirect_to(room_path(room))
  end
end
