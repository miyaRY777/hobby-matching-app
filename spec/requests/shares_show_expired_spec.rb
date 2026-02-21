require "rails_helper"

RSpec.describe "shares#show", type: :request do
  it "リンクが切れた場合、参加ができない" do
    # リンクを作成
    issuer = create(:profile)
    room = create(:room, issuer_profile: issuer)
    share_link = create(:share_link, room: room, expires_at: 1.minutes.ago)

    # 閲覧者のプロフィールを作成
    viewer = create(:user)
    create(:profile, user: viewer)

    # ログイン
    sign_in viewer

    # 検証
    expect {
      get share_path(share_link.token)
    }.not_to change(RoomMembership, :count)
  end
end
