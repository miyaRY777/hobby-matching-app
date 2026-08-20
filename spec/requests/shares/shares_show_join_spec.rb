require "rails_helper"

RSpec.describe "Shares#show", type: :request do
  it "共有リンクが有効でも、閲覧者は参加しない" do
    # セットアップ: 有効な招待リンクと、プロフィールのある未参加の閲覧者
    issuer = create(:profile)
    room = create(:room, issuer_profile: issuer)
    share_link = create(:share_link, room: room, expires_at: 24.hour.from_now)

    viewer_user = create(:user)
    create(:profile, user: viewer_user)

    sign_in viewer_user

    # アクション: 招待リンクの URL を開く
    expect {
      get share_path(share_link.token)
    }.not_to change(RoomMembership, :count)

    # アサーション: 部屋へ案内するだけ
    expect(response).to redirect_to(room_path(room))
  end
end
