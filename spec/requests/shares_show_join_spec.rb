require "rails_helper"

RSpec.describe "Shares#show", type: :request do
  it "共有リンクが有効で、閲覧者にプロフィールがあるとき、room に参加する" do
    # 共有リンクを用意
    issuer = create(:profile)
    room = create(:room, issuer_profile: issuer)
    share_link = create(:share_link, room: room, expires_at: 24.hour.from_now)

    # 閲覧者のプロフィールを用意
    viewer_user = create(:user)
    viewer_profile = create(:profile, user: viewer_user)

    sign_in viewer_user

    expect {
      get share_path(share_link.token)
    }.to change(RoomMembership, :count).by(1)

    membership = RoomMembership.order(:created_at).last
    expect(membership.room).to eq(room)
    expect(membership.profile).to eq(viewer_profile)
  end
end
