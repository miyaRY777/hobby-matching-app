require "rails_helper"

RSpec.describe RoomMembership, type: :model do
  it "room がない場合は無効になる" do
    membership = described_class.new(room: nil, profile: create(:profile))

    expect(membership).not_to be_valid
  end

  it "同じ room と profile の組み合わせで、重複して join できないようにする" do
    room = create(:room)
    profile = create(:profile)

    described_class.create!(room: room, profile: profile)
    dup = described_class.new(room: room, profile: profile)

    expect(dup).not_to be_valid
  end
end