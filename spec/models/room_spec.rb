require "rails_helper"

RSpec.describe Room, type: :model do
  it "発行者がプロフィール（issuer_profile）がない場合は無効にする" do
    room = described_class.new(issuer_profile: nil)

    expect(room).not_to be_valid
  end
end