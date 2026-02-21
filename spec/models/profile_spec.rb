require "rails_helper"

RSpec.describe Profile, type: :model do
  it "has room-related associations" do
    expect(described_class.reflect_on_association(:room_memberships).macro).to eq(:has_many)
    expect(described_class.reflect_on_association(:joined_rooms).macro).to eq(:has_many)
    expect(described_class.reflect_on_association(:issued_rooms).macro).to eq(:has_many)
  end
end
