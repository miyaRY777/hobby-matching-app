require "rails_helper"

RSpec.describe ShareLink, type: :model do
  it "roomがない場合は無効になる" do
    share_link = described_class.new(room: nil)

    expect(share_link).not_to be_valid
  end

  it "作成時に自動でトークンが生成される" do
    room = create(:room)
    share_link = described_class.create(room: room)

    expect(share_link.token).to be_present
  end

  it "作成時にexpire_atが現在時刻から24時間後に設定される" do
    room = create(:room)
    share_link = described_class.create(room: room)

    expect(share_link.expires_at).to be_within(5.seconds).of(24.hours.from_now)
  end
end
