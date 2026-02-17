require "rails_helper"

RSpec.describe Room, type: :model do
  it "発行者プロフィール（issuer_profile）がない場合は無効にする" do
    room = described_class.new(issuer_profile: nil)

    expect(room).not_to be_valid
  end

  it "has associations" do
    room = described_class.reflect_on_association(:issuer_profile)
    
    expect(room.macro).to eq(:belongs_to)
    expect(described_class.reflect_on_association(:room_memberships).macro).to eq(:has_many)
    expect(described_class.reflect_on_association(:profiles).macro).to eq(:has_many)
    expect(described_class.reflect_on_association(:share_link).macro).to eq(:has_one)
  end
end
