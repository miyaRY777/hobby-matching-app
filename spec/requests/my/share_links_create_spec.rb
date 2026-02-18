require "rails_helper"

RSpec.describe "My::ShareLinks#create", type: :request do
  it "creates room, issuer membership, and share_link" do
    user = create(:user)
    profile = create(:profile, user: user)

    sign_in user

    expect {
      post my_share_links_path, params: { room: { label: "" } }
    }.to change(Room, :count).by(1)
     .and change(RoomMembership, :count).by(1)
     .and change(ShareLink, :count).by(1)

    room = Room.order(:created_at).last
    expect(room.issuer_profile).to eq(profile)

    membership = RoomMembership.order(:created_at).last
    expect(membership.room).to eq(room)
    expect(membership.profile).to eq(profile)

    share_link = ShareLink.order(:created_at).last
    expect(share_link.room).to eq(room)
    expect(share_link.expires_at).to be_within(5.seconds).of(24.hours.from_now)
    expect(share_link.token).to be_present
  end
end
